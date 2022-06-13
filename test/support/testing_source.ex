defmodule Membrane.Stream.Test.Support.TestingSource do
  @moduledoc false
  use Membrane.Source
  alias Membrane.Element.{Action, Base, WithOutputPads}

  def_output_pad :output, caps: :any

  def_options actions: [
                spec: [Action.t()]
              ]

  @impl Base
  def handle_init(%__MODULE__{actions: actions} = _opts) do
    actions = actions

    {:ok, %{actions: actions}}
  end

  @impl WithOutputPads
  def handle_demand(:output, _size, :buffers, _ctx, state) do
    send(self(), :supply_demand)
    {:ok, state}
  end

  @impl Base
  def handle_other(:supply_demand, _ctx, %{actions: [action | actions]} = state) do
    {{:ok, [action, redemand: :output]}, %{state | actions: actions}}
  end

  @impl Base
  def handle_other(:supply_demand, _ctx, %{actions: []} = state) do
    {{:ok, end_of_stream: :output}, state}
  end
end
