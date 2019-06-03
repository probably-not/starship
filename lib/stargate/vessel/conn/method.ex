defmodule Stargate.Vessel.Conn.Method do
  @moduledoc """
  The struct and type spec for HTTP Methods
  """
  alias __MODULE__

  @type method :: :GET | :HEAD | :POST | :PUT | :DELETE | :CONNECT | :OPTIONS | :TRACE | :PATCH

  @type t :: %Method{name: method, has_body: boolean}
  defstruct name: :GET, has_body: false

  def get, do: %Method{name: :GET, has_body: false}
  def head, do: %Method{name: :HEAD, has_body: false}
  def post, do: %Method{name: :POST, has_body: true}
  def put, do: %Method{name: :PUT, has_body: true}
  def delete, do: %Method{name: :DELETE, has_body: true}
  def connect, do: %Method{name: :CONNECT, has_body: false}
  def options, do: %Method{name: :OPTIONS, has_body: false}
  def trace, do: %Method{name: :TRACE, has_body: false}
  def patch, do: %Method{name: :PATCH, has_body: true}
end
