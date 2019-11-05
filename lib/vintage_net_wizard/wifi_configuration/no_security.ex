defmodule VintageNetWizard.WiFiConfiguration.NoSecurity do
  @moduledoc false
  @behaviour VintageNetWizard.WiFiConfiguration

  @type t :: %__MODULE__{
          ssid: String.t(),
          priority: non_neg_integer() | nil
        }

  defstruct ssid: nil, priority: nil

  @spec from_params(map()) :: {:ok, t()} | {:error, :invalid_ssid}
  @impl VintageNetWizard.WiFiConfiguration
  def from_params(%{"ssid" => nil}), do: {:error, :invalid_ssid}
  def from_params(%{"ssid" => ssid}), do: {:ok, %__MODULE__{ssid: ssid}}
  def from_params(_), do: {:error, :invalid_ssid}

  @impl VintageNetWizard.WiFiConfiguration
  @spec to_vintage_net_configuration(t()) :: map()
  def to_vintage_net_configuration(%__MODULE__{
        ssid: ssid,
        priority: priority
      }) do
    %{
      ssid: ssid,
      mode: :infrastructure,
      key_mgmt: :none
    }
    |> maybe_put_priority(priority)
  end

  defp maybe_put_priority(config, nil), do: config
  defp maybe_put_priority(config, priority), do: Map.put(config, :priority, priority)

  defimpl Jason.Encoder do
    def encode(%{ssid: ssid}, opts) do
      config = %{ssid: ssid, key_mgmt: :none}
      Jason.Encode.map(config, opts)
    end
  end
end
