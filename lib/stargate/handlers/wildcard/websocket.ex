defmodule Stargate.Handler.Wildcard.Websocket do
  def connect(%{path: path}, s) do
    IO.inspect({"unhandled ws connect", __MODULE__, path})
    {:ok, s}
  end

  def payload(bin, s) do
    IO.inspect({"unhandled ws payload", __MODULE__, bin})
    s
  end
end
