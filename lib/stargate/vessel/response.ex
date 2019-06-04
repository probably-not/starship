defmodule Stargate.Vessel.Response do
  @moduledoc """
  Functions for building responses that are returned to the client.
  """

  alias __MODULE__
  alias Stargate.Vessel.Conn
  alias Stargate.Vessel.Http
  import Response.Codes, only: [response: 1]

  @spec build_response(non_neg_integer, Conn.headers(), Conn.body(), Conn.http_version()) ::
          binary
  def build_response(code, response_headers, body, http_version) do
    headers = build_headers(response_headers, byte_size(body))
    # response_head = <<"#{http_version} #{code} #{response(code)}\r\n"::binary>>
    response_head = ["#{http_version} ", "#{code} ", "#{response(code)}\r\n"]
    # headers_bin = Enum.reduce(headers, "", fn {k, v}, a -> a <> "#{k}: #{v}\r\n" end)
    headers_bin = Enum.map(headers, fn {k, v} -> [k, ": ", v, "\r\n"] end)
    # <<response_head::binary, headers_bin::binary, "\r\n", body::binary>>
    [response_head, headers_bin, body]
  end

  @spec build_headers(Conn.headers(), non_neg_integer) :: Conn.headers()
  def build_headers(response_headers, content_length) do
    response_headers ++ [{"Content-Length", "#{content_length}"}]
  end

  @spec connection_header(Conn.headers(), Conn.http_version()) ::
          {Http.connection_state(), Conn.header()}
  def connection_header(_request_headers, :"HTTP/0.9") do
    {:close, {"Connection", "Close"}}
  end

  def connection_header(request_headers, :"HTTP/1.0") do
    header = List.keyfind(request_headers, "Connection", 0, {"Connection", "Close"})

    case header do
      {"Connection", "Keep-Alive"} -> {:keepalive, {"Connection", "Keep-Alive"}}
      _ -> {:close, {"Connection", "Close"}}
    end
  end

  def connection_header(request_headers, _) do
    header = List.keyfind(request_headers, "Connection", 0, {"Connection", "Keep-Alive"})

    case header do
      {"Connection", "Close"} -> {:close, {"Connection", "Close"}}
      _ -> {:keepalive, {"Connection", "Keep-Alive"}}
    end
  end
end
