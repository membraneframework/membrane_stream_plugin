defmodule Membrane.Stream.Serializer.V1 do
  @moduledoc false
  @type action_t() ::
          {:buffer, Membrane.Buffer.t()}
          | {:event, any()}
          | {:caps, any()}

  @spec serialize(action_t) :: binary()
  def serialize(action) do
    stringified = :erlang.term_to_binary(action)
    size = byte_size(stringified)
    <<size::32, stringified::binary>>
  end
end
