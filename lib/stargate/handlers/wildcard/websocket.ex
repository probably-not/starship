defmodule Stargate.Handler.Wildcard.Websocket do
  def connect(_conn, config) do
    {:ok, config}
  end

  def payload(bin, config) do
    IO.inspect({"unhandled ws payload", __MODULE__, bin})
    config
  end
end
