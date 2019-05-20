defmodule Stargate.Vessel do
  @moduledoc """
  The main request handler for the `Stargate` Webserver.

  When a message is passed to a `Stargate.Acceptor` process,
  a `Stargate.Vessel` process is spawned to handle the request.
  """

  alias __MODULE__
  alias Stargate.Errors

  import Vessel.Response, only: [build_response: 3]
  import Vessel.Http, only: [handle_http_request: 2]
  import Vessel.Websocket, only: [handle_ws_handshake: 2, handle_ws_frame: 2]

  @max_header_size 8192
  @vessel_timeout 120_000
  @ssl_handshake_timeout 120_000

  @spec loop(config :: map) :: map | true
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
        @vessel_timeout ->
          :close
      end

    loop(config)
  end

  @spec on_close(config :: map) :: true
  def on_close(config) do
    config.transport.close(config.socket)
    Process.exit(self(), :normal)
  end

  @spec on_ws_send(_tuple :: tuple, config :: map) :: map
  def on_ws_send(_tuple, config) do
    config
  end

  def on_tcp(%{state: :ws} = config, bin) do
    handle_ws_frame(bin, config)
    config
  end

  def on_tcp(config = %{state: :http_body, body_size: bs}, bin) do
    buf = Map.get(config, :buf, <<>>) <> bin

    case buf do
      <<body::binary-size(bs), buf::binary>> ->
        request = Map.put(config.request, :body, body)
        config = handle_http_request(request, config)
        Map.merge(config, %{buf: buf, request: %{}, state: nil})

      buf ->
        Map.merge(config, %{buf: buf})
    end
  end

  @spec on_tcp(config :: map, bin :: binary) :: map | true
  def on_tcp(config, bin) do
    buf = Map.get(config, :buf, <<>>) <> bin
    end_of_header = :binary.match(buf, "\r\n\r\n")

    cond do
      byte_size(buf) > @max_header_size -> close_connection(config)
      end_of_header == :nomatch -> Map.put(config, :buf, buf)
      is_tuple(end_of_header) -> handle_request(end_of_header, buf, config)
    end
  end

  @spec close_connection(config :: map) :: true
  def close_connection(config) do
    response_bin = build_response(413, [{"Connection", "close"}], "")
    :ok = config.transport.send(config.socket, response_bin)
    Process.exit(self(), :normal)
  end

  @spec handle_request({non_neg_integer, non_neg_integer}, buf :: binary, config :: map) :: map
  def handle_request({end_of_headers, _}, buf, config) do
    {conn, buf} = build_conn(end_of_headers, buf)

    cond do
      websocket?(conn.headers) ->
        config = handle_ws_handshake(conn, config)
        Map.merge(config, %{buf: buf, state: :ws})

      conn.method == :POST or conn.method == :PUT ->
        # add parsing more content types
        {"content-length", clen} = Enum.find(conn.headers, fn {k, _} -> k == "content-length" end)
        clen = :erlang.binary_to_integer(clen)

        case buf do
          <<body::binary-size(clen), buf::binary>> ->
            conn = Map.put(conn, :body, body)
            config = handle_http_request(conn, config)
            Map.merge(config, %{buf: buf, request: %{}, state: nil})

          buf ->
            Map.merge(config, %{
              buf: buf,
              request: conn,
              state: :http_body,
              body_size: clen
            })
        end

      true ->
        config = handle_http_request(conn, config)
        Map.merge(config, %{buf: buf, request: %{}, state: nil})
    end
  end

  @spec build_conn(end_of_headers :: non_neg_integer, buf :: binary) :: {Vessel.Conn.t(), binary}
  def build_conn(end_of_headers, buf) do
    <<header_bin::binary-size(end_of_headers), _::32, buf::binary>> = buf
    [req | headers] = String.split(header_bin, "\r\n")
    [method, path, http_version] = String.split(req, " ")

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

    method =
      try do
        String.to_existing_atom(method)
      rescue
        ArgumentError ->
          stacktrace = System.stacktrace()
          reraise Errors.UnsupportedHttpMethodError, method, stacktrace
      end

    http_version =
      try do
        v = String.to_existing_atom(http_version)

        if v == :"HTTP/1.1" do
          v
        else
          raise Errors.UnsupportedHttpVersionError, v
        end
      rescue
        ArgumentError ->
          stacktrace = System.stacktrace()
          reraise Errors.UnsupportedHttpVersionError, http_version, stacktrace
      end

    {%Vessel.Conn{
       method: method,
       path: path,
       query: query,
       http_version: http_version,
       headers: headers,
       body: ""
     }, buf}
  end

  @spec websocket?(headers :: [{binary, binary}]) :: boolean
  def websocket?(headers) do
    Enum.find(headers, fn {k, v} -> k == "upgrade" and v == "websocket" end) != nil
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
