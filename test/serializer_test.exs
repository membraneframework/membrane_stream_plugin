defmodule Membrane.Stream.SerializerTest do
  use ExUnit.Case, async: true
  import Membrane.Testing.Assertions
  alias Membrane.{Buffer, ParentSpec, RemoteStream, Testing.Pipeline}

  alias Membrane.Stream.{Deserializer, Format.Header, Serializer}
  alias Membrane.Stream.Test.Support.TestingSource

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
          source: %TestingSource{actions: scenario},
          serializer: %Serializer{version: unquote(version)},
          deserializer: Deserializer,
          sink: Membrane.Testing.Sink
        ]

        {:ok, pid} = Pipeline.start_link(links: ParentSpec.link_linear(children))

        assert_start_of_stream(pid, :sink)

        Enum.each(scenario, fn
          {:buffer, {:output, buffer}} -> assert_sink_buffer(pid, :sink, ^buffer)
          {:caps, {:output, caps}} -> assert_sink_caps(pid, :sink, ^caps)
          {:event, {:output, event}} -> assert_sink_event(pid, :sink, ^event)
        end)

        assert_end_of_stream(pid, :sink)
        Pipeline.terminate(pid, blocking?: true)
      end

      test "Serializer creates correct header" do
        assert {:ok, state} = Serializer.handle_init(%Serializer{version: unquote(version)})
        assert {{:ok, actions}, _state} = Serializer.handle_prepared_to_playing(nil, state)

        assert {:output, %Buffer{payload: header}} = Keyword.fetch!(actions, :buffer)
        assert {:ok, %Header{version: unquote(version)}, <<>>} = Header.parse(header)
      end
    end
  end)
end
