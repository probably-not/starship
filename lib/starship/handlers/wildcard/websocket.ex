defmodule Starship.Handler.Wildcard.Websocket do
  @moduledoc """
  A simple wildcard handler for Websocket Requests that always sends
  "Returning: " followed by the text that is sent to the socket.
  """

  use Starship.Handlers.Websocket
  alias Starship.Reactor.Conn

  @spec connect(Conn.t(), map) :: {:ok, map} | :reject
  def connect(%Conn{} = _conn, config) do
    {:ok, config}
  end

  @spec handle_text(bitstring, map) :: {binary, map}
  def handle_text(text, config) do
    {"Returning: #{text}", config}
  end
end
