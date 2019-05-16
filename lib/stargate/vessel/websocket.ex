defmodule Stargate.Vessel.Websocket do
  @moduledoc false

  alias Stargate.Vessel
  alias __MODULE__
  import Vessel.Response, only: [build_response: 3]

  def handle_ws_frame(frame, config) do
    frame = Map.get(config, :buf, <<>>) <> frame

    case Websocket.Frame.parse_frame(frame) do
      {:ok, :final, :masked, :close, ""} -> config.transport.close(config.socket)
      {:ok, :final, :masked, :text, text} -> config.handler.handle_text_frame(text, config)
    end
  end

  def handle_ws_handshake(request, config) do
    {_, host} = Enum.find(request.headers, &(elem(&1, 0) == "host"))
    {ws_handler, opts} = Vessel.get_host_handler(:ws, host, request.path, config.hosts)
    config = Map.put(config, :handler, ws_handler)

    case :erlang.apply(ws_handler, :connect, [request, config]) do
      :reject ->
        response_bin = build_response(404, [{"Connection", "close"}], "")
        :ok = config.transport.send(config.socket, response_bin)
        config

      {:ok, config} ->
        {_, ws_key} = Enum.find(request.headers, &(elem(&1, 0) == "sec-websocket-key"))

        {_, ws_ext} =
          Enum.find(request.headers, {"", ""}, &(elem(&1, 0) == "sec-websocket-extensions"))

        ws_ext = String.replace(ws_ext, " ", "")
        ws_ext = String.split(ws_ext, ",", trim: true)

        ws_ext =
          Enum.reduce(ws_ext, %{}, fn ext, acc ->
            case String.split(ext, ";", trim: true) do
              [h | [] = _t] -> Map.put(acc, h, "")
              [h | t] -> Map.put(acc, h, t)
              _ -> acc
            end
          end)

        extra_headers =
          cond do
            opts[:compress] != nil and ws_ext["permessage-deflate"] != nil ->
              [{"Sec-WebSocket-Extensions", "permessage-deflate"}]

            true ->
              []
          end

        inject_headers = Map.get(opts, :inject_headers, [])

        reply_headers =
          [
            {"Upgrade", "websocket"},
            {"Connection", "Upgrade"},
            {"Sec-WebSocket-Accept",
             :base64.encode(
               :crypto.hash(:sha, <<ws_key::binary, "258EAFA5-E914-47DA-95CA-C5AB0DC85B11">>)
             )}
          ] ++ extra_headers ++ inject_headers

        config =
          if length(extra_headers) > 0 do
            inflate_zlib = :zlib.open()
            :zlib.inflateInit(inflate_zlib, -15)

            compress = Map.get(opts, :compress, %{})
            level = Map.get(compress, :level, 1)
            memLevel = Map.get(compress, :mem_level, 8)
            windowBits = Map.get(compress, :window_bits, 15)
            strategy = Map.get(compress, :strategy, :default)

            deflate_zlib = :zlib.open()
            :zlib.deflateInit(deflate_zlib, level, :deflated, -windowBits, memLevel, strategy)

            Map.merge(config, %{inflate: inflate_zlib, deflate: deflate_zlib})
          else
            config
          end

        handshake_response =
          <<"HTTP/1.1 101 Switching Protocols\r\n"::binary,
            Enum.reduce(reply_headers, "", fn {k, v}, a -> a <> "#{k}: #{v}\r\n" end)::binary,
            "\r\n">>

        :ok =
          config.transport.send(
            config.socket,
            handshake_response
          )

        config
    end
  end
end
