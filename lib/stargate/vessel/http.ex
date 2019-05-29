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

    response_bin =
      build_response(code, [connection_header | response_headers], body, conn.http_version)

    :ok = config.transport.send(config.socket, response_bin)
    {connection_state, config}
  end
end
