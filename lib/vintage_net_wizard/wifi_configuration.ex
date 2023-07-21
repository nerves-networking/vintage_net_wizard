defmodule VintageNetWizard.WiFiConfiguration do
  @moduledoc """
  Module for working with various WiFi configurations
  """

  alias VintageNetWizard.WiFiConfiguration.Params

  @type key_mgmt() :: :none | :wpa_psk | :wpa_eap

  @doc """
  Make a network config from a JSON request from the `VintageNetWizard` client
  """
  @spec json_to_network_config(map()) :: {:ok, map()} | {:error, Params.param_error()}
  def json_to_network_config(%{"key_mgmt" => "none"} = params) do
    case Params.ssid_from_params(params) do
      {:ok, ssid} ->
        {:ok,
         %{
           ssid: ssid,
           key_mgmt: :none,
           mode: :infrastructure
         }}

      error ->
        error
    end
  end

  def json_to_network_config(%{"key_mgmt" => "wpa_psk"} = params) do
    with {:ok, password} <- Params.password_from_params(params),
         {:ok, ssid} <- Params.ssid_from_params(params),
         :ok <- Params.validate_password(password) do
      {:ok,
       %{
         ssid: ssid,
         mode: :infrastructure,
         key_mgmt: :wpa_psk,
         psk: password
       }}
    else
      error -> error
    end
  end

  def json_to_network_config(%{"key_mgmt" => "wpa_eap"} = params) do
    with {:ok, ssid} <- Params.ssid_from_params(params),
         {:ok, password} <- Params.password_from_params(params),
         {:ok, user} <- Params.user_from_params(params),
         :ok <- Params.validate_peap_password(password) do
      {:ok,
       %{
         mode: :infrastructure,
         key_mgmt: :wpa_eap,
         eap: "PEAP",
         phase2: "auth=MSCHAPV2",
         ssid: ssid,
         identity: user,
         password: password
       }}
    else
      error -> error
    end
  end

  @doc """
  Get the expected timeout in milisecs for a particular configuration
  """
  @spec timeout(%{key_mgmt: key_mgmt()}) :: 30_000 | 75_000
  def timeout(%{key_mgmt: :none}), do: 30_000
  def timeout(%{key_mgmt: :wpa_psk}), do: 30_000
  def timeout(%{key_mgmt: :wpa_eap}), do: 75_000

  @doc """
  Get the `key_mgmt` type from the particular WiFi Configuration
  """
  @spec get_key_mgmt(map()) :: key_mgmt()
  def get_key_mgmt(%{key_mgmt: key_mgmt}), do: key_mgmt

  @doc """
  Convert a key_mgmt string into a key_mgmt
  """
  @spec key_mgmt_from_string(String.t()) :: {:ok, key_mgmt()} | {:error, :invalid_key_mgmt}
  def key_mgmt_from_string("wpa_eap"), do: {:ok, :wpa_eap}
  def key_mgmt_from_string("wpa_psk"), do: {:ok, :wpa_psk}
  def key_mgmt_from_string("none"), do: {:ok, :none}
  def key_mgmt_from_string(_), do: {:error, :invalid_key_mgmt}

  @doc """
  Get a human friendly name for the type of security of a WiFiConfiguration
  """
  @spec security_name(%{key_mgmt: key_mgmt()}) :: String.t()
  def security_name(%{key_mgmt: :wpa_psk}), do: "WPA Personal"
  def security_name(%{key_mgmt: :wpa_eap}), do: "WPA Enterprise"
  def security_name(%{key_mgmt: :none}), do: "None"
end
