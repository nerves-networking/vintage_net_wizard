defmodule VintageNetWizard.Backend do
  @moduledoc """
  Backends define the boundaries of getting access points,
  handling incoming messages, and scanning the network
  """

  alias VintageNetWizard.WiFiConfiguration
  alias VintageNetWiFi.AccessPoint

  @type configuration_status :: :not_configured | :good | :bad

  @doc """
  Do any initialization work like subscribing to messages
  """
  @callback init() :: state :: any()

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
  Return information about the device for populating the web UI footer
  """
  @callback device_info() :: [{String.t(), String.t()}]

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
  @callback reset() :: state :: any()

  @doc """
  Perform final completion steps.
  """
  @callback complete([WiFiConfiguration.t()], state :: any()) :: {:ok, state :: any()}
end
