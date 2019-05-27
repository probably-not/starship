defmodule Stargate.Handler.Wildcard.Websocket do
  @moduledoc """
  A simple wildcard handler for Websocket Requests that always sends
  "Returning: " followed by the text that is sent to the socket.
  """

  alias Stargate.Vessel.Conn
  alias Stargate.Vessel.Websocket.Frame

  @spec connect(Conn.t(), map) :: {:ok, map} | :reject
  def connect(%Conn{} = _conn, config) do
    {:ok, config}
  end

  @spec handle_text_frame(bitstring, map) :: map
  def handle_text_frame(text, config) do
    response = Frame.format_server_frame("Returning: #{text}", :text)
    config.transport.send(config.socket, response)
    config
  end
end
