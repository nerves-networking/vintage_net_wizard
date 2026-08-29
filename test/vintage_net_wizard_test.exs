# SPDX-FileCopyrightText: 2019 Connor Rigby
# SPDX-FileCopyrightText: 2019 Frank Hunleth
# SPDX-FileCopyrightText: 2019 Jon Carstens
# SPDX-FileCopyrightText: 2021 Matt Ludwigs
# SPDX-FileCopyrightText: 2023 Masatoshi Nishiguchi
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule VintageNetWizardTest do
  use ExUnit.Case
  doctest VintageNetWizard

  test "on_exit callback mfa" do
    key = :on_exit_receive

    # make sure we start with fresh state
    VintageNetWizard.stop_wizard()

    VintageNetWizard.run_wizard(on_exit: {__MODULE__, :callback_tester, [key]})
    VintageNetWizard.stop_wizard()

    assert_receive ^key
  end

  @spec callback_tester(any()) :: any()
  def callback_tester(key) do
    # This is to be called from {m, f, a} callback and
    # sends the message back to this process for
    # assert_receive to verify it worked
    send(self(), key)
  end
end
