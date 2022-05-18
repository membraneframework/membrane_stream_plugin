defmodule Membrane.Stream.Deserializer do
  @moduledoc false
  use Membrane.Filter

  alias Membrane.{Buffer, RemoteStream}
  alias Membrane.Caps.Matcher
  alias Membrane.Stream.Parser

  @parsers %{
    1 => Parser.V1.Elements
  }

  def_input_pad :input,
    caps: {RemoteStream, content_format: Matcher.one_of([nil, Membrane.Stream])},
    demand_unit: :buffers,
    demand_mode: :auto

  def_output_pad :output,
    caps: :any,
    demand_mode: :auto

  @impl true
  def handle_init(_opts) do
    {:ok, %{partial: <<>>, header_read?: false, parser: nil}}
  end

  @impl true
  def handle_caps(:input, _caps, _ctx, state), do: {:ok, state}

  @impl true
  def handle_process(:input, %Buffer{payload: payload}, _ctx, %{header_read?: false} = state) do
    data = state.partial <> payload
    state = %{state | partial: data}

    case Membrane.Stream.Header.parse(data) do
      {:ok, %Membrane.Stream.Header{version: version}, leftover} ->
        parser = Map.get(@parsers, version)
        {:ok, %{state | parser: parser, partial: leftover, header_read?: true}}

      {:error, :not_enough_data} ->
        {:ok, state}

      {:error, reason} ->
        raise "Failed to parse Membrane Stream header with reason: #{inspect(reason)}"
    end
  end

  @impl true
  def handle_process(:input, %Buffer{payload: payload}, _ctx, %{header_read?: true} = state) do
    data = state.partial <> payload
    state = %{state | partial: data}

    case state.parser.parse(data) do
      {:ok, actions, leftover} ->
        {{:ok, actions}, %{state | partial: leftover}}

      {:error, :not_enough_data} ->
        {:ok, state}

      {:error, reason} ->
        raise "Failed to parse Membrane Stream payload with reason: #{inspect(reason)}"
    end
  end
end
