defmodule Stargate.Vessel.Http do
  @moduledoc """
  Functions for handling HTTP Requests in `Stargate.Vessel`.
  """

  alias Stargate.Vessel
  alias Stargate.Vessel.Conn
  import Vessel.Response, only: [build_response: 4, connection_header: 2]

  @type connection_state :: :close | :keepalive

  @spec handle_http_request(Conn.t(), map) :: {connection_state, map}
  def handle_http_request(%Conn{http_version: http_version} = conn, config) do
    {_, host} = List.keyfind(conn.headers, "host", 0)
    {http_handler, _} = Vessel.get_host_handler(:http, host, conn.path, config.hosts)
    {code, response_headers, body, config} = :erlang.apply(http_handler, :http, [conn, config])
    {connection_state, connection_header} = connection_header(conn.headers, http_version)

    response_io_list =
      build_response(code, [connection_header | response_headers], body, conn.http_version)

    :ok = config.transport.send(config.socket, response_io_list)
    {connection_state, config}
  end

  @spec handle_request_with_body(Conn.t(), binary, map) :: {connection_state, map} | map
  def handle_request_with_body(%Conn{} = conn, buf, config) do
    # add parsing more content types
    {_, clen} = List.keyfind(conn.headers, "content-length", 0)
    clen = :erlang.binary_to_integer(clen)

    case buf do
      <<body::binary-size(clen), buf::binary>> ->
        conn = Map.put(conn, :body, body)
        {result, config} = handle_http_request(conn, config)

        if result == :keepalive do
          {result, Map.merge(config, %{buf: buf, request: %{}, state: nil})}
        else
          {result, config}
        end

      buf ->
        Map.merge(config, %{
          buf: buf,
          request: conn,
          state: :http_body,
          body_size: clen
        })
    end
  end
end
