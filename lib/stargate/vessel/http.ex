defmodule Stargate.Vessel.Http do
  @moduledoc """
  Functions for handling HTTP Requests in `Stargate.Vessel`.
  """

  alias Stargate.Vessel
  alias Stargate.Vessel.Conn
  import Vessel.Response, only: [build_response: 4]

  @spec handle_http_request(Conn.t(), map) :: map
  def handle_http_request(%Conn{} = conn, config) do
    {_, host} = Enum.find(conn.headers, &(elem(&1, 0) == "host"))
    {http_handler, _} = Vessel.get_host_handler(:http, host, conn.path, config.hosts)
    {code, headers, body, config} = :erlang.apply(http_handler, :http, [conn, config])
    response_bin = build_response(code, headers, body, conn.http_version)
    :ok = config.transport.send(config.socket, response_bin)
    config
  end
end
