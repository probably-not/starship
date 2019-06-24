defmodule Starship.Reactor.Response do
  @moduledoc """
  Functions for building responses that are returned to the client.
  """

  alias Starship.Reactor
  alias Starship.Reactor.Conn
  import Starship.Reactor.Response.Codes, only: [response: 1]

  @spec build_response(non_neg_integer, Conn.headers(), Conn.body(), Conn.http_version()) ::
          [binary]
  def build_response(code, response_headers, body, http_version) do
    response_head = [to_string(http_version), " ", to_string(code), " ", response(code), "\r\n"]

    headers = [
      Enum.map(response_headers, fn {k, v} -> [k, ": ", v, "\r\n"] end),
      ["Content-Length: ", to_string(byte_size(body)), "\r\n"]
    ]

    [response_head, headers, body]
  end

  @spec build_headers(Conn.headers(), non_neg_integer) :: Conn.headers()
  def build_headers(response_headers, content_length) do
    response_headers ++ [{"Content-Length", "#{content_length}"}]
  end

  @spec connection_header(Conn.headers(), Conn.http_version()) ::
          {Reactor.connection_state(), Conn.header()}
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
