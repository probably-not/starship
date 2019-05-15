defmodule Stargate.Handler.Wildcard.Http do
  def http(conn, s) do
    IO.inspect(conn)
    IO.inspect(s)
    {200, [], "", s}
  end
end
