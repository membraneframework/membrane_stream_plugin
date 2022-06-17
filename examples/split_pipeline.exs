# This examples show how to split the pipeline into two independent parts using `Membrane.Stream.Plugin`
# To run it, execute `elixir <filename>` in your console

# Installs mix dependencies
Mix.install([
  {:membrane_core, "~> 0.10.1"},
  {:membrane_hackney_plugin, "~> 0.8.2"},
  {:membrane_h264_ffmpeg_plugin, "~> 0.21.1"},
  {:membrane_sdl_plugin, "~> 0.14.0"},
  {:membrane_stream_plugin, path: __DIR__ |> Path.join("..") |> Path.expand()},
  {:membrane_file_plugin, "~> 0.12.0"}
])

# This pipeline is responsible for downloading the content from our static repository and
# prepares it for playback. Normally, decoder would be instantly followed by a player, but in this case
# we are serializing the stream and saving it to a file
defmodule Sender do
  use Membrane.Pipeline

  @impl true
  def handle_init(_opts) do
    children = [
      source: %Membrane.Hackney.Source{
        location:
          "https://raw.githubusercontent.com/membraneframework/static/gh-pages/samples/ffmpeg-testsrc.h264",
        hackney_opts: [follow_redirect: true]
      },
      parser: %Membrane.H264.FFmpeg.Parser{framerate: {30, 1}, alignment: :au},
      decoder: Membrane.H264.FFmpeg.Decoder,
      serializer: Membrane.Stream.Serializer,
      sink: %Membrane.File.Sink{location: "example.msr"}
    ]

    {{:ok, spec: %ParentSpec{links: ParentSpec.link_linear(children)}, playback: :playing}, %{}}
  end

  # These two `handle_element_end_of_stream/3` clauses are only used to terminate the pipeline after processing finished
  # This part is considered the business logic, you don't need to worry about it in this example
  @impl true
  def handle_element_end_of_stream({:sink, _pad}, _ctx, state) do
    Sender.terminate(self())
    {:ok, state}
  end

  @impl true
  def handle_element_end_of_stream(_element, _ctx, state) do
    {:ok, state}
  end
end

# Following the completion of the Sender pipeline, we are going to read the saved stream and play it
defmodule Receiver do
  use Membrane.Pipeline

  @impl true
  def handle_init(_opts) do
    spec = %ParentSpec{
      children: [
        source: %Membrane.File.Source{location: "example.msr"},
        deserializer: Membrane.Stream.Deserializer,
        player: Membrane.SDL.Player
      ],
      links: [
        link(:source) |> to(:deserializer) |> to(:player)
      ]
    }

    {{:ok, spec: spec, playback: :playing}, %{}}
  end

  # These two `handle_element_end_of_stream/3` clauses are only used to terminate the pipeline after processing finished
  # This part is considered the business logic, you don't need to worry about it in this example
  @impl true
  def handle_element_end_of_stream({:player, _pad}, _ctx, state) do
    Receiver.terminate(self())
    {:ok, state}
  end

  @impl true
  def handle_element_end_of_stream(_element, _ctx, state) do
    {:ok, state}
  end
end

# Run the two pipelines one after the other

## Start the Sender and await its completion
{:ok, sender_pid} = Sender.start_link()
sender_monitor = Process.monitor(sender_pid)

receive do
  {:DOWN, ^sender_monitor, :process, _pid, reason} ->
    unless reason == :normal,
      do: raise("Saving a stream to a file failed with reason: #{inspect(reason)}")

    IO.puts("Recording has been processed and saved to a file `example.msr`")
end

## Started the Receiver and await its completion
IO.puts("Playing the recorded file")
{:ok, receiver_pid} = Receiver.start_link()
receiver_monitor = Process.monitor(receiver_pid)

receive do
  {:DOWN, ^receiver_monitor, :process, _pid, reason} ->
    unless reason == :normal,
      do: raise("Playing the recorded stream failed with reason: #{inspect(reason)}")

    IO.puts("Playback finished, terminating")
end
