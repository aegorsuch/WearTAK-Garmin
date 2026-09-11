# WearTAK-Garmin

A standalone Connect IQ map app for the Garmin fenix 7X.

## Main menu

On launch the app shows a menu with two options:

- **Map** — the pan/zoom map screen described below.
- **TAK Server** — configure and connect to a TAK server.

## Map

- Pan with swipes.
- Zoom with the `+` and `-` controls.
- Tap the target control to drop a 2525D point at the current GPS location.
- Long press the map to drop a 2525D point at the pressed map location.
- Dropped points are saved as watch waypoints.
- Tap the back control (or the physical back button) to return to the main menu.

## TAK Server

From the main menu, select **TAK Server** to enter connection details:

- Server URL
- Server Name (used as your callsign)
- Username
- Password
- Port

Selecting **Connect** validates the credentials against the server over HTTPS
and, once connected, periodically reports the watch's GPS location to the
server. Selecting **Disconnect** stops location reporting.

> **Certificate enrollment limitation:** ATAK/WinTAK normally connect to a TAK
> server using mutual-TLS with a client certificate obtained through a
> certificate enrollment flow. The Connect IQ Communications API used by
> watch apps has no way to install or use a client TLS certificate, so this
> app cannot perform that enrollment. Instead it authenticates with the
> server over HTTPS using the entered username/password (HTTP Basic auth),
> which most TAK servers also accept for REST access. Confirm your TAK
> server is configured to allow username/password authentication if you rely
> on this app.
