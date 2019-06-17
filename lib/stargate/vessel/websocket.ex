defmodule Stargate.Vessel.Websocket do
  @moduledoc """
  Functions for handling Websocket Requests in `Stargate.Vessel`.
  """

  alias __MODULE__
  alias Stargate.Vessel
  alias Vessel.Conn
  import Websocket.Handshake, only: [successful_handshake: 3, rejected_handshake: 1]

  @spec handle_ws_frame(binary, map) :: map
  def handle_ws_frame(frame, config) do
    frame = Map.get(config, :buf, <<>>) <> frame

    case Websocket.Frame.parse_frame(frame) do
      {:ok, :fin, :masked, :text, payload} -> config.handler.handle_text(payload, config)
      {:ok, :fin, :masked, :binary, payload} -> config.handler.handle_binary(payload, config)
      {:ok, :fin, :masked, :close, payload} -> config.handler.handle_close(payload, config)
      {:ok, :fin, :masked, :ping, payload} -> handle_ping(payload, config)
      {:ok, :fin, :masked, :pong, _payload} -> :ignore
      {:ok, :not_fin, :masked, :continuation, payload} -> handle_fragment(payload, config)
      {:ok, :not_fin, :masked, :text, payload} -> handle_fragment(payload, config)
      {:ok, :not_fin, :masked, :binary, payload} -> handle_fragment(payload, config)
      {:error, _reason} -> rejected_handshake(config)
    end

    config
  end

  @spec handle_ws_handshake(Conn.t(), map) :: map
  def handle_ws_handshake(%Conn{} = conn, config) do
    {_, host} = List.keyfind(conn.headers, "host", 0)
    {ws_handler, opts} = Vessel.get_host_handler(:ws, host, conn.path, config.hosts)
    config = Map.put(config, :handler, ws_handler)

    case :erlang.apply(ws_handler, :connect, [conn, config]) do
      :reject -> rejected_handshake(config)
      {:ok, config} -> successful_handshake(conn, config, opts)
    end
  end

  @spec handle_ping(bitstring, map) :: map
  def handle_ping(_payload, _config) do
    :not_implemented_yet
  end

  @spec handle_fragment(bitstring, map) :: map
  def handle_fragment(_payload, _config) do
    :not_implemented_yet
  end
end
