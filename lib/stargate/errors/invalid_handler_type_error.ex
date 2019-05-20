defmodule Stargate.Errors.InvalidHandlerTypeError do
  @moduledoc """
  The error that is raised when an invalid
  configuration is passed to `Stargate.warp_in/1`.
  """
  defexception [:message]

  @impl true
  @spec exception(handler_type :: binary) :: map
  def exception(handler_type) do
    message = """
    The request was made using the #{handler_type} handler type,
    which is currently unsupported by the Stargate Webserver.

    The current supported handler types are Websocket (ws) and HTTP.
    """

    %__MODULE__{message: message}
  end
end
