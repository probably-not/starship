defmodule Stargate.Vessel do
  @moduledoc false

  alias __MODULE__
  import Vessel.Response, only: [build_response: 3]
  import Vessel.Http, only: [handle_http_request: 2]
  import Vessel.Websocket, only: [handle_ws_handshake: 2, handle_ws_frame: 2]

  @max_header_size 8192

  def loop(config) do
    config =
      receive do
        {:pass_socket, csocket} ->
          {transport, socket} =
            if !config[:ssl_opts] do
              :ok = :inet.setopts(csocket, [{:active, true}])
              {:gen_tcp, csocket}
            else
              {:ok, ssl_socket} = :ssl.handshake(csocket, config.ssl_opts, 120_000)
              {:ssl, ssl_socket}
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
        120_000 ->
          :close
      end

    loop(config)
  end

  def on_close(config) do
    config.transport.close(config.socket)
    Process.exit(self(), :normal)
  end

  def on_ws_send(_tuple, config) do
    config
  end

  def on_tcp(config = %{state: :ws}, bin) do
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

  def on_tcp(config, bin) do
    buf = Map.get(config, :buf, <<>>) <> bin
    end_of_header = :binary.match(buf, "\r\n\r\n")

    cond do
      byte_size(buf) > @max_header_size -> close_connection(config)
      end_of_header == :nomatch -> Map.put(config, :buf, buf)
      is_tuple(end_of_header) -> handle_request(end_of_header, buf, config)
    end
  end

  def close_connection(config) do
    response_bin = build_response(413, [{"Connection", "close"}], "")
    :ok = config.transport.send(config.socket, response_bin)
    Process.exit(self(), :normal)
  end

  def handle_request(end_of_header, buf, config) do
    {pos, _} = end_of_header
    <<header_bin::binary-size(pos), _::32, buf::binary>> = buf
    [req | headers] = String.split(header_bin, "\r\n")
    [type, path, http_ver] = String.split(req, " ")

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

    request = %{
      type: type,
      path: path,
      query: query,
      http_ver: http_ver,
      headers: headers,
      body: ""
    }

    websocket? = Enum.find(headers, fn {k, v} -> k == "upgrade" and v == "websocket" end)

    cond do
      websocket? != nil ->
        config = handle_ws_handshake(request, config)
        Map.merge(config, %{buf: buf, state: :ws})

      type == "POST" or type == "PUT" ->
        # add parsing more content types
        {"content-length", clen} = Enum.find(headers, fn {k, _} -> k == "content-length" end)
        clen = :erlang.binary_to_integer(clen)

        case buf do
          <<body::binary-size(clen), buf::binary>> ->
            request = Map.put(request, :body, body)
            config = handle_http_request(request, config)
            Map.merge(config, %{buf: buf, request: %{}, state: nil})

          buf ->
            Map.merge(config, %{
              buf: buf,
              request: request,
              state: :http_body,
              body_size: clen
            })
        end

      true ->
        config = handle_http_request(request, config)
        Map.merge(config, %{buf: buf, request: %{}, state: nil})
    end
  end

  def get_host_handler(type, host, path, config_hosts) do
    default_handler = Map.get(config_hosts, {type, "*"})

    cond do
      type == :http ->
        Map.get(config_hosts, {:http, host}, default_handler)

      type == :ws ->
        default_handler_path = Map.get(config_hosts, {:ws, {"*", path}}, default_handler)
        Map.get(config_hosts, {:ws, {host, path}}, default_handler_path)
    end
  end
end
