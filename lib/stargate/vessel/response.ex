defmodule Stargate.Vessel.Response do
  @moduledoc """
  Functions for building responses that are returned to the client.
  """

  alias __MODULE__
  import Response.Codes, only: [response: 1]

  @spec build_response(non_neg_integer, [{binary, binary}], bitstring, atom) :: binary
  def build_response(code, request_headers, body, http_version) do
    headers = build_headers(request_headers, byte_size(body))
    response_head = <<"#{http_version} #{code} #{response(code)}\r\n"::binary>>
    response_headers = Enum.reduce(headers, "", fn {k, v}, a -> a <> "#{k}: #{v}\r\n" end)
    <<response_head::binary, response_headers::binary, "\r\n", body::binary>>
  end

  @spec build_headers([{binary, binary}], non_neg_integer) :: [{binary, binary}]
  def build_headers(request_headers, content_length) do
    response_headers =
      case Enum.find(request_headers, &(elem(&1, 0) == "Connection")) do
        nil -> request_headers ++ [{"Connection", "keep-alive"}]
        _ -> request_headers
      end

    response_headers ++ [{"Content-Length", "#{content_length}"}]
  end
end
