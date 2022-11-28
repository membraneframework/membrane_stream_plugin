defmodule Membrane.Stream.Format do
  @moduledoc false
  # Module containing definition of behavior describing the implementation of specific version of the format and common type definitions

  @typedoc """
  Type describing actions carried by `Membrane.Stream`
  """
  @type action_t() ::
          {:buffer, Membrane.Buffer.t()}
          | {:event, any()}
          | {:stream_format, any()}

  @typedoc """

  """
  @type parser_return_t() ::
          {:ok, actions :: [Membrane.Element.Action.t()], leftover :: binary()}
          | {:error, reason :: atom()}
  @type parser_t() :: (binary() -> parser_return_t())

  @type serializer_t() :: (action_t() -> binary())

  @doc """
  Function that parses the body of the file format and returns the resulting Membrane actions.
  """
  @callback parse(binary()) :: parser_return_t()

  @doc """
  Function that serializes a action into a single part of the file format's body.
  """
  @callback serialize(action_t()) :: binary()
end
