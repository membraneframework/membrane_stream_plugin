defmodule Membrane.Stream.Deserializer do
  @moduledoc """
  Element restoring recorded data in Membrane.Stream format, as captured by `Membrane.Stream.Serializer`
  """
  use Membrane.Filter

  alias Membrane.{Buffer, RemoteStream}
  alias Membrane.Caps.Matcher

  alias Membrane.Stream.Format.{Header, Versions}

  def_input_pad :input,
    caps: {RemoteStream, content_format: Matcher.one_of([nil, Membrane.Stream])},
    demand_unit: :buffers,
    demand_mode: :auto

  def_output_pad :output,
    caps: :any,
    demand_mode: :auto

  @impl true
  def handle_init(_opts) do
    {:ok, %{partial: <<>>, header_read?: false, parser_fn: nil}}
  end

  @impl true
  def handle_caps(:input, _caps, _ctx, state), do: {:ok, state}

  @impl true
  def handle_process(:input, %Buffer{payload: payload}, ctx, %{header_read?: false} = state) do
    data = state.partial <> payload
    state = %{state | partial: data}

    case Header.parse(data) do
      {:ok, %Header{version: version}, leftover} ->
        {:ok, parser_fn} = Versions.get_parser(version)
        state = %{state | parser_fn: parser_fn, partial: leftover, header_read?: true}
        handle_process(:input, %Buffer{payload: ""}, ctx, state)

      {:error, :not_enough_data} ->
        {:ok, state}

      {:error, reason} ->
        raise "Failed to parse MSR header with reason: #{inspect(reason)}. Header: #{inspect(data, limit: :infinity)}"
    end
  end

  @impl true
  def handle_process(:input, %Buffer{payload: payload}, _ctx, %{header_read?: true} = state) do
    data = state.partial <> payload
    state = %{state | partial: data}

    case state.parser_fn.(data) do
      {:ok, actions, leftover} ->
        {{:ok, actions}, %{state | partial: leftover}}

      {:error, :not_enough_data} ->
        {:ok, state}

      {:error, reason} ->
        raise "Failed to parse Membrane Stream payload with reason: #{inspect(reason)}. Data: #{inspect(data, limit: :infinity)}"
    end
  end
end
