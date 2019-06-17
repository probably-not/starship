defmodule Stargate.Vessel.Websocket.OldFrame do
  @moduledoc """
  A websocket frame helper, originally taken from another project that was parsing websocket frames.

  This is very old code, used for learning purposes so I can understand how to parse websocket frames correctly.
  """

  @no_mask <<0::size(1)>>
  @mask <<1::size(1)>>

  ## fin bit
  @final <<1::size(1)>>

  ## opcode definitions
  # 1
  @text <<0::size(1), 0::size(1), 0::size(1), 1::size(1)>>
  # 8
  @close <<1::size(1), 0::size(1), 0::size(1), 0::size(1)>>

  def translate_payload(<<masking_key::bits-size(32), payload::bits>>) do
    translate_payload(payload, masking_key, 0, "")
  end

  defp translate_payload(<<>>, _, _, decoded) do
    decoded
  end

  defp translate_payload(payload, masking_key, i, decoded) do
    <<m>> = binary_part(payload, 0, 1)
    <<n>> = binary_part(masking_key, rem(i, 4), 1)

    translate_payload(
      binary_part(payload, 1, byte_size(payload) - 1),
      masking_key,
      i + 1,
      decoded <> <<:erlang.bxor(m, n)>>
    )
  end

  def format_server_frame(payload, :text) do
    <<@final::bits, 0::size(3), @text::bits, @no_mask::bits, byte_size(payload)::size(7),
      payload::binary>>
  end

  def format_server_frame(payload, :close) do
    <<@final::bits, 0::size(3), @close::bits, @no_mask::bits, byte_size(payload)::size(7),
      payload::binary>>
  end

  def format_client_frame(masking_key, payload, opcode) do
    masked_payload = translate_payload(masking_key <> <<payload::binary>>)

    <<@final::bits, 0::size(3), opcode::bits, @mask::bits, byte_size(payload)::size(7),
      masking_key::binary, masked_payload::binary>>
  end
end
