# WearTAK-Garmin

WearTAK-Garmin is a standalone Garmin Connect IQ watch application for basic
Team Awareness Kit (TAK) operational awareness. It is designed for Garmin
watches with maps and GPS, currently targeting the fenix 7X.

The app uses Garmin Connect IQ phone messages to relay watch input to the
WearTAK ATAK companion. ATAK owns TAK server connectivity, mTLS credentials,
identity, and the authoritative phone location for PLI; the watch provides a
secondary display and input surface.

## Current capabilities

- Relays `pli`, `marker`, and `emergency` JSON envelopes to the ATAK phone
	companion through Garmin Connect IQ. No TAK endpoint or credentials are
	stored on the watch.
- Defaults to dynamic GPS reporting: every 10 seconds while alerting, every
	60 seconds while moving, and every hour while stationary. Static tracking is
	also available and defaults to every 60 seconds.
- Uses a locally configurable watch label as metadata for marker and emergency
	input; ATAK remains the source identity and position for PLI.
- Displays the watch's current position on a pan-and-zoom map.
- Drops and saves 2525D-style friendly, hostile, unknown, and obstacle points
  as Garmin waypoints.
- Publishes map points as typed CoT marker events after their type is selected.
- Provides a confirmed SOS action that sends an emergency CoT event and uses
	the configured alert reporting interval until the SOS control is selected
	again to clear alerting.
- Displays phone-relayed `entity` or `entities` messages on the map.
- Preserves opt-in heart-rate, respiration-rate, and step telemetry in outbound
	PLI payload metadata when the device makes those readings available.

## Using the app

1. Install and start the WearTAK ATAK plugin on the paired Android phone.
2. Open **Phone Companion** from the main menu and set an optional watch label.
3. Select **Tracking Mode** and configure reporting intervals in seconds as
	needed. Dynamic tracking is the default; a speed of at least 0.5 m/s is
	considered moving.
4. Select **Start relay**. The watch waits for Garmin Connect to acknowledge
	its relay handshake before it starts reporting and requests an initial map
	entity sync from the ATAK companion.
5. Open **Map** to browse the map, center on the current position, and add
	local points.

The ATAK companion may send incoming entities to the watch using `entity` or
`entities` envelopes. **Send SOS** opens a separate confirmation before
transmitting; selecting it again clears alerting.

**Health telemetry** is disabled by default. When enabled, heart rate,
respiration rate, and step values are included in the outbound PLI payload for
the ATAK companion to map into CoT according to its policy.

## Platform limits

Connect IQ is not Wear OS. This application cannot use Android foreground
services, Compose, Tiles, MDM managed configuration, Android plugins, Samsung
Health APIs, or APK tooling. It sends only dictionary messages through Garmin
Connect; all TAK network transport and mTLS remain on ATAK.

Treat location and saved waypoints as sensitive data. Configure ATAK's TAK
connection according to the deployment's operational policy.

## Implementation roadmap

1. **Phone relay** - implemented: dictionary envelopes sent through Garmin
	Connect IQ to the ATAK companion, with delivery-confirmed startup and an
	initial entity-sync request.
2. **Dynamic reporting** - implemented: watch input is scheduled at alert,
	moving, stationary, or static intervals.
3. **Map input and incoming entities** - implemented: typed map points and
	phone-relayed entities share the existing on-watch map.
4. **SOS/manual alert** - implemented: confirmed alert and cancel envelopes.
5. **Garmin sensors** - implemented as opt-in heart rate, respiration rate,
	and daily step metadata. Environmental and other device-specific sensors
	remain unsupported until a compatible watch and stable CoT mapping are
	validated.

## Development

Build the project with the Garmin Connect IQ SDK for the configured product.
Use the simulator for UI and payload checks, then validate relay behavior on a
physical watch with Garmin Connect and the ATAK plugin. Do not commit generated
build output or the private `developer_key.der`; both are ignored by Git.
