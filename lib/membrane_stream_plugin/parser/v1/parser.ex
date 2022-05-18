defmodule Membrane.Stream.Parser.V1.Elements do
  @moduledoc false
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

  defp do_parse(<<length::32, data::binary-size(length), rest::binary>>, acc) do
    element = :erlang.binary_to_term(data)
    do_parse(rest, [element | acc])
  end

  defp do_parse(_leftover, []), do: {:error, :not_enough_data}
  defp do_parse(leftover, acc), do: {:ok, Enum.reverse(acc), leftover}

  defp convert_to_actions(elements) do
    Enum.map(elements, fn
      {:buffer, %Membrane.Buffer{} = buffer} -> {:buffer, {:output, buffer}}
      {:caps, caps} -> {:caps, {:output, caps}}
      {:event, event} -> {:event, {:output, event}}
      :end_of_stream -> {:end_of_stream, :output}
      action -> raise "Unknown action: #{inspect(action)}"
    end)
    |> then(&{:ok, &1})
  end
end
