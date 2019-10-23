defmodule VintageNetWizard.WiFiConfiguration.ParamsTest do
  use ExUnit.Case, async: true

  alias VintageNetWizard.WiFiConfiguration.Params

  test "won't like params have no ssid" do
    assert {:error, :invalid_ssid} == Params.ssid_from_params(%{})
    assert {:error, :invalid_ssid} == Params.ssid_from_params(%{"ssid" => nil})
  end

  test "gets the ssid from the params" do
    params = %{"ssid" => "Hello"}
    assert {:ok, params["ssid"]} == Params.ssid_from_params(params)
  end

  test "gets and validates a password from params" do
    params = %{"password" => "123123123"}

    assert {:ok, params["password"]} == Params.password_from_params(params)
  end

  test "gets a validates a password from params with custom validator" do
    params = %{"password" => "hello"}
    params_bad = %{"password" => "123"}

    assert {:ok, params["password"]} == Params.password_from_params(params, &custom_validator/1)

    assert {:error, :password_needs_to_be_hello} ==
             Params.password_from_params(params_bad, &custom_validator/1)
  end

  defp custom_validator("hello"), do: :ok
  defp custom_validator(_), do: {:error, :password_needs_to_be_hello}
end
