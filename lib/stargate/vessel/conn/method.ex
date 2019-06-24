defmodule Stargate.Vessel.Conn.Method do
  @moduledoc """
  The struct and type spec for HTTP Methods
  """

  alias Stargate.Vessel.Conn.Method

  @typedoc "HTTP Methods according to HTTP Standards."
  @type method :: :GET | :HEAD | :POST | :PUT | :DELETE | :CONNECT | :OPTIONS | :TRACE | :PATCH

  @typedoc """
  A struct defining an HTTP Method and whether or not the method has a body.

  By default, `GET`, `HEAD`, `CONNECT`, `OPTIONS`, and `TRACE`
  methods have no body, while `POST`, `PUT`, `DELETE`, and `PATCH`
  methods have a body.
  """
  @type t :: %Method{name: method, has_body: boolean}
  defstruct name: :GET, has_body: false

  @spec get :: Method.t()
  def get, do: %Method{name: :GET, has_body: false}
  @spec head :: Method.t()
  def head, do: %Method{name: :HEAD, has_body: false}
  @spec post :: Method.t()
  def post, do: %Method{name: :POST, has_body: true}
  @spec put :: Method.t()
  def put, do: %Method{name: :PUT, has_body: true}
  @spec delete :: Method.t()
  def delete, do: %Method{name: :DELETE, has_body: true}
  @spec connect :: Method.t()
  def connect, do: %Method{name: :CONNECT, has_body: false}
  @spec options :: Method.t()
  def options, do: %Method{name: :OPTIONS, has_body: false}
  @spec trace :: Method.t()
  def trace, do: %Method{name: :TRACE, has_body: false}
  @spec patch :: Method.t()
  def patch, do: %Method{name: :PATCH, has_body: true}
end
