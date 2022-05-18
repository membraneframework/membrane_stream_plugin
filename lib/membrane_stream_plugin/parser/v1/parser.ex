defmodule Membrane.Stream.Parser.V1.Elements do
  @moduledoc false

  @magic "Action"

  @spec parse(binary()) ::
          {:ok, actions :: [Membrane.Element.Action.t()], leftover :: binary()}
          | {:error, reason :: atom()}
  def parse(data) do
    with {:ok, elements, leftover} <- do_parse(data),
         {:ok, actions} <- convert_to_actions(elements) do
      {:ok, actions, leftover}
    end
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
    Enum.map(elements, fn
      {:buffer, %Membrane.Buffer{} = buffer} -> {:buffer, {:output, buffer}}
      {:caps, caps} -> {:caps, {:output, caps}}
      {:event, event} -> {:event, {:output, event}}
      :end_of_stream -> {:end_of_stream, :output}
      # Food for thought: what should we do in such a case? We could technically discard it.
      # Technically, nothing should explode as we already handle buffers and caps.
      # That said, we shouldn't even get here anyway in the first place and who knows what will be possible in the future
      action -> raise "Unknown action: #{inspect(action)}"
    end)
    |> then(&{:ok, &1})
  end

  defp do_parse_return([], _leftover), do: {:error, :not_enough_data}
  defp do_parse_return(acc, leftover), do: {:ok, Enum.reverse(acc), leftover}
end
