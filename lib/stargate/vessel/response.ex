defmodule Stargate.Vessel.Response do
  @moduledoc """
  Functions for building responses that are returned to the client.
  """

  alias __MODULE__
  import Response.Codes, only: [response: 1]

  @spec build_response(non_neg_integer, [{binary, binary}], bitstring) :: binary
  def build_response(code, headers, body) do
    headers =
      case Enum.find(headers, &(elem(&1, 0) == "Connection")) do
        nil -> headers ++ [{"Connection", "keep-alive"}]
        _ -> headers
      end

    headers = headers ++ [{"Content-Length", "#{byte_size(body)}"}]

    response_head = <<"HTTP/1.1 #{code} #{response(code)}\r\n"::binary>>
    response_headers = Enum.reduce(headers, "", fn {k, v}, a -> a <> "#{k}: #{v}\r\n" end)
    <<response_head::binary, response_headers::binary, "\r\n", body::binary>>
  end
end
