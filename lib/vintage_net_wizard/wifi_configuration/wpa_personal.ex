defmodule VintageNetWizard.WiFiConfiguration.WPAPersonal do
  @moduledoc false

  @behaviour VintageNetWizard.WiFiConfiguration

  alias VintageNetWizard.WiFiConfiguration.Params

  @type t :: %__MODULE__{
          ssid: String.t(),
          psk: String.t(),
          priority: non_neg_integer() | nil
        }

  defstruct ssid: nil, psk: nil, priority: nil

  @impl VintageNetWizard.WiFiConfiguration
  @spec from_params(map()) :: {:ok, t()} | {:error, Params.param_error()}
  def from_params(params) do
    with {:ok, ssid} <- Params.ssid_from_params(params),
         {:ok, psk} <- Params.password_from_params(params) do
      {:ok, %__MODULE__{ssid: ssid, psk: psk}}
    else
      error -> error
    end
  end

  @impl VintageNetWizard.WiFiConfiguration
  @spec to_vintage_net_configuration(t()) :: map()
  def to_vintage_net_configuration(%__MODULE__{
        ssid: ssid,
        psk: psk,
        priority: priority
      }) do
    %{
      ssid: ssid,
      mode: :client,
      key_mgmt: :wpa_psk,
      psk: psk
    }
    |> maybe_put_priority(priority)
  end

  defp maybe_put_priority(config, nil), do: config
  defp maybe_put_priority(config, priority), do: Map.put(config, :priority, priority)

  defimpl Jason.Encoder do
    def encode(%{ssid: ssid}, opts) do
      config = %{ssid: ssid, key_mgmt: :wpa_psk}
      Jason.Encode.map(config, opts)
    end
  end
end
