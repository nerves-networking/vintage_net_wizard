# JSON API

## Get Access Points

This request returns a list of known access points and their properties. Hidden
access points are not returned.

Path: `/api/v1/access_points`

Method: `GET`

Response: Array AccessPoint

Response Code: `200`

### Examples

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

## Get Configurations

Get the current known configurations.

The `password` field is write only, so it will always return as `null` even
if the password was provided.

Path: `/api/v1/configurations`

Method: `GET`

Request: Empty

Response: Array WiFiConfiguration

Response Code: 200

### Examples

#### Request

```json
[
  {
    "ssid": "Millennium Falcon",
    "key_mgmt": "wpa_psk",
    "password": null
  }
]
```

## Update configurations

Make a PUT request to this endpoint to set the list of WiFi access points for
the device. This list is temporary and is not applied when set. See
[Apply](#Apply) to apply the configuration.

Access points should be listed in the order that they should be tried on the
device.

Path: `/api/v1/configurations`

Method: `PUT`

Request: Array WiFiConfiguration

Response: Empty

Response Code: `204`

### Examples

#### Request

```json
[
  {
    "ssid": "Millennium Falcon",
    "key_mgmt": "wpa_psk",
    "password": "Chewbacca"
  }
]
```

## Apply

A POST to this endpoint applies the configuration and attempts to connect to the
configured WiFi networks. To perform any additional configuration, the device
will need to re-enter AP mode. This is done outside of this API.

Path: `/api/v1/apply`

Method: `POST`

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
