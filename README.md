# Telecursor

Teleport your cursor between screens with a keypress. No dragging, no edge-bumping — just instant jumps.

## What it does

Press **F3** and your cursor warps to the next monitor. Press **Shift+F3** to go back. Telecursor remembers where your cursor was on each screen and puts it back there when you return.

Screens are cycled left-to-right based on your display arrangement.

## Install

```bash
git clone git@github.com:yarinzirlin/Telecursor.git
cd Telecursor
./build.sh
open Telecursor.app
```

Grant **Accessibility** access when prompted (System Settings > Privacy & Security > Accessibility).

## Usage

| Action | Default Hotkey |
|---|---|
| Next screen | `F3` |
| Previous screen | `Shift+F3` |

Both hotkeys are configurable — click the menu bar icon > **Settings** and press any key combo to rebind.

## Features

- Menu bar app — no dock icon, no clutter
- Remembers last cursor position per screen
- Press-to-record hotkey configuration
- Starts at login via LaunchAgent

## Start at login

```bash
cp com.telecursor.app.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.telecursor.app.plist
```

## Build requirements

- macOS 14+
- Command Line Tools for Xcode (`xcode-select --install`)

## License

MIT
