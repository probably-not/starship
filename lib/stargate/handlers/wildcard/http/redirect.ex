defmodule Stargate.Handler.Wildcard.Http.Redirect do
  @moduledoc false

  def http(conn, config) do
    {_, host} = Enum.find(conn.headers, &(elem(&1, 0) == "host"))

    query = Enum.reduce(conn.query, "", fn {k, v}, a -> "#{a}&#{k}=#{v}" end)
    query = if byte_size(query) > 0, do: "?#{String.trim_leading(query, "&")}", else: ""

    ssl_path = "https://#{host}/#{conn.path}#{query}"
    {301, [{"Location", ssl_path}], "", config}
  end
end
