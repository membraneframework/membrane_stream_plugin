defmodule Membrane.Stream.Serializer do
  @moduledoc false
  use Membrane.Filter
  alias Membrane.{Buffer, RemoteStream}

  @current_version 1
  @type version_t() :: 1

  @serializers %{
    1 => __MODULE__.V1
  }

  def_input_pad :input,
    caps: :any,
    demand_mode: :auto,
    demand_unit: :buffers

  def_output_pad :output,
    caps: {RemoteStream, content_format: Membrane.Stream},
    demand_mode: :auto

  def_options version: [
                spec: version_t(),
                default: @current_version
              ]

  @impl true
  def handle_init(%__MODULE__{version: version}) do
    serializer = Map.get(@serializers, version)
    {:ok, %{serializer: serializer, version: version}}
  end

  @impl true
  def handle_prepared_to_playing(_ctx, state) do
    caps = %RemoteStream{content_format: Membrane.Stream}

    header =
      state.version
      |> Membrane.Stream.Header.build_header()
      |> then(&%Buffer{payload: &1})

    {{:ok, caps: {:output, caps}, buffer: {:output, header}}, state}
  end

  @impl true
  def handle_caps(:input, caps, _ctx, state) do
    process({:caps, caps}, state)
  end

  @impl true
  def handle_process(:input, buffer, _ctx, state) do
    process({:buffer, buffer}, state)
  end

  @impl true
  def handle_event(:input, event, _ctx, state) do
    process({:event, event}, state)
  end

  @impl true
  def handle_end_of_stream(:input, _ctx, state) do
    process(:end_of_stream, state)
  end

  defp process(action, state) do
    serialized = state.serializer.serialize(action)
    {{:ok, buffer: {:output, %Buffer{payload: serialized}}}, state}
  end
end
