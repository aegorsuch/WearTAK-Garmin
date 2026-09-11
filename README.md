# WearTAK-Garmin

WearTAK-Garmin is a standalone Garmin Connect IQ watch application for basic
Team Awareness Kit (TAK) operational awareness. It is designed for Garmin
watches with maps and GPS, currently targeting the fenix 7X.

The app connects to a TAK Server REST endpoint over HTTPS, publishes the
watch's position as Cursor-on-Target (CoT), and provides an on-watch map for
viewing position and saving manually placed points.

## Current capabilities

- Connects to a configured TAK Server HTTPS endpoint using HTTP Basic auth.
- Publishes GPS position as a CoT PLI event every 15 seconds while connected.
- Uses a stable `garmin-<callsign>` CoT UID and the configured server name as
  the callsign; the username is used when no server name is set.
- Displays the watch's current position on a pan-and-zoom map.
- Drops and saves 2525D-style friendly, hostile, unknown, and obstacle points
  as Garmin waypoints.
- Stores TAK endpoint settings locally on the watch.

## Using the app

1. Open **TAK Server** from the main menu.
2. Set the server host, port, username, password, and an optional server name
	to use as the callsign.
3. Select **Connect**. The app validates the server and starts PLI reporting.
4. Open **Map** to browse the map, center on the current position, and add
	local points.

The current CoT publisher posts XML events to
`https://<server>:<port>/Marti/api/cot`. The target TAK Server must expose this
REST endpoint and permit the configured HTTP Basic credentials.

## Platform limits

Connect IQ is not Wear OS. This application cannot use Android foreground
services, Compose, Tiles, MDM managed configuration, Android plugins, Samsung
Health APIs, or APK tooling. It also cannot connect to the native TAK mutual-
TLS streaming port because Connect IQ provides HTTPS web requests rather than
arbitrary TLS sockets or client-certificate installation.

Treat location, server credentials, and saved waypoints as sensitive data.
Use a trusted HTTPS TAK Server and verify its REST authentication policy before
field use.

## Implementation roadmap

1. **CoT PLI publishing** - implemented: send a periodic `a-f-G-U-C` position
	event to the TAK Server REST API.
2. **CoT marker publishing** - publish points created on the map as CoT marker
	events after the operator assigns their type.
3. **Incoming CoT awareness** - retrieve supported REST CoT feeds and render
	received entities with type-specific map icons.
4. **SOS/manual alert** - add a deliberate, confirmed emergency action that
	transmits an emergency CoT event and shows delivery state.
5. **Operational reliability** - make reporting interval configurable, surface
	request failures, and define reconnect behavior within Connect IQ lifecycle
	limits.
6. **Garmin sensors** - evaluate supported heart-rate, activity, and
	environmental data APIs, then publish only data with a defined CoT mapping.

## Development

Build the project with the Garmin Connect IQ SDK for the configured product.
Use the simulator for UI and payload checks, then validate networking on a
physical watch against a dedicated test TAK Server. Do not commit generated
build output or the private `developer_key.der`; both are ignored by Git.
