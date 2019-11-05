defmodule VintageNetWizard.WiFiConfiguration.PEAPEnterprise do
  @moduledoc false

  @behaviour VintageNetWizard.WiFiConfiguration

  alias VintageNetWizard.WiFiConfiguration.Params

  @type t :: %__MODULE__{
          ssid: String.t(),
          user: String.t(),
          password: String.t(),
          priority: non_neg_integer()
        }

  defstruct ssid: nil, user: nil, password: nil, priority: nil

  @impl VintageNetWizard.WiFiConfiguration
  @spec to_vintage_net_configuration(t()) :: map()
  def to_vintage_net_configuration(%__MODULE__{
        ssid: ssid,
        user: user,
        password: password,
        priority: priority
      }) do
    %{
      mode: :infrastructure,
      key_mgmt: :wpa_eap,
      eap: "PEAP",
      phase2: "auth=MSCHAPV2",
      ssid: ssid,
      identity: user,
      password: password
    }
    |> maybe_put_priority(priority)
  end

  @impl VintageNetWizard.WiFiConfiguration
  @spec from_params(map()) :: {:ok, t()} | {:error, Params.param_error()}
  def from_params(params) do
    with {:ok, ssid} <- Params.ssid_from_params(params),
         {:ok, password} <- Params.password_from_params(params, &validate_password/1),
         {:ok, user} <- user_from_params(params) do
      {:ok, %__MODULE__{ssid: ssid, password: password, user: user}}
    else
      error -> error
    end
  end

  defp user_from_params(%{"user" => nil}), do: {:error, :user_required}
  defp user_from_params(%{"user" => ssid}), do: {:ok, ssid}
  defp user_from_params(_), do: {:error, :user_required}

  defp maybe_put_priority(config, nil), do: config
  defp maybe_put_priority(config, priority), do: Map.put(config, :priority, priority)

  defp validate_password(nil), do: {:error, :password_required}
  defp validate_password(""), do: {:error, :password_required}
  defp validate_password(_pw), do: :ok

  defimpl Jason.Encoder do
    def encode(%{ssid: ssid}, opts) do
      config = %{ssid: ssid, key_mgmt: :wpa_eap}
      Jason.Encode.map(config, opts)
    end
  end
end
