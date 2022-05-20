defmodule Membrane.Stream.Format do
  @moduledoc false

  @type action_t() ::
          {:buffer, Membrane.Buffer.t()}
          | {:event, any()}
          | {:caps, any()}

  @callback parse(binary()) ::
              {:ok, actions :: [Membrane.Element.Action.t()], leftover :: binary()}
              | {:error, reason :: atom()}

  @callback serialize(action_t()) :: binary()

  @current_version 1
  @supported_versions [@current_version]

  @type version_t() :: 1

  defguard is_supported_version(version) when version in @supported_versions

  @implementations %{
    1 => __MODULE__.V1
  }

  @spec parse(version_t(), binary()) ::
          {:ok, actions :: [Membrane.Element.Action.t()], leftover :: binary()}
          | {:error, reason :: atom()}
  def parse(version, data) when is_supported_version(version) do
    @implementations[version].parse(data)
  end

  def parse(_version, _data), do: {:error, :unsupported_version}

  @spec serialize(version_t(), action_t()) :: binary()
  def serialize(version \\ @current_version, action)

  def serialize(version, action) when is_supported_version(version) do
    @implementations[version].serialize(action)
  end

  def serialize(_version, _action), do: {:error, :unsupported_version}
end
