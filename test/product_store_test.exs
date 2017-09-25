defmodule RabbitsManagerTest do
  use ExUnit.Case
  doctest RabbitsManager

  test "greets the world" do
    assert RabbitsManager.hello() == :world
  end
end
