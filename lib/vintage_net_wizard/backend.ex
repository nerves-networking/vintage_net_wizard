defmodule VintageNetWizard.Backend do
  @moduledoc """
  Backends define the boundaries of getting access points, handling incoming
  messages, and scanning the network
  """

  alias VintageNetWizard.WiFiConfiguration
  alias VintageNetWiFi.AccessPoint

  @type device_info_name() :: String.t()

  @type device_info_value() :: String.t()

  @type opt() :: {:device_info, [{device_info_name(), device_info_value()}]}

  @type configuration_status() :: :not_configured | :good | :bad

  @doc """
  Do any initialization work like subscribing to messages

  Will be passed the interface name that the backend should use. By default
  this will be `"wlan0"`. If you want to use a different interface name you
  can pass that in an option to `VintageNetWizard.run_wizard/1`.
  """
  @callback init(VintageNet.ifname()) :: state :: any()

  @doc """
  Get all the access points that the backend knowns about
  """
  @callback access_points(state :: any()) :: [AccessPoint.t()]

  @doc """
  Apply the WiFi configurations
  """
  @callback apply([WiFiConfiguration.t()], state :: any()) ::
              {:ok, state :: any()} | {:error, :invalid_state}

  @doc """
  Handle any message the is received by another process

  If you want the socket to send data to the client
  return `{:reply, message, state}`, otherwise return
  `{:noreply, state}`
  """
  @callback handle_info(any(), state :: any()) ::
              {:reply, any(), state :: any()} | {:noreply, state :: any()}

  @doc """
  Return the configuration status of a configuration that has been applied
  """
  @callback configuration_status(state :: any()) :: configuration_status()

  @doc """
  Start scanning for WiFi access points
  """
  @callback start_scan(state :: any()) :: state :: any()

  @doc """
  Stop the scan for WiFi access points
  """
  @callback stop_scan(state :: any()) :: state :: any()

  @doc """
  Apply any actions required to set the backend back to an
  initial default state
  """
  @callback reset(state :: any()) :: state :: any()

  @doc """
  Perform final completion steps.
  """
  @callback complete([WiFiConfiguration.t()], state :: any()) :: {:ok, state :: any()}
end
