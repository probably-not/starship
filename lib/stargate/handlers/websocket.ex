defmodule Stargate.Handlers.Websocket do
  @moduledoc """
  A behaviour module fo use when creating HTTP handlers for the `Stargate` Webserver.
  """
  alias Stargate.Handlers.Websocket
  alias Stargate.Vessel.Conn

  @callback connect(Conn.t(), map) :: {:ok, map} | :reject
  @callback handle_text(bitstring, map) :: {binary, map}
  @callback handle_binary(binary, map) :: {binary, map}
  @callback handle_close(binary, map) :: {binary, map}

  @optional_callbacks handle_binary: 2

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @behaviour Websocket
      @before_compile Websocket

      @doc false
      def handle_text(text, config) do
        {text, config}
      end

      @doc false
      def handle_binary(binary, config) do
        {binary, config}
      end

      @doc false
      def handle_close(binary, config) do
        {binary, config}
      end

      defoverridable handle_text: 2, handle_binary: 2, handle_close: 2
    end
  end

  defmacro __before_compile__(env) do
    unless Module.defines?(env.module, {:connect, 2}) do
      message = """
      function connect/2 required by behaviour `Stargate.Handlers.Websocket` is not implemented \
      (in module #{inspect(env.module)}).
      We will inject a default implementation for now:
          def connect(_conn, config) do
            {:ok, config}
          end
      You can copy the implementation above or define your own that performs \
      actions that you want before accepting or rejecting the connection to the websocket.
      """

      IO.warn(message, Macro.Env.stacktrace(env))

      quote do
        @doc false
        @spec connect(Conn.t(), map) :: {:ok, map}
        def connect(%Conn{} = _conn, config) do
          {:ok, config}
        end

        defoverridable connect: 2
      end
    end
  end
end
