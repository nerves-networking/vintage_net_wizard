defmodule VintageNetWizard.WiFiConfiguration.Params do
  @moduledoc false

  alias VintageNetWiFi.WPA2

  @type param_error :: :invalid_ssid | :password_required | WPA2.invalid_passphrase_error()

  @doc """
  Get the ssid form the configuration params
  """
  @spec ssid_from_params(map()) :: {:ok, String.t()} | {:error, param_error()}
  def ssid_from_params(%{"ssid" => nil}), do: {:error, :invalid_ssid}
  def ssid_from_params(%{"ssid" => ssid}), do: {:ok, ssid}
  def ssid_from_params(_), do: {:error, :invalid_ssid}

  @doc """
  Get and validate the password from the configuration params

  You can pass a custom validator to this function that should return
  `:ok` if the password is valid, or `{:error, reason}` if the password
  is not valide with reason.

  By default this will use `VintageNetWiFi.WPA2.validate_passphrase/1`
  """
  @spec password_from_params(map(), (String.t() -> :ok | {:error, param_error() | any()})) ::
          {:ok, String.t()} | {:error, param_error()}
  def password_from_params(params, validate \\ &validate_password/1)

  def password_from_params(%{"password" => password}, validator) do
    case validator.(password) do
      :ok -> {:ok, password}
      error -> error
    end
  end

  def password_from_params(_, _), do: {:error, :password_required}

  @doc """
  The default function used to valid a password
  """
  @spec validate_password(String.t()) :: :ok | {:error, param_error()}
  def validate_password(nil), do: {:error, :password_required}
  def validate_password(password), do: WPA2.validate_passphrase(password)
end
