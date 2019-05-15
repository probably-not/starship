defmodule Stargate.Handler.Wildcard.Http do
  def http(conn, config) do
    IO.inspect(conn)
    IO.inspect(config)
    {200, [], "", config}
  end
end
