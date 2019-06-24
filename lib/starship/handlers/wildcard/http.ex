defmodule Starship.Handler.Wildcard.Http do
  @moduledoc """
  A simple wildcard handler for HTTP Requests that always returns 404 Not Found responses.
  """

  alias Starship.Vessel.Conn

  @spec http(Conn.t(), map) :: {non_neg_integer, Conn.headers(), binary, map}
  def http(%Conn{} = _conn, config) do
    {404, [], "The requested page was not found", config}
  end
end
