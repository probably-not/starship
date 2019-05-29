defmodule Stargate.Handler.Wildcard.Http.Redirect do
  @moduledoc """
  A simple wildcard handler for redirecting HTTP requests from non-secured to secured endpoints.
  """

  alias Stargate.Vessel.Conn

  @spec http(Conn.t(), map) :: {non_neg_integer, [{binary, binary}], binary, map}
  def http(%Conn{} = conn, config) do
    {_, host} = List.keyfind(conn.headers, "host", 0)

    query = Enum.reduce(conn.query, "", fn {k, v}, a -> "#{a}&#{k}=#{v}" end)
    query = if byte_size(query) > 0, do: "?#{String.trim_leading(query, "&")}", else: ""

    ssl_path = "https://#{host}/#{conn.path}#{query}"
    {301, [{"Location", ssl_path}], "", config}
  end
end
