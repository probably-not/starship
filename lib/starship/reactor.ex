defmodule Starship.Reactor do
  @moduledoc """
  The main request handler for the `Starship` Webserver.

  When a message is passed to a `Starship.Drive` process,
  a `Starship.Reactor` process is spawned to handle the request.
  """

  alias Starship.Errors
  alias Starship.Reactor.Conn

  import Starship.Reactor.Response, only: [build_response: 4]
  import Starship.Reactor.Http, only: [handle_http_request: 2, handle_request_with_body: 3]
  import Starship.Reactor.Websocket, only: [handle_ws_handshake: 2, handle_ws_frame: 2]

  @typedoc """
  The connection state of the port and socket.

  If set to `:close`, then the socket and port will return a Connection: Close header
  and close.

  If set to `:keepalive`, then the socket and port will return a Connection: Keep-Alive header
  and stay open.
  """
  @type connection_state :: :close | :keepalive

  @max_header_size 8192
  @reactor_timeout 120_000
  @ssl_handshake_timeout 120_000

  @spec loop(map) :: map | true
  def loop(config) do
    config =
      receive do
        {:pass_socket, csocket} ->
          {transport, socket} =
            if config[:ssl_opts] do
              {:ok, ssl_socket} = :ssl.handshake(csocket, config.ssl_opts, @ssl_handshake_timeout)
              {:ssl, ssl_socket}
            else
              :ok = :inet.setopts(csocket, [{:active, true}])
              {:gen_tcp, csocket}
            end

          Map.merge(config, %{socket: socket, transport: transport})

        {:tcp, _socket, bin} ->
          on_tcp(config, bin)

        {:tcp_closed, _socket} ->
          on_close(config)

        {:tcp_error, _socket, _error} ->
          on_close(config)

        {:ssl, _socket, bin} ->
          on_tcp(config, bin)

        {:ssl_closed, _socket} ->
          on_close(config)

        {:ssl_error, _socket, _error} ->
          on_close(config)

        {:ws_send, tuple} ->
          on_ws_send(tuple, config)
      after
        @reactor_timeout ->
          :close
      end

    loop(config)
  end

  @spec on_close(map) :: true
  def on_close(config) do
    config.transport.close(config.socket)
    Process.exit(self(), :normal)
  end

  @spec on_ws_send(tuple, map) :: map
  def on_ws_send(_tuple, config) do
    config
  end

  def on_tcp(%{state: :ws} = config, bin) do
    case handle_ws_frame(bin, config) do
      {:close, config} -> on_close(config)
      {:keepalive, config} -> config
    end
  end

  def on_tcp(%{state: :http_body} = config, bin) do
    buf = Map.get(config, :buf, <<>>) <> bin

    case handle_request_with_body(config.request, buf, config) do
      {:close, config} -> on_close(config)
      {:keepalive, config} -> Map.merge(config, %{buf: buf, request: %{}, state: nil})
      %{} = config -> config
    end
  end

  @spec on_tcp(map, binary) :: map | true
  def on_tcp(config, bin) do
    buf = Map.get(config, :buf, <<>>) <> bin
    end_of_header = :binary.match(buf, "\r\n\r\n")

    cond do
      byte_size(buf) > @max_header_size -> header_too_large(config)
      end_of_header == :nomatch -> Map.put(config, :buf, buf)
      is_tuple(end_of_header) -> handle_request(end_of_header, buf, config)
    end
  end

  @spec header_too_large(map) :: true
  def header_too_large(config) do
    response_io_list = build_response(413, [{"Connection", "close"}], "", :"HTTP/1.1")
    :ok = config.transport.send(config.socket, response_io_list)
    Process.exit(self(), :normal)
  end

  @spec method_not_allowed(map) :: true
  def method_not_allowed(config) do
    response_io_list = build_response(405, [{"Connection", "close"}], "", :"HTTP/1.1")
    :ok = config.transport.send(config.socket, response_io_list)
    Process.exit(self(), :normal)
  end

  @spec http_version_not_supported(map) :: true
  def http_version_not_supported(config) do
    response_io_list = build_response(505, [{"Connection", "close"}], "", :"HTTP/1.1")
    :ok = config.transport.send(config.socket, response_io_list)
    Process.exit(self(), :normal)
  end

  @spec handle_request({non_neg_integer, non_neg_integer}, binary, map) :: map | true
  def handle_request({end_of_headers, _}, buf, config) do
    case build_conn(end_of_headers, buf) do
      {:ok, conn, buf} -> process_request(conn, buf, config)
      {:error, %Errors.MethodNotAllowedError{}} -> method_not_allowed(config)
      {:error, %Errors.HttpVersionNotSupportedError{}} -> http_version_not_supported(config)
    end
  end

  @spec process_request(Conn.t(), binary, map) :: map
  def process_request(conn, buf, config) do
    cond do
      websocket?(conn.headers) ->
        {result, config} = handle_ws_handshake(conn, config)

        if result == :close do
          on_close(config)
        else
          Map.merge(config, %{buf: buf, state: :ws})
        end

      conn.method.has_body ->
        case handle_request_with_body(conn, buf, config) do
          {:close, config} -> on_close(config)
          {:keepalive, config} -> Map.merge(config, %{buf: buf, request: %{}, state: nil})
          %{} = config -> config
        end

      true ->
        {result, config} = handle_http_request(conn, config)

        if result == :close do
          on_close(config)
        else
          Map.merge(config, %{buf: buf, request: %{}, state: nil})
        end
    end
  end

  @spec build_conn(non_neg_integer, binary) :: {:ok, Conn.t(), binary} | {:error, Exception.t()}
  def build_conn(end_of_headers, buf) do
    <<header_bin::binary-size(end_of_headers), _::32, buf::binary>> = buf
    [req | headers] = String.split(header_bin, "\r\n")
    [method, path, http_version] = String.split(req, " ")

    with {:ok, http_version} <- Conn.http_version(http_version),
         {:ok, method} <- Conn.http_method(method) do
      headers =
        Enum.map(headers, fn line ->
          [k, v] = String.split(line, ": ")
          {String.downcase(k), v}
        end)

      # split out the query from the path
      {path, query} =
        case String.split(path, "?") do
          [p, q] ->
            kvmap =
              Enum.reduce(String.split(q, "&"), %{}, fn line, a ->
                [k, v] = String.split(line, "=")
                Map.put(a, k, v)
              end)

            {p, kvmap}

          _ ->
            {path, %{}}
        end

      {:ok,
       %Conn{
         method: method,
         path: path,
         query: query,
         http_version: http_version,
         headers: headers,
         body: ""
       }, buf}
    else
      error -> error
    end
  end

  @spec websocket?(Conn.headers()) :: boolean
  def websocket?(headers) do
    case List.keyfind(headers, "upgrade", 0) do
      {"upgrade", "websocket"} -> true
      _ -> false
    end
  end

  @spec get_host_handler(atom, binary, binary, map) :: {module, map}
  def get_host_handler(type, host, path, config_hosts) do
    default_handler = Map.get(config_hosts, {type, "*"})

    case type do
      :http ->
        Map.get(config_hosts, {:http, host}, default_handler)

      :ws ->
        default_handler_path = Map.get(config_hosts, {:ws, {"*", path}}, default_handler)
        Map.get(config_hosts, {:ws, {host, path}}, default_handler_path)

      _ ->
        raise Errors.InvalidHandlerTypeError, type
    end
  end
end
