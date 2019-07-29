defmodule VintageNetWizard.WiFiConfiguration do
  @moduledoc """
  A WiFiConfiguration is used for clients to define
  the settings for a WiFi access point.
  """
  @type key_mgmt :: :none | :wpa_psk

  @type t :: %__MODULE__{
          ssid: String.t(),
          key_mgmt: key_mgmt(),
          password: String.t() | nil
        }

  @type opt :: {:key_mgmt, atom()} | {:password, binary()}

  @type param_error :: :invalid_key_mgmt | :invalid_ssid

  @type decode_error ::
          {:error, :json_deocde, Jason.DecodeError.t()} | {:error, param_error(), value :: any()}

  @enforce_keys [:ssid]
  defstruct ssid: "", key_mgmt: :none, password: nil

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

    - "password" - The passowrd for the access point
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

  defp key_mgmt_from_params(%{"key_mgmt" => nil}), do: {:eror, :invalid_key_mgmt, nil}
  defp key_mgmt_from_params(%{"key_mgmt" => key_mgmt}), do: key_mgmt_from_string(key_mgmt)

  defp key_mgmt_from_string("none"), do: {:ok, :none}
  defp key_mgmt_from_string("wpa_psk"), do: {:ok, :wpa_psk}
  defp key_mgmt_from_string(key_mgmt), do: {:error, :invalid_key_mgmt, key_mgmt}

  defp ssid_from_params(%{"ssid" => nil}), do: {:error, :invalid_ssid, nil}
  defp ssid_from_params(%{"ssid" => ssid}), do: {:ok, ssid}

  defimpl Jason.Encoder do
    alias VintageNetWizard.WiFiConfiguration

    def encode(%WiFiConfiguration{ssid: ssid, key_mgmt: key_mgmt}, opts) do
      config = %{ssid: ssid, key_mgmt: key_mgmt, password: nil}
      Jason.Encode.map(config, opts)
    end
  end
end
