defmodule Membrane.Stream.Test.Support.TestingSource do
  @moduledoc false
  use Membrane.Source
  alias Membrane.Element.Action

  def_output_pad :output, accepted_format: _any

  def_options actions: [
                spec: [Action.t()]
              ]

  @impl true
  def handle_init(_ctx, %__MODULE__{actions: actions} = _opts) do
    actions = actions

    {[], %{actions: actions}}
  end

  @impl true
  def handle_demand(:output, _size, :buffers, _ctx, state) do
    send(self(), :supply_demand)
    {[], state}
  end

  @impl true
  def handle_info(:supply_demand, _ctx, %{actions: [action | actions]} = state) do
    {[action, redemand: :output], %{state | actions: actions}}
  end

  @impl true
  def handle_info(:supply_demand, _ctx, %{actions: []} = state) do
    {[end_of_stream: :output], state}
  end
end
