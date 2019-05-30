defmodule VintageNet.WizardTest do
  use ExUnit.Case
  doctest VintageNet.Wizard

  test "greets the world" do
    assert VintageNet.Wizard.hello() == :world
  end
end
