defmodule Membrane.Stream.Serializer do
  @moduledoc """
  Element recording a stream of Membrane actions into binary format, suitable for saving to the file.

  Currently supported, as of V#{Membrane.Stream.Utils.get_current_version()}:
  - buffers
  - stream_format
  - events

  A stream can be replayed using `Membrane.Stream.Deserializer`:
  """
  use Membrane.Filter
  alias Membrane.{Buffer, RemoteStream}
  alias Membrane.Stream.Format.Header

  alias Membrane.Stream.Utils

  def_input_pad :input,
    accepted_format: _any,
    demand_mode: :auto,
    demand_unit: :buffers

  def_output_pad :output,
    accepted_format: %RemoteStream{content_format: Membrane.Stream},
    demand_mode: :auto

  def_options version: [
                spec: Membrane.Stream.Format.Version.t(),
                default: Utils.get_current_version()
              ]

  @impl true
  def handle_init(_ctx, %__MODULE__{version: version}) do
    {:ok, serializer_fn} = Utils.get_serializer(version)
    {[], %{serializer_fn: serializer_fn, version: version}}
  end

  @impl true
  def handle_playing(_ctx, state) do
    stream_format = %RemoteStream{content_format: Membrane.Stream}

    header =
      state.version
      |> Header.build()
      |> then(&%Buffer{payload: &1})

    {[stream_format: {:output, stream_format}, buffer: {:output, header}], state}
  end

  @impl true
  def handle_stream_format(:input, stream_format, _ctx, state) do
    process({:stream_format, stream_format}, state)
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
  def handle_end_of_stream(:input, _ctx, state), do: {[end_of_stream: :output], state}

  defp process(action, state) do
    serialized = state.serializer_fn.(action)
    {[buffer: {:output, %Buffer{payload: serialized}}], state}
  end
end
