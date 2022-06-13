defmodule Membrane.Stream.Format do
  @moduledoc false

  # Module containing definition of behavior describing the implementation of specific version of the format
  # as well as common type definitions and helper functions for finding the implementation

  @type action_t() ::
          {:buffer, Membrane.Buffer.t()}
          | {:event, any()}
          | {:caps, any()}

  @type version_t() :: 1
  @type parser_return_t() ::
          {:ok, actions :: [Membrane.Element.Action.t()], leftover :: binary()}
          | {:error, reason :: atom()}
  @type parser_t() :: (binary() -> parser_return_t())

  @doc """
  Function that parses the body of the file format and returns the resulting Membrane actions.
  """
  @callback parse(binary()) :: parser_return_t()

  @doc """
  Function that serializes a action into a single part of the file format's body.
  """
  @callback serialize(action_t()) :: binary()

  @implementations %{
    1 => __MODULE__.V1
  }

  @supported_versions Map.keys(@implementations)
  @current_version Enum.max(@supported_versions)

  defguardp is_supported_version(version) when version in @supported_versions

  @spec get_parser(version_t()) :: {:ok, parser_t()} | {:error, reason :: atom()}
  def get_parser(version) when is_supported_version(version) do
    {:ok, &@implementations[version].parse/1}
  end

  def get_parser(_version), do: {:error, :unsupported_version}

  @spec get_serializer(version_t()) ::
          {:ok, (action_t() -> binary())} | {:error, reason :: atom()}
  def get_serializer(version) when is_supported_version(version) do
    {:ok, &@implementations[version].serialize/1}
  end

  def get_serializer(_version), do: {:error, :unsupported_version}

  @spec get_current_version() :: version_t()
  def get_current_version, do: @current_version
end
