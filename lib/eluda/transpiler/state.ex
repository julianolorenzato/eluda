defmodule Eluda.Transpiler.State do
  use Agent

  defstruct [:gen_vars, :scope_vars]

  defp initial_state(_ \\ nil) do
    %__MODULE__{
      gen_vars: [],
      scope_vars: []
    }
  end

  def start_link() do
    Agent.start_link(&initial_state/0, name: __MODULE__)
  end

  def add_gen_var(var) do
    Agent.update(__MODULE__, fn %__MODULE__{} = state ->
      Map.update!(state, :gen_vars, &[var | &1])
    end)
  end

  def add_scope_var(var) do
    Agent.update(__MODULE__, fn %__MODULE__{} = state ->
      Map.update!(state, :scope_vars, &[var | &1])
    end)
  end

  def reset() do
    Agent.update(__MODULE__, &initial_state/1)
  end
end
