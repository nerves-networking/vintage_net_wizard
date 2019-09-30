defmodule VintageNetWizard.WiFiConfiguration do
  @moduledoc """
  A WiFiConfiguration is used for clients to define
  the settings for a WiFi access point.
  """
  @type key_mgmt :: :none | :wpa_psk

  @type t :: %__MODULE__{
          ssid: String.t(),
          key_mgmt: key_mgmt(),
          password: String.t() | nil,
          priority: non_neg_integer() | nil
        }

  @type opt :: {:key_mgmt, atom()} | {:password, binary()} | {:priority, non_neg_integer()}

  @type param_error :: :invalid_key_mgmt | :invalid_ssid

  @type decode_error ::
          {:error, :json_decode, Jason.DecodeError.t()} | {:error, param_error(), value :: any()}

  @enforce_keys [:ssid]
  defstruct ssid: "", key_mgmt: :none, password: nil, priority: nil

  @doc """
  Make a new WiFiConfiguration struct
  """
  @spec new(binary(), [opt()]) :: t()
  def new(ssid, opts) do
    opts = Keyword.merge(opts, ssid: ssid)

    struct(__MODULE__, opts)
  end

  @doc """
  Decode JSON string into WiFiConfiguration
  """
  @spec decode(binary()) :: {:ok, t()} | decode_error()
  def decode(json) do
    case Jason.decode(json) do
      {:ok, params} ->
        from_map(params)

      {:error, decode_error} ->
        {:error, :json_decode, decode_error}
    end
  end

  @doc """
  Try to make a WiFiConfiguration from a map.

  Required fields:

    - "ssid" - The SSID of the access point
    - "key_mgmt" - The key management to use

  Options fields:

    - "password" - The password for the access point
  """
  @spec from_map(map()) :: {:ok, t()} | {:error, param_error(), value :: any()}
  def from_map(params) do
    with {:ok, ssid} <- ssid_from_params(params),
         {:ok, key_mgmt} <- key_mgmt_from_params(params),
         password <- params["password"] do
      {:ok, new(ssid, key_mgmt: key_mgmt, password: password)}
    else
      error -> error
    end
  end

  @doc """
  Take a `WiFiConfiguration.t()` and turn into a map that
  is used to configure `VintageNet`
  """
  @spec to_vintage_net_configuration(t()) :: map()
  def to_vintage_net_configuration(%__MODULE__{
        ssid: ssid,
        password: psk,
        key_mgmt: key_mgmt,
        priority: priority
      }) do
    %{
      ssid: ssid,
      mode: :client,
      key_mgmt: key_mgmt
    }
    |> maybe_put_psk(psk)
    |> maybe_put_priority(priority)
  end

  defp key_mgmt_from_params(%{"key_mgmt" => ""}), do: {:ok, :none}
  defp key_mgmt_from_params(%{"key_mgmt" => key_mgmt}), do: key_mgmt_from_string(key_mgmt)

  defp key_mgmt_from_string("none"), do: {:ok, :none}
  defp key_mgmt_from_string("wpa_psk"), do: {:ok, :wpa_psk}
  defp key_mgmt_from_string(key_mgmt), do: {:error, :invalid_key_mgmt, key_mgmt}

  defp ssid_from_params(%{"ssid" => nil}), do: {:error, :invalid_ssid, nil}
  defp ssid_from_params(%{"ssid" => ssid}), do: {:ok, ssid}

  defp maybe_put_priority(vn_config, nil), do: vn_config
  defp maybe_put_priority(vn_config, priority), do: Map.put(vn_config, :priority, priority)

  defp maybe_put_psk(vn_config, nil), do: vn_config
  defp maybe_put_psk(vn_config, psk), do: Map.put(vn_config, :psk, psk)

  defimpl Jason.Encoder do
    alias VintageNetWizard.WiFiConfiguration

    def encode(%WiFiConfiguration{ssid: ssid, key_mgmt: key_mgmt}, opts) do
      config = %{ssid: ssid, key_mgmt: key_mgmt}
      Jason.Encode.map(config, opts)
    end
  end
end
