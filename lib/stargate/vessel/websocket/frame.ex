defmodule Stargate.Vessel.Websocket.Frame do
  @moduledoc """
  A websocket frame helper, used to parse and generate websocket frames.
  """
  # credo:disable-for-this-file

  @typep opcode :: :continuation | :text | :binary | :close | :ping | :pong
  @typep fin_bit :: :fin | :not_fin
  @typep mask_bit :: :masked | :unmasked
  @typep payload :: bitstring | binary | nil
  @typedoc "A properly parsed websocket frame"
  @type frame :: {:ok, fin_bit, mask_bit, opcode, payload}

  @typep reason :: :no_fin_and_opcode_match | :unmasked_frame | :not_implemented_yet
  @typedoc "Errors that occur when parsing a websocket frame"
  @type parse_error :: {:error, reason}

  ## MASK Bit
  @unmasked <<0::size(1)>>
  @masked <<1::size(1)>>
  ## FIN Bit
  @not_fin <<0::size(1)>>
  @fin <<1::size(1)>>
  ## Opcodes
  # 0x0
  @continuation <<0::size(1), 0::size(1), 0::size(1), 0::size(1)>>
  # 0x1
  @text <<0::size(1), 0::size(1), 0::size(1), 1::size(1)>>
  # 0x2
  @binary <<0::size(1), 0::size(1), 1::size(1), 0::size(1)>>
  # 0x8
  @close <<1::size(1), 0::size(1), 0::size(1), 0::size(1)>>
  # 0x9
  @ping <<1::size(1), 0::size(1), 0::size(1), 1::size(1)>>
  # 0xA
  @pong <<1::size(1), 0::size(1), 1::size(1), 0::size(1)>>

  @spec parse_frame(binary) :: frame | parse_error
  def parse_frame(<<@fin::bits, _::bits-size(3), @continuation::bits, _rest::bits>> = _frame) do
    # TODO: Parse Final Continuation Frame
    {:error, :not_implemented_yet}
  end

  def parse_frame(<<@fin::bits, _::bits-size(3), @text::bits, rest::bits>> = _frame) do
    case parse(rest) do
      {:ok, payload} -> {:ok, :fin, :masked, :text, payload}
      error -> error
    end
  end

  def parse_frame(<<@fin::bits, _::bits-size(3), @binary::bits, _rest::bits>> = _frame) do
    # TODO: Parse Final Binary Frame
    {:error, :not_implemented_yet}
  end

  def parse_frame(<<@fin::bits, _::bits-size(3), @close::bits, _rest::bits>> = _frame) do
    # TODO: Parse Final Close Frame
    {:error, :not_implemented_yet}
  end

  def parse_frame(<<@fin::bits, _::bits-size(3), @ping::bits, _rest::bits>> = _frame) do
    # TODO: Parse Final Ping Frame
    {:error, :not_implemented_yet}
  end

  def parse_frame(<<@fin::bits, _::bits-size(3), @pong::bits, _rest::bits>> = _frame) do
    # TODO: Parse Final Pong Frame
    {:error, :not_implemented_yet}
  end

  def parse_frame(<<@not_fin::bits, _::bits-size(3), @continuation::bits, _rest::bits>> = _frame) do
    # TODO: Parse Not Final Continuation Frame
    {:error, :not_implemented_yet}
  end

  def parse_frame(<<@not_fin::bits, _::bits-size(3), @text::bits, _rest::bits>> = _frame) do
    # TODO: Parse Not Final Text Frame
    {:error, :not_implemented_yet}
  end

  def parse_frame(<<@not_fin::bits, _::bits-size(3), @binary::bits, _rest::bits>> = _frame) do
    # TODO: Parse Not Final Binary Frame
    {:error, :not_implemented_yet}
  end

  def parse_frame(_frame), do: {:error, :no_fin_and_opcode_match}

  @spec parse(bitstring) :: {:ok, binary} | parse_error
  defp parse(<<@masked::bits, rest::bits>> = _frame) do
    {payload_length, masked_payload} = parse_payload_length(rest)
    <<masking_key::bits-size(32), payload::bits>> = masked_payload

    decoded =
      Enum.reduce(0..(payload_length - 1), "", fn i, decoded ->
        <<mask>> = binary_part(masking_key, rem(i, 4), 1)
        <<encoded>> = binary_part(payload, i, 1)
        decoded <> <<:erlang.bxor(encoded, mask)>>
      end)

    {:ok, decoded}
  end

  defp parse(<<@unmasked::bits, _rest::bits>> = _frame), do: {:error, :unmasked_frame}

  @spec parse_payload_length(bitstring) :: {non_neg_integer, bitstring}
  defp parse_payload_length(<<first_len::unsigned-integer-7, rest::bits>> = _frame) do
    case first_len do
      126 ->
        <<actual_len::unsigned-integer-16, masked_payload::bits>> = rest
        {actual_len, masked_payload}

      127 ->
        <<actual_len::unsigned-integer-64, masked_payload::bits>> = rest
        {actual_len, masked_payload}

      _ ->
        {first_len, rest}
    end
  end
end
