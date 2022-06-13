defmodule Membrane.Stream.Serializer do
  @moduledoc """
  Element recording a stream of Membrane actions into binary format, suitable for saving to the file.

  Currently supported:
  - buffers
  - caps
  - events

  A stream can be restored
  """
  use Membrane.Filter
  alias Membrane.{Buffer, RemoteStream}
  alias Membrane.Stream.{Format, Format.Header}

  def_input_pad :input,
    caps: :any,
    demand_mode: :auto,
    demand_unit: :buffers

  def_output_pad :output,
    caps: {RemoteStream, content_format: Membrane.Stream},
    demand_mode: :auto

  def_options version: [
                spec: Format.version_t(),
                default: Format.get_current_version()
              ]

  @impl Membrane.Element.Base
  def handle_init(%__MODULE__{version: version}) do
    {:ok, serializer_fn} = Format.get_serializer(version)
    {:ok, %{serializer_fn: serializer_fn, version: version}}
  end

  @impl Membrane.Element.Base
  def handle_prepared_to_playing(_ctx, state) do
    caps = %RemoteStream{content_format: Membrane.Stream}

    header =
      state.version
      |> Header.build_header()
      |> then(&%Buffer{payload: &1})

    {{:ok, caps: {:output, caps}, buffer: {:output, header}}, state}
  end

  @impl Membrane.Element.WithInputPads
  def handle_caps(:input, caps, _ctx, state) do
    process({:caps, caps}, state)
  end

  @impl Membrane.Filter
  def handle_process(:input, buffer, _ctx, state) do
    process({:buffer, buffer}, state)
  end

  @impl Membrane.Element.Base
  def handle_event(:input, event, _ctx, state) do
    process({:event, event}, state)
  end

  @impl Membrane.Element.WithInputPads
  def handle_end_of_stream(:input, _ctx, state), do: {{:ok, end_of_stream: :output}, state}

  defp process(action, state) do
    serialized = state.serializer_fn.(action)
    {{:ok, buffer: {:output, %Buffer{payload: serialized}}}, state}
  end
end
