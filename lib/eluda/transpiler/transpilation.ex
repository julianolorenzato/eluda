defmodule Eluda.Transpiler.Transpilation do
  use Agent

  defstruct [:unique_name, :gen_vars, :scope_vars]

  @typep gen_var() :: {atom(), Range.t() | atom(), integer()}
  @typep scope_var() :: atom()
  # @typep used_scope_var() :: {atom(), tuple()}

  @type t() :: %__MODULE__{
          unique_name: charlist(),
          gen_vars: [gen_var()],
          scope_vars: MapSet.t()
          # used_scope_vars: [used_scope_var()]
        }

  defp initial_state(_ \\ nil) do
    %__MODULE__{
      unique_name: nil,
      gen_vars: [],
      scope_vars: MapSet.new() # maybe should be better change to MapSet, key s the symbol and value is the index
      # used_scope_vars: []
    }
  end

  @spec start_link() :: {:ok, pid()}
  def start_link() do
    Agent.start_link(&initial_state/0, name: __MODULE__)
  end

  @spec set_unique_name() :: :ok
  def set_unique_name() do
    unique_name = ~c"f#{:erlang.phash2(:erlang.unique_integer())}"

    Agent.update(__MODULE__, fn %__MODULE__{} = state ->
      Map.replace!(state, :unique_name, unique_name)
    end)
  end

  @spec unique_name() :: charlist()
  def unique_name() do
    Agent.get(__MODULE__, & &1.unique_name)
  end

  @spec add_scope_var(scope_var()) :: :ok
  def add_scope_var(var) do
    Agent.update(__MODULE__, fn %__MODULE__{} = state ->
      # Map.update!(state, :scope_vars, &[var | &1])
      MapSet.put()
    end)
  end

  @spec mark_used_scope_var(atom()) :: :ok
  def mark_used_scope_var(sym) do
    Agent.update(__MODULE__, fn %__MODULE__{} = state ->
      Map.update!(state, :scope_vars, fn vars ->
        greatest_index = Enum.reduce(vars, -1, fn {_symbol, idx}, acc ->
          if is_integer(idx) && idx > acc do
            idx
          else
            acc
          end
        end)

        Enum.map(vars, fn {symbol, _} = v ->
          if symbol == sym do
            {symbol, greatest_index + 1}
          else
            v
          end
        end)
      end)
    end)
  end

  @spec scope_vars() :: [scope_var()]
  def scope_vars(), do: Agent.get(__MODULE__, & &1.scope_vars)

  @spec add_gen_var(gen_var()) :: :ok
  def add_gen_var(var) do
    Agent.update(__MODULE__, fn %__MODULE__{} = state ->
      Map.update!(state, :gen_vars, &[var | &1])
    end)
  end

  @spec gen_vars() :: [gen_var()]
  def gen_vars(), do: Agent.get(__MODULE__, & &1.gen_vars)

  # @spec add_used_scope_var(used_scope_var()) :: :ok
  # def add_used_scope_var(var) do
  #   Agent.update(__MODULE__, fn %__MODULE__{} = state ->
  #     Map.update!(state, :used_scope_vars, &[var | &1])
  #   end)
  # end

  # @spec used_scope_vars() :: [used_scope_var()]
  # def used_scope_vars(), do: Agent.get(__MODULE__, & &1.used_scope_vars)

  @spec reset() :: :ok
  def reset() do
    Agent.update(__MODULE__, &initial_state/1)
  end

  def state(), do: Agent.get(__MODULE__, & &1)

  @spec stop :: :ok
  def stop do
    Agent.stop(__MODULE__)
  end
end
