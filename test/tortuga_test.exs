defmodule TortugaTest do
  use ExUnit.Case
  doctest Tortuga

  test "greets the world" do
    assert Tortuga.hello() == :world
  end
end
