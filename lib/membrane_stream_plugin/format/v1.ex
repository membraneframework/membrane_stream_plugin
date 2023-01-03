defmodule Membrane.Stream.Format.V1 do
  @moduledoc false

  @behaviour Membrane.Stream.Format

  require Membrane.Logger

  alias Membrane.Buffer

  @magic "TERM"

  @spec parse(binary()) ::
          {:ok, actions :: [Membrane.Element.Action.t()], leftover :: binary()}
          | {:error, reason :: atom()}
  def parse(data) do
    with {:ok, elements, leftover} <- do_parse(data),
         {:ok, actions} <- convert_to_actions(elements) do
      {:ok, actions, leftover}
    end
  end

  @spec serialize(Membrane.Stream.Format.action_t()) :: binary()
  def serialize(action) do
    {:ok, term} = action_to_term(action)
    stringified = :erlang.term_to_binary(term)

    # TODO: include a guard to protect from the overflow of the length field
    # IDEA: if overflow issues are encountered, consider introducing fragmentation in later versions
    size = byte_size(stringified)
    <<@magic, size::32, stringified::binary>>
  end

  defp do_parse(data, acc \\ [])

  defp do_parse(binary, acc) when byte_size(binary) < byte_size(@magic) + 4,
    do: do_parse_return(acc, binary)

  defp do_parse(<<@magic, length::32, rest::binary>> = binary, acc) when byte_size(rest) < length,
    do: do_parse_return(acc, binary)

  defp do_parse(<<@magic, length::32, payload::binary-size(length), rest::binary>>, acc) do
    element = :erlang.binary_to_term(payload)
    do_parse(rest, [element | acc])
  end

  defp do_parse(_not_a_packet, _acc), do: {:error, :malformed_action}

  defp convert_to_actions(elements) do
    actions = Enum.map(elements, &term_to_action/1)

    if Enum.any?(actions, &(:error == &1)) do
      {:error, :unknown_action}
    else
      actions
      |> Enum.map(fn {:ok, action} -> action end)
      |> then(&{:ok, &1})
    end
  end

  defp do_parse_return([], _leftover), do: {:error, :not_enough_data}
  defp do_parse_return(acc, leftover), do: {:ok, Enum.reverse(acc), leftover}

  defp action_to_term({:stream_format, stream_format}), do: {:ok, {:caps, stream_format}}
  defp action_to_term(action), do: {:ok, action}

  defp term_to_action({:caps, caps}), do: {:ok, {:stream_format, {:output, caps}}}
  defp term_to_action(:end_of_stream), do: {:ok, {:end_of_stream, :output}}
  defp term_to_action({:event, event}), do: {:ok, {:event, {:output, event}}}
  defp term_to_action({:buffer, %Buffer{} = buffer}), do: {:ok, {:buffer, {:output, buffer}}}

  defp term_to_action(action) do
    Membrane.Logger.error("Encountered unknown action: #{inspect(action)}")
    {:error, :unknown_action}
  end
end
