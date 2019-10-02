defmodule VintageNetWizard.WiFiConfiguration do
  @moduledoc """
  A WiFiConfiguration is used for clients to define
  the settings for a WiFi access point.
  """

  alias VintageNet.WiFi.WPA2

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
  Validate the password for the WiFiConfiguration
  """
  @spec validate_password(t()) ::
          :ok
          | {:error, WPA2.invalid_passphrase_error()}
          | {:error, :password_required, key_mgmt()}
  def validate_password(%__MODULE__{password: password, key_mgmt: key_mgmt}) do
    case do_validate_password(password, key_mgmt) do
      {:ok, _} -> :ok
      error -> error
    end
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
  @spec from_map(map()) ::
          {:ok, t()}
          | {:error, param_error(), value :: any()}
          | {:error, :password_required, key_mgmt()}
          | {:error, WPA2.invalid_passphrase_error()}
  def from_map(params) do
    with {:ok, ssid} <- ssid_from_params(params),
         {:ok, key_mgmt} <- key_mgmt_from_params(params),
         {:ok, password} <- get_and_validate_password_from_params(params) do
      {:ok, new(ssid, key_mgmt: key_mgmt, password: password)}
    else
      error -> error
    end
  end

  @doc """
  Take a `WiFiConfiguration.t()` and turn into a map that
  is used to configure `VintageNet`
  """
  @spec to_vintage_net_configuration(t()) ::
          map()
          | {:error, WPA2.invalid_passphrase_error()}
          | {:error, :password_required, key_mgmt()}
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
    |> maybe_put_priority(priority)
    |> try_put_psk(psk)
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

  defp try_put_psk(vn_config, psk) do
    security = Map.get(vn_config, :key_mgmt)

    case do_validate_password(psk, security) do
      {:ok, nil} ->
        vn_config

      {:ok, _} ->
        Map.put(vn_config, :psk, psk)

      error ->
        error
    end
  end

  defp get_and_validate_password_from_params(%{"password" => password} = params) do
    security = key_mgmt_from_params(params)
    do_validate_password(password, security)
  end

  defp get_and_validate_password_from_params(params) do
    case key_mgmt_from_params(params) do
      {:ok, :none} -> {:ok, nil}
      {:ok, security} -> {:error, :password_required, security}
    end
  end

  defp do_validate_password(password, :none) do
    {:ok, password}
  end

  defp do_validate_password(nil, security) do
    {:error, :password_required, security}
  end

  defp do_validate_password(password, _security) do
    case WPA2.validate_passphrase(password) do
      :ok -> {:ok, password}
      error -> error
    end
  end

  defimpl Jason.Encoder do
    alias VintageNetWizard.WiFiConfiguration

    def encode(%WiFiConfiguration{ssid: ssid, key_mgmt: key_mgmt}, opts) do
      config = %{ssid: ssid, key_mgmt: key_mgmt}
      Jason.Encode.map(config, opts)
    end
  end
end
