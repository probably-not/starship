defmodule Stargate.Handler.Wildcard.Http do
  alias Stargate.Vessel.Conn

  def http(%Conn{} = _conn, config) do
    {200, [], "", config}
  end
end
