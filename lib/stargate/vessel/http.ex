defmodule Stargate.Vessel.Http do
  @moduledoc false

  alias Stargate.Vessel
  import Vessel.Response, only: [build_response: 3]

  def handle_http_request(conn, config) do
    {_, host} = Enum.find(conn.headers, &(elem(&1, 0) == "host"))
    {http_handler, _} = Vessel.get_host_handler(:http, host, conn.path, config.hosts)
    {code, headers, body, config} = :erlang.apply(http_handler, :http, [conn, config])

    response_bin = build_response(code, headers, body)

    :ok = config.transport.send(config.socket, response_bin)
    config
  end
end
