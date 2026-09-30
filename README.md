# Telesm: Location Spoofer

A tiny native macOS app that puts a connected iPhone's GPS somewhere else, with one button per place.

**طلسم** — a talisman. Something you hold to be somewhere you are not.

## Why I made it

Faking the iPhone's location from the Mac means typing a `pymobiledevice3` command with the right coordinates, the right device UDID, and a tunnel flag, every single time. I wanted two or three places I go back to, each behind a button.

So this is a small SwiftUI window: plug the iPhone in, hit **New York City**, **London**, or **St Antony's College**, and the phone's location services follow. **Real GPS (stop faking)** clears it.

## What it does

- Detects attached devices over USB, and says so plainly when there is none.
- Sets the simulated location through `pymobiledevice3 developer dvt simulate-location set`.
- Uses `--userspace`, which builds the iOS 17+ RemoteServiceDiscovery tunnel in-process in pure Python — so the app needs **no root and no admin prompt**.
- Shows the last line of the tool's output when something fails, rather than a generic error.
- Kills the child process on a timeout, so a half-attached phone cannot hang the window.

## Requirements

- macOS 14 or later
- An iPhone on iOS 17+, connected by USB, unlocked, and trusted
- [`pymobiledevice3`](https://github.com/doronz88/pymobiledevice3), installed with `pipx install pymobiledevice3`

The app looks for the binary at `~/.local/bin`, then `/opt/homebrew/bin`, then `/usr/local/bin`.

## Build

```bash
./scripts/build_app.sh
```

Produces `dist/Telesm.app`. It is ad-hoc signed, so the first launch may need a right-click → Open.

The icon is drawn in code — an aged brass amulet on ink — by `scripts/DrawIcon.swift`, assembled into `Resources/AppIcon.icns` by `scripts/make_icon.sh`. Change a colour there and rebuild rather than shipping a binary asset nobody can edit.

## Adding a place

Add a `Spot` in [`Sources/Telesm/Phone.swift`](Sources/Telesm/Phone.swift) and list it in [`ContentView.swift`](Sources/Telesm/ContentView.swift).

## Notes

The location is simulated at the developer-service level, so it disappears when the phone reboots or the cable is pulled. It is intended for testing your own device — apps that check for simulated location will notice.
