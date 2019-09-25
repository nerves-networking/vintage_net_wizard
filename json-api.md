# JSON API

## Endpoints

* [Get Access Points](#get-access-points)
* [Configure SSID Priority](#configure-ssid-priority)
* [Configure an SSID](#configure-an-ssid)
* [Delete an SSID configuration](#delete-an-ssid-configuration)
* [Get Configurations](#get-configurations)
* [Get Configuration Status](#get-configuration-status)
* [Apply](#apply)
* [Complete the Configuration Process](#complete-the-configuration-process)

### Get Access Points

This request returns a list of known access points and their properties. Hidden
access points are not returned.

Path: `/api/v1/access_points`

Method: `GET`

Response: Array AccessPoint

Response Code: `200`

#### Response

```json
[
  {
    "ssid": "Free WiFi!",
    "frequency": 2437,
    "band": "wifi_2_4_ghz",
    "channel": 6,
    "flags": ["ess"],
    "signal_percent": 100,

  },
  {
    "ssid": "Imperial Star Destroyer",
    "frequency": 5755,
    "band": "wifi_5_ghz",
    "channel": 151,
    "flags": ["wpa2_psk_ccmp", "ess"],
    "signal_percent": 75
  }
]
```

### Configure SSID Priority

This endpoint takes a list of SSIDs. Each SSID is tried in order until a
successful connection is made. It is not required to list all configured SSIDs.

Path: `/api/v1/ssids`

Method: `PUT`

Request: `Array String`

Response: Empty

Response Code: `204`

### Example

#### Request

```json
[
  "Millennium Falcon",
  "Death Star",
  "TIE-fighter-01",
  "lukes-lightsaber"
]
```

### Configure an SSID

Set connection parameters for an `SSID`.

Path: `/api/v1/<ssid>/configuration`

Method: `PUT`

Request: `WiFiConfiguration`

Response: Empty

Response Code: `204`

### Example

#### Request

`/api/v1/millennium-falcon/configuration`

```json
{
  "key_mgmt": "wpa_psk",
  "password": "Chewbacca"
}
```

### Delete an SSID configuration

Delete the configuration attached to an SSID

Path: `/api/v1/<ssid>/configuration`

Method: `DELETE`

Request: Empty

Response: Empty

Response Code: `200`

### Get Configurations

Get the current known configurations.

Path: `/api/v1/configurations`

Method: `GET`

Request: Empty

Response: `Array WiFiConfiguration` - Passwords are filtered

Response Code: 200

#### Request

```json
[
  {
    "ssid": "Millennium Falcon",
    "key_mgmt": "wpa_psk"
  }
]
```

### Get Configuration Status

Get the current status of the configuration. This is useful after using
the `/api/v1/apply` endpoint to figure out if the configurations that
were provided work or not.

Path: `/api/v1/configuration/status`

Method: `GET`

Request: Empty

Response: `ConfigurationStatus`

Response Code: 200

### Apply

A POST to this endpoint applies the configuration and attempts to connect to the
configured WiFi networks. This will return back to AP mode and you can use the
`/api/v1/configuration/status` endpoint to get weather or not the configuration
worked or not.

Path: `/api/v1/apply`

Method: `POST`

Request: Empty

Response: Empty

Response Code: `202`

### Complete the Configuration Process

Finalize the configuration process. This will apply the configuration and
not return to AP mode.

Path: `/api/v1/complete`

Method: `GET`

Request: Empty

Response: Empty

Response Code: `202`

## Types

### AccessPoint

```s
{
  "ssid": String,
  "signal_percent": 0..100,
  "frequency": Integer,
  "band": Band,
  "channel": Integer,
  "flags": Flags
}
```

### Band

This is the WiFi radio band that the access point is using.

```s
"wifi_2_4_ghz"
"wifi_5_ghz"
"unknown"
```

### Flags

Flags are reported by access points. They can be used to know whether a password
is required to join the network. For example, a password is required for access
points with `"wpa2_psk_*"`.

```s
"wpa2_psk_ccmp" - WPA2 security with a pre-shared key is supported
"wpa2_eap_ccmp" - WPA2 security with enterprise security is supported
"wpa2_psk_ccmp_tkip" - WPA2 security with a pre-shared key is supported
"wpa_psk_ccmp_tkip" - WPA security with a pre-shared key is supported
"ibss" - A long legged wading bird
"mesh" - Mesh network supported
"ess" - Extended service set network
"p2p" - This is a peer-to-peer WiFi connection
"wps" - WiFi Protected Setup supported
"rsn_ccmp" - Robust secure network
```

### KeyManagement

Key management tells the device what kind of WiFi security method it should use
when connecting to an access point. Sometimes this can be determined from the
`Flags`. To connect to a hidden access point, the user will need to say whether
a password is needed.

```s
"none" - No security
"wpa_psk" - WPA or WPA2 with a pre-shared key
```

### WiFiConfiguration

This specifies how to connect to one WiFi access point. The `ssid` and
`key_mgmt` fields are required. Depending on the `key_mgmt`, `password` may be
needed.

```s
{
  "ssid": String,
  "key_mgmt": KeyManagement,
  "password": Optional String
}
```

### ConfigurationStatus

```s
not_configured - No configuration attempts have taken place
good - A configuration was applied and is working
bad - A configuration was applied and is not working
```
