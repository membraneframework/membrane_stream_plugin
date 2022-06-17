defmodule Membrane.Stream.Utils do
  @moduledoc false

  alias Membrane.Stream.Format

  @implementations %{
    1 => Format.V1
  }

  @supported_versions Map.keys(@implementations)
  @current_version Enum.max(@supported_versions)

  defguardp is_supported_version(version) when version in @supported_versions

  @spec get_parser(Format.Version.t()) :: {:ok, Format.parser_t()} | {:error, reason :: atom()}
  def get_parser(version) when is_supported_version(version) do
    {:ok, &@implementations[version].parse/1}
  end

  def get_parser(_version), do: {:error, :unsupported_version}

  @spec get_serializer(Format.Version.t()) ::
          {:ok, (Format.action_t() -> binary())} | {:error, reason :: atom()}
  def get_serializer(version) when is_supported_version(version) do
    {:ok, &@implementations[version].serialize/1}
  end

  def get_serializer(_version), do: {:error, :unsupported_version}

  @spec get_current_version() :: Format.Version.t()
  def get_current_version, do: @current_version
end
