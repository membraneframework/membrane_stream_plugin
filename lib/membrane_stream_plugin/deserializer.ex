defmodule Membrane.Stream.Deserializer do
  @moduledoc """
  Element restoring recorded data in Membrane.Stream format, as captured by `Membrane.Stream.Serializer`
  """
  use Membrane.Filter

  alias Membrane.{Buffer, RemoteStream}

  alias Membrane.Stream.Format.Header
  alias Membrane.Stream.Utils

  def_input_pad :input,
    accepted_format: %RemoteStream{content_format: format} when format in [nil, Membrane.Stream]

  def_output_pad :output, accepted_format: _any

  @impl true
  def handle_init(_ctx, _opts) do
    {[], %{partial: <<>>, header_read?: false, parser_fn: nil}}
  end

  @impl true
  def handle_stream_format(:input, _stream_format, _ctx, state), do: {[], state}

  @impl true
  def handle_buffer(:input, %Buffer{payload: payload}, ctx, %{header_read?: false} = state) do
    data = state.partial <> payload
    state = %{state | partial: data}

    case Header.parse(data) do
      {:ok, %Header{version: version}, leftover} ->
        {:ok, parser_fn} = Utils.get_parser(version)
        state = %{state | parser_fn: parser_fn, partial: leftover, header_read?: true}
        handle_buffer(:input, %Buffer{payload: ""}, ctx, state)

      {:error, :not_enough_data} ->
        {[], state}

      {:error, reason} ->
        raise "Failed to parse MSR header with reason: #{inspect(reason)}. Header: #{inspect(data, limit: :infinity)}"
    end
  end

  @impl true
  def handle_buffer(:input, %Buffer{payload: payload}, _ctx, %{header_read?: true} = state) do
    data = state.partial <> payload
    state = %{state | partial: data}

    case state.parser_fn.(data) do
      {:ok, actions, leftover} ->
        {actions, %{state | partial: leftover}}

      {:error, :not_enough_data} ->
        {[], state}

      {:error, reason} ->
        raise "Failed to parse Membrane Stream payload with reason: #{inspect(reason)}. Data: #{inspect(data, limit: :infinity)}"
    end
  end
end
