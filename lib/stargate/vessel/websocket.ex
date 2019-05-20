defmodule Stargate.Vessel.Websocket do
  @moduledoc false

  alias Stargate.Vessel
  alias __MODULE__
  import Vessel.Response, only: [build_response: 3]

  @ws_guid "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

  def handle_ws_frame(frame, config) do
    frame = Map.get(config, :buf, <<>>) <> frame

    case Websocket.Frame.parse_frame(frame) do
      {:ok, :final, :masked, :close, _final_payload} -> config.transport.close(config.socket)
      {:ok, :final, :masked, :text, text} -> config.handler.handle_text_frame(text, config)
    end
  end

  def handle_ws_handshake(conn, config) do
    {_, host} = Enum.find(conn.headers, &(elem(&1, 0) == "host"))
    {ws_handler, opts} = Vessel.get_host_handler(:ws, host, conn.path, config.hosts)
    config = Map.put(config, :handler, ws_handler)

    case :erlang.apply(ws_handler, :connect, [conn, config]) do
      :reject -> rejected_handshake(config)
      {:ok, config} -> successful_handshake(conn, config, opts)
    end
  end

  def rejected_handshake(config) do
    response_bin = build_response(404, [{"Connection", "close"}], "")
    :ok = config.transport.send(config.socket, response_bin)
    config
  end

  def successful_handshake(conn, config, opts) do
    {_, ws_key} = Enum.find(conn.headers, &(elem(&1, 0) == "sec-websocket-key"))
    ws_ext = extract_websocket_extensions(conn.headers)

    extra_headers =
      if opts[:compress] != nil and ws_ext["permessage-deflate"] != nil do
        [{"Sec-WebSocket-Extensions", "permessage-deflate"}]
      else
        []
      end

    inject_headers = Map.get(opts, :inject_headers, [])

    reply_headers =
      [
        {"Upgrade", "websocket"},
        {"Connection", "Upgrade"},
        {"Sec-WebSocket-Accept", :base64.encode(:crypto.hash(:sha, <<ws_key::binary, @ws_guid>>))}
      ] ++ extra_headers ++ inject_headers

    config =
      if length(extra_headers) > 0 do
        inflate_zlib = :zlib.open()
        :zlib.inflateInit(inflate_zlib, -15)

        compress = Map.get(opts, :compress, %{})
        level = Map.get(compress, :level, 1)
        mem_level = Map.get(compress, :mem_level, 8)
        window_bits = Map.get(compress, :window_bits, 15)
        strategy = Map.get(compress, :strategy, :default)

        deflate_zlib = :zlib.open()
        :zlib.deflateInit(deflate_zlib, level, :deflated, -window_bits, mem_level, strategy)

        Map.merge(config, %{inflate: inflate_zlib, deflate: deflate_zlib})
      else
        config
      end

    handshake_response =
      <<"HTTP/1.1 101 Switching Protocols\r\n"::binary,
        Enum.reduce(reply_headers, "", fn {k, v}, a -> a <> "#{k}: #{v}\r\n" end)::binary,
        "\r\n">>

    :ok = config.transport.send(config.socket, handshake_response)
    config
  end

  def extract_websocket_extensions(headers) do
    {_, ws_ext} = Enum.find(headers, {"", ""}, &(elem(&1, 0) == "sec-websocket-extensions"))

    ws_ext = String.replace(ws_ext, " ", "")
    ws_ext = String.split(ws_ext, ",", trim: true)

    Enum.reduce(ws_ext, %{}, fn ext, acc ->
      case String.split(ext, ";", trim: true) do
        [h | [] = _t] -> Map.put(acc, h, "")
        [h | t] -> Map.put(acc, h, t)
        _ -> acc
      end
    end)
  end
end
