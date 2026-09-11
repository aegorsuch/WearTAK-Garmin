# WearTAK-Garmin

WearTAK-Garmin is a standalone Garmin Connect IQ watch application for basic
Team Awareness Kit (TAK) operational awareness. It is designed for Garmin
watches with maps and GPS, currently targeting the fenix 7X.

The app connects to a dedicated HTTPS TAK bridge, publishes the watch's
position as Cursor-on-Target (CoT), and provides an on-watch map for viewing
position and saving manually placed points.

## Current capabilities

- Connects to a configured HTTPS TAK bridge using HTTP Basic auth.
- Defaults to dynamic GPS reporting: every 10 seconds while alerting, every
	60 seconds while moving, and every hour while stationary. Static tracking is
	also available and defaults to every 60 seconds.
- Uses a stable `garmin-<callsign>` CoT UID and the configured server name as
  the callsign; the username is used when no server name is set.
- Displays the watch's current position on a pan-and-zoom map.
- Drops and saves 2525D-style friendly, hostile, unknown, and obstacle points
  as Garmin waypoints.
- Publishes map points as typed CoT marker events after their type is selected.
- Provides a confirmed SOS action that sends an emergency CoT event and uses
	the configured alert reporting interval until the SOS control is selected
	again to clear alerting.
- Optionally polls a configured XML CoT feed and displays up to 50 received
	entities on the map.
- Retries failed TAK requests after 5, 15, and 60 seconds before reporting a
	connection failure.
- Supports opt-in heart-rate, respiration-rate, and step telemetry in a
	Garmin-specific CoT detail extension when the device makes those readings
	available.
- Stores TAK endpoint settings locally on the watch.

## Using the app

1. Open **TAK Server** from the main menu.
2. Set the server host, port, username, password, and an optional server name
	to use as the callsign.
3. Select **Tracking Mode** and configure reporting intervals in seconds as
	needed. Dynamic tracking is the default; a speed of at least 0.5 m/s is
	considered moving.
4. Select **Connect**. The app validates the server and starts PLI reporting.
5. Open **Map** to browse the map, center on the current position, and add
	local points.

Set **Incoming CoT path** only when the TAK deployment provides an HTTPS path
that returns CoT XML events. It is blank by default because no single incoming
REST endpoint is portable across TAK Server deployments. **Send SOS** opens a
separate confirmation before transmitting; selecting it again clears alerting.

**Health telemetry** is disabled by default. When enabled, position reports may
include `<_garmin heartRate="..." respirationRate="..." steps="..."/>` inside
the CoT `detail` element. This is a Garmin-specific extension, not a standard
TAK health schema; confirm that the receiving system accepts and handles it
before using it operationally.

The current CoT publisher posts a JSON envelope of the form
`{"cot":"<event ...>"}` to `https://<server>:<port>/Marti/api/cot`. The HTTPS
bridge must authenticate the watch, validate and unwrap the CoT XML, and relay
it to TAK using the bridge's mTLS certificate. A standard TAK Server mTLS data
port does not implement this endpoint.

## Platform limits

Connect IQ is not Wear OS. This application cannot use Android foreground
services, Compose, Tiles, MDM managed configuration, Android plugins, Samsung
Health APIs, or APK tooling. It also cannot connect to the native TAK mutual-
TLS streaming port or submit raw XML request bodies because Connect IQ provides
dictionary-based HTTPS web requests rather than arbitrary TLS sockets, client-
certificate installation, or raw HTTP body control.

Treat location, server credentials, and saved waypoints as sensitive data.
Use a trusted HTTPS TAK Server and verify its REST authentication policy before
field use.

## Implementation roadmap

1. **CoT PLI publishing** - implemented: send periodic `a-f-G-U-C` position
	events to the TAK Server REST API with dynamic or static scheduling.
2. **CoT marker publishing** - implemented: typed map points publish CoT
	marker events after type assignment.
3. **Incoming CoT awareness** - implemented for configurable XML REST feeds;
	validate the configured endpoint and payload against the target server.
4. **SOS/manual alert** - implemented: confirmed emergency event plus dynamic
	alert-rate reporting, subject to target TAK Server policy.
5. **Operational reliability** - implemented: bounded reconnect attempts and
	request-status feedback within Connect IQ lifecycle limits.
6. **Garmin sensors** - implemented as opt-in heart rate, respiration rate,
	and daily step telemetry in a documented Garmin-specific CoT extension.
	Environmental and other device-specific sensors remain unsupported until a
	compatible watch and stable CoT mapping are validated.

## Development

Build the project with the Garmin Connect IQ SDK for the configured product.
Use the simulator for UI and payload checks, then validate networking on a
physical watch against a dedicated test TAK Server. Do not commit generated
build output or the private `developer_key.der`; both are ignored by Git.
