defmodule Membrane.Stream.FormatTest do
  use ExUnit.Case, async: true

  import Membrane.Testing.Assertions
  import Membrane.ChildrenSpec

  alias Membrane.{Buffer, RemoteStream, Testing.Pipeline}

  alias Membrane.Stream.{Deserializer, Format.Header, Serializer}
  alias Membrane.Stream.Test.Support.TestingSource

  @supported_versions [1]

  Enum.map(@supported_versions, fn version ->
    describe_str = "Version #{version}"

    describe describe_str do
      test "header" do
        assert {[], state} = Serializer.handle_init(nil, %Serializer{version: unquote(version)})
        assert {actions, _state} = Serializer.handle_playing(nil, state)

        assert {:output, %Buffer{payload: header}} = Keyword.fetch!(actions, :buffer)
        assert {:ok, %Header{version: unquote(version)}, <<>>} = Header.parse(header)
      end

      @tag :tmp_dir
      test "serializer and deserializer", %{tmp_dir: dir} do
        tmp_file = Path.join(dir, "v#{unquote(version)}.msr")

        serializing_pipeline =
          Pipeline.start_link_supervised!(
            spec:
              child(:source, %TestingSource{actions: scenario()})
              |> child(:serializer, %Serializer{version: unquote(version)})
              |> child(:sink, %Membrane.File.Sink{location: tmp_file})
          )

        assert_end_of_stream(serializing_pipeline, :sink)
        Pipeline.terminate(serializing_pipeline)

        assert File.exists?(tmp_file)

        deserializing_pipeline =
          Pipeline.start_link_supervised!(
            spec:
              child(:source, %Membrane.File.Source{location: tmp_file})
              |> child(:deserializer, Deserializer)
              |> child(:sink, Membrane.Testing.Sink)
          )

        assert_scenario(deserializing_pipeline)
        Pipeline.terminate(deserializing_pipeline)
      end

      test "deserializer" do
        pipeline =
          Pipeline.start_link_supervised!(
            spec:
              child(:source, %Membrane.File.Source{location: reference_file(unquote(version))})
              |> child(:deserializer, Deserializer)
              |> child(:sink, Membrane.Testing.Sink)
          )

        assert_scenario(pipeline)
        Pipeline.terminate(pipeline)
      end
    end
  end)

  defp reference_file(version), do: Path.join(["test", "fixtures", "v#{version}.msr"])

  defp assert_scenario(pipeline) do
    assert_start_of_stream(pipeline, :sink)

    Enum.each(scenario(), fn
      {:buffer, {:output, buffer}} ->
        assert_sink_buffer(pipeline, :sink, ^buffer)

      {:stream_format, {:output, stream_format}} ->
        assert_sink_stream_format(pipeline, :sink, ^stream_format)

      {:event, {:output, event}} ->
        assert_sink_event(pipeline, :sink, ^event)
    end)

    assert_end_of_stream(pipeline, :sink)
  end

  defp scenario do
    [
      stream_format: {:output, %RemoteStream{content_format: Testing}},
      buffer: {:output, %Buffer{payload: "1"}},
      event: {:output, %Event{data: :a}},
      buffer: {:output, %Buffer{payload: "2"}},
      buffer: {:output, %Buffer{payload: "3"}},
      event: {:output, %Event{data: :b}}
    ]
  end
end
