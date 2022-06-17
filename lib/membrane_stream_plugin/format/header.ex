defmodule Membrane.Stream.Format.Header do
  @moduledoc false

  @magic "MSR"

  @enforce_keys [:version]
  defstruct @enforce_keys

  @type t() :: %__MODULE__{
          version: non_neg_integer()
        }

  # This part of the header is set in stone
  @spec parse(binary()) :: {:ok, header :: t(), leftover :: binary()} | {:error, reason :: atom()}
  def parse(<<@magic, version::8, rest::binary>>) do
    header = %__MODULE__{version: version}
    {:ok, header, rest}
  end

  def parse(incomplete_header) when byte_size(incomplete_header) < 4 do
    {:error, :not_enough_data}
  end

  def parse(_not_a_header) do
    {:error, :malformed}
  end

  @spec build(non_neg_integer()) :: binary()
  def build(version) do
    <<@magic, version::8>>
  end
end
