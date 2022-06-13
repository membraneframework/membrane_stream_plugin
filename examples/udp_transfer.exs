Mix.install([
  {:membrane_core, "~> 0.10.1"},
  {:membrane_udp_plugin, github: "membraneframework/membrane_udp_plugin", branch: "bugfix/emsgsize"},
  {:membrane_hackney_plugin, "~> 0.8.2"},
  {:membrane_h264_ffmpeg_plugin, "~> 0.21.1"},
  {:membrane_sdl_plugin, "~> 0.14.0"},
  {:membrane_stream_plugin, path: __DIR__ |> Path.join("..") |> Path.expand()}
])

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
      parser: %Membrane.H264.FFmpeg.Parser{framerate: {30,1}, alignment: :au},
      serializer: Membrane.Stream.Serializer,
      sink: %Membrane.UDP.Sink{destination_address: {127, 0, 0, 1}, destination_port_no: 1234, max_msg_size: 1024}
    ]

    {{:ok, spec: %ParentSpec{links: ParentSpec.link_linear(children)}, playback: :playing}, %{}}
  end

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

defmodule Receiver do
  use Membrane.Pipeline

  @impl true
  def handle_init(_opts) do
    children = [
      source: %Membrane.UDP.Source{local_port_no: 1234, local_address: {127,0,0,1}},
      deserializer: Membrane.Stream.Deserializer,
      decoder: Membrane.H264.FFmpeg.Decoder,
      player: Membrane.SDL.Player
    ]

    {{:ok, spec: %ParentSpec{links: ParentSpec.link_linear(children)}, playback: :playing}, %{}}
  end

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

{:ok, receiver_pid} = Receiver.start_link()
Process.sleep(1000)
{:ok, sender_pid} = Sender.start_link()

Process.sleep(10_000)
