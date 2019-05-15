defmodule Stargate.Handler.Wildcard.Http.Redirect do
  def http(%{headers: h, path: path, query: query}, s) do
    {_, host} = Enum.find(h, &(elem(&1, 0) == "host"))

    query = Enum.reduce(query, "", fn {k, v}, a -> "#{a}&#{k}=#{v}" end)
    query = if byte_size(query) > 0, do: "?#{String.trim_leading(query, "&")}", else: ""

    ssl_path = "https://#{host}/#{path}#{query}"
    {301, [{"Location", ssl_path}], "", s}
  end
end
