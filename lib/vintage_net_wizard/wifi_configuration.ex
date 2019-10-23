defmodule VintageNetWizard.WiFiConfiguration do
  @moduledoc """
  Module for working with various WiFi configurations
  """

  @opaque t ::
            VintageNetWizard.WiFiConfiguration.WPAPersonal.t()
            | VintageNetWizard.WiFiConfiguration.NoSecurity.t()

  @type key_mgmt() :: :none | :wpa_psk

  alias VintageNetWizard.WiFiConfiguration.{
    Params,
    WPAPersonal,
    NoSecurity
  }

  @doc """
  A function on how to transform the map of params into a WiFiConfiguration
  """
  @callback from_params(map()) :: {:ok, t()} | {:error, Params.param_error()}

  @doc """
  A function on how to take a WiFiConfiguration and make it into
  a useable `vintage_net` WiFi configuration. 
  """
  @callback to_vintage_net_configuration(t()) :: map()

  @doc """
  Marshal a parameter map into a type of WiFi Configuration
  """
  @spec from_params(map()) :: {:ok, t()} | {:error, Params.param_error()}
  def from_params(%{"key_mgmt" => "wpa_psk"} = params) do
    WPAPersonal.from_params(params)
  end

  def from_params(%{"key_mgmt" => "none"} = params) do
    NoSecurity.from_params(params)
  end

  @doc """
  Take a particular type of WiFi configuration and make into a configuration
  that `vintage_net` can use
  """
  @spec to_vintage_net_configuration(struct()) :: map()
  def to_vintage_net_configuration(config) do
    module = config.__struct__
    module.to_vintage_net_configuration(config)
  end

  @doc """
  Get the `key_mgmt` type from the particular WiFi Configuration
  """
  @spec get_key_mgmt(t()) :: key_mgmt()
  def get_key_mgmt(%WPAPersonal{}), do: :wpa_psk
  def get_key_mgmt(%NoSecurity{}), do: :none
end
