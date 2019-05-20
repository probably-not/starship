defmodule Stargate.Handler.Wildcard.Http do
  @moduledoc false

  alias Stargate.Vessel.Conn

  def http(_conn = %Conn{}, config) do
    {200, [], "", config}
  end
end
