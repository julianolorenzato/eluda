defmodule EludaTest do
  use ExUnit.Case
  doctest Eluda

  test "greets the world" do
    assert Eluda.hello() == :world
  end
end
