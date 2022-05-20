defmodule Membrane.Stream.SerializerTest do
  use ExUnit.Case, async: true
  import Membrane.Testing.Assertions
  alias Membrane.{Buffer, RemoteStream}
  alias Membrane.Testing.Pipeline

  @supported_versions [1]

  Enum.map(@supported_versions, fn version ->
    describe_str = "Version #{version}"

    describe describe_str do
      test "Passes end-to-end integration test" do
        scenario = [
          caps: {:output, %RemoteStream{content_format: Testing}},
          buffer: {:output, %Buffer{payload: "1"}},
          event: {:output, %Event{data: :a}},
          buffer: {:output, %Buffer{payload: "2"}},
          buffer: {:output, %Buffer{payload: "3"}},
          event: {:output, %Event{data: :b}}
        ]

        children = [
          source: %Membrane.Stream.Test.Support.TestingSource{actions: scenario},
          serializer: %Membrane.Stream.Serializer{version: unquote(version)},
          deserializer: Membrane.Stream.Deserializer,
          sink: Membrane.Testing.Sink
        ]

        {:ok, pid} = Pipeline.start_link(links: Membrane.ParentSpec.link_linear(children))
        Pipeline.execute_actions(pid, playback: :playing)

        assert_start_of_stream(pid, :sink)

        Enum.each(scenario, fn
          {:buffer, {:output, buffer}} -> assert_sink_buffer(pid, :sink, ^buffer)
          {:caps, {:output, caps}} -> assert_sink_caps(pid, :sink, ^caps)
          {:event, {:output, event}} -> assert_sink_event(pid, :sink, ^event)
        end)

        assert_end_of_stream(pid, :sink)
        Pipeline.terminate(pid, blocking?: true)
      end
    end
  end)
end
