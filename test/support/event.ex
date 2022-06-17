defmodule Event do
  @moduledoc false

  @derive Membrane.EventProtocol

  @type t() :: %__MODULE__{data: any()}

  @enforce_keys [:data]
  defstruct @enforce_keys
end
