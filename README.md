# kuori

A desktop shell for Hyprland, written in [Quickshell](https://quickshell.org) and QML. *Kuori* is
Finnish for shell, husk, envelope.

It draws a border around the whole desktop with tabs — "notches" — hanging off the top edge, and
provides an application launcher, a notification daemon, and an authentication agent. It is built
from a Claude Design mockup, and `CLAUDE.md` records every place the implementation departs from it
and why.

## What it does

- **A frame** around the desktop, with the rounded opening your windows live in.
- **Three notches** on the top edge: workspaces (left), clock and calendar (centre), system (right).
- **A launcher** with six categories — applications, clipboard history, wallpapers, windows, power —
  each openable straight from a keybind.
- **Notifications**: kuori *is* the session's notification daemon. Toasts appear top-right, and the
  history lives in the system panel.
- **An authentication agent**: kuori answers polkit, so privileged actions raise its own dialog.
- **A focus indicator** on the active window, either a corner wedge or a strip along one edge.

## Requirements

kuori talks to a number of things and degrades quietly when they are missing, so this list is worth
scanning if something looks dead.

| Needed for | What |
|---|---|
| Everything | `quickshell`, Hyprland, a running Wayland session |
| Launching applications | `uwsm` |
| Wi-Fi details (band, IPv4) | `nmcli` (NetworkManager) |
| Latency reading | `ping` |
| The backlight | `acpilight`, and your user in the `video` group |
| Naming the backlight device | `brightnessctl` |
| Wallpapers | `awww`, and images in `~/Pictures/wallpapers` |
| webp/tiff/jp2 thumbnails | `qt6.qtimageformats` |
| Clipboard history | `cliphist` and `wl-clipboard` |
| Screenshots | `grim`, `slurp`, `grimblast` |
| Screen recording | `wf-recorder` |
| Knowing where captures go | `xdg-user-dirs` |
| Night light | `hyprsunset` |
| Focusing a window, colour temperature | `hyprctl` |
| Icons in the launcher | any installed icon theme (Adwaita, MoreWaita) |
| Text | `JetBrainsMono Nerd Font` and `Manrope` |

Everything the shell shells out to must be on the **systemd unit's** PATH, which is not your login
shell's. See *Running it*.

### Companion services

These run as systemd **user** units alongside kuori. Without them the corresponding feature is inert
rather than broken.

| Unit | Why |
|---|---|
| `awww-daemon` | Displays the wallpaper. Its `ExecStartPost` runs `awww restore`, which is what puts your wallpaper back at login. |
| `cliphist-text`, `cliphist-image` | Record the clipboard. `cliphist` is a store, not a daemon — without these there is no history at all. The text one skips anything a password manager marked. |
| `hyprsunset` | Runs with `-i` (identity: present, changing nothing) so the night light has something to talk to. |
| `xdg-user-dirs-update` | Writes `~/.config/user-dirs.dirs` from `/etc/xdg/user-dirs.defaults`, which is how anything — kuori, grimblast, your file manager — knows where Pictures and Videos are. Oneshot at login. |

## Running it

kuori runs as a systemd user unit:

```sh
systemctl --user restart kuori      # restart it — never launch a second copy by hand
journalctl --user -u kuori -f       # follow its output
qs log -p /path/to/kuori            # or quickshell's own log
```

Starting a second instance by hand while the unit is running gives you two shells, each claiming its
own exclusive zone, and a border that reserves twice the space it should.

## Keyboard

The launcher is bound in `~/.config/hypr/hyprland.lua`:

| Keys | Does |
|---|---|
| `ALT` + `SPACE` | Open the launcher |
| `SUPER` + `R` | Open the launcher |

Every other entry point is an IPC call, so binding one is a line in your Hyprland config. The `-p` is
**not optional** — without it `qs ipc` may resolve a different Quickshell config:

```lua
local kuori = "qs ipc -p /home/tuomo/work/personal/kuori call "

hl.bind(mainMod .. " + N", hl.dsp.exec_cmd(kuori .. "notifications dnd"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(kuori .. "launcher wallpapers"))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(kuori .. "launcher clipboard"))
```

### Inside the launcher

| Keys | Does |
|---|---|
| `↑` `↓`, `Tab` / `Shift+Tab`, `Ctrl+n` / `Ctrl+p`, `Ctrl+j` / `Ctrl+k` | Move through the results, one at a time, wrapping at both ends |
| `Ctrl+h` / `Ctrl+l` | Move between category chips |
| `Page Up` / `Page Down` | Move by whole rows |
| `Ctrl+Home` / `Ctrl+End` | First and last result (bare `Home`/`End` belong to the text caret) |
| `Enter` | Run the selected row |
| `Escape` | Close |

A power row does not run on `Enter` — it raises a confirmation, where `Enter` confirms and `Escape`
goes back.

## IPC

Every call is `qs ipc -p <path-to-kuori> call <target> <function>`. `qs ipc -p . show` lists them.

### `launcher`

| Call | Does |
|---|---|
| `toggle` | Open or close the launcher, showing everything |
| `open` / `close` | Open showing everything / close |
| `apps` | Open on applications |
| `clipboard` | Open on clipboard history |
| `wallpapers` | Open on wallpapers |
| `windows` | Open on open windows |
| `power` | Open on suspend / reboot / power off |

The category calls **toggle**: pressing the same one twice opens and closes, while pressing a
different one while the launcher is open switches category without closing it.

### `notifications`

| Call | Does |
|---|---|
| `dnd` | Toggle Do Not Disturb |
| `clear` | Throw away the history |
| `dismiss` | Dismiss every toast currently on screen |

### `capture`

| Call | Does |
|---|---|
| `region` | Screenshot a region you drag out |
| `app` | Screenshot the active window |
| `monitor` | Screenshot the whole monitor |
| `record <target>` | Start recording `region`, `app` or `monitor`; empty uses whatever the panel shows |
| `stop` | Stop the recording and finalise the file |

`Print` is the obvious bind for `region`.

### `display`

| Call | Does |
|---|---|
| `night` | Toggle the night light |
| `awake` | Toggle the idle inhibitor |
| `temperature <K>` | Set the colour temperature, 2500–6500 |

## The notches

**Workspaces** (left) opens on hover, since it has nothing to click. The others latch open on a
click, and a click anywhere else closes them.

**Clock** (centre) opens a calendar. The month arrows page; the date line is clickable to come back
to today, but only when you have paged away from it. Clicking the time again closes the panel.

**System** (right) shows Wi-Fi, Bluetooth, volume and battery, plus a glyph for anything switched on
that it cannot otherwise show — a moon for the night light, a cup for the idle inhibitor, and a bell
when notifications are waiting or muted. It opens a panel of rows, one folded open at a time:

- **Wi-Fi** — known and available networks, signal, band, IPv4 and a latency reading. Clicking an
  open network joins it with **no confirmation**.
- **Bluetooth** — paired devices first. A device that has stopped advertising will refuse to connect;
  the row says so rather than looking dead.
- **Audio** — output and input devices, volume, and a switch that is mute read the right way up.
- **Battery** — level, time remaining, health, rate, and power profiles when a daemon offers them.
- **Display** — night light, stay awake, brightness, and a colour temperature slider that appears
  while the night light is on.
- **Notifications** — the Do Not Disturb switch and the history.

Panels only do work while they are open: the Wi-Fi scan, the latency probe and the backlight poll all
stop when their row folds away.

## Notifications

kuori answers `org.freedesktop.Notifications`. **Nothing else on the machine does**, so while kuori
is down notifications are not merely undrawn — they are dropped.

- Up to four toasts, newest at the top, each gone after about five seconds.
- **Clicking a toast dismisses it.** Buttons on it are the sender's own actions; the first is
  accented because it is the one the sender listed first.
- **Critical notifications do not time out.** They stay until dismissed.
- Toasts stand aside while the system panel is open, since they share that corner.
- **Do Not Disturb silences the toasts only.** A muted notification still lands in the history, which
  is the only place you would find out it arrived.
- The history keeps the last 50. Clicking an entry forgets it; `CLEAR` empties the lot. Anything a
  sender marked *transient* — volume popups and the like — is never kept.
- The bell on the system strip tracks what you have **not looked at**. Opening the notifications row
  marks the history seen.

## Wallpapers

Images live in `~/Pictures/wallpapers` — jpg, png, webp, gif, bmp, tiff and jp2. The launcher's
wallpaper category lists them with thumbnails, marks the one on screen, and offers a random pick that
never lands on the one already showing. A file dropped into the folder appears without a restart.

`awww` keeps its own cache of the last image, and its unit restores it at login, so kuori does not
remember your wallpaper for it.

## Clipboard

Everything copied goes to `cliphist`. The launcher's clipboard category lists it newest first, with
an icon for the kind of entry — text, a link, an image, or a swatch of the colour when the entry is a
hex code. Choosing one puts it back on the clipboard, ready to paste; it does not type it for you.
`Clear clipboard history` at the bottom wipes the store.

Anything a password manager marked with `x-kde-passwordManagerHint` is **never recorded**.

## Capture

The block at the foot of the system panel: pick **Screenshot** or **Record**, pick a target — Region,
App or Monitor — and press **Capture!**. Recording adds two switches, Desktop sounds (on) and
Microphone (off).

- **Screenshots are saved and copied at once**, so the file is kept *and* ready to paste.
- **Where they go is not kuori's decision**: `XDG_SCREENSHOTS_DIR` then `XDG_PICTURES_DIR` from
  `~/.config/user-dirs.dirs`, which on this machine means `~/Pictures/Screenshots`. Recordings go to
  `XDG_VIDEOS_DIR`. Change the file and everything follows, including other tools.
- Every capture announces itself with a notification, and a screenshot's notification carries the
  screenshot as its thumbnail.
- **A recording shows a red dot** on the system strip until you stop it, and the button reads
  `Recording…`. Press it again, or `qs ipc … call capture stop`, to finish.

Recording adds one switch, **Record microphone**, off by default. Desktop sound is not offered:
wf-recorder takes a single audio device and mixing two needs a virtual source nothing here builds.

Two things worth knowing:

**Encoding is hardware when a VAAPI driver is loadable, software otherwise**, and the notification
says which you got. The check is whether a driver sits in `/run/opengl-driver/lib/dri` — a driver
merely installed into `environment.systemPackages` is invisible to libva; it has to be in
`hardware.graphics.extraPackages`. wf-recorder exits rather than falling back, so the shell only asks
for hardware when it can see a driver.

**Restarting the shell ends a recording**, since the recorder is its child process.

## Configuration

There is no config file: this is a shell you edit. Almost everything lives in `theme/Theme.qml` —
every colour, size, duration and font in one place.

| Want to change | Look at |
|---|---|
| Colours, sizes, animation timing | `theme/Theme.qml` |
| Focus indicator style | `Theme.focusStyle` (`"mark"` or `"strip"`), `Theme.focusStripEdge` |
| How long a toast lasts, how many stack | `Theme.toastTimeout`, `Theme.toastMax` |
| Colour temperature range | `Theme.dispTempMin` / `dispTempMax` / `dispTempDefault` |
| Where wallpapers come from | `Wallpapers.directory` in `services/Wallpapers.qml` |
| What the latency reading pings | `Network.pingTarget` in `services/Network.qml` |
| How many clipboard entries the launcher shows | `cliphist`'s own `-max-items` |
| Where captures are written | `~/.config/user-dirs.dirs` — not kuori |

State that has to survive a restart — currently only the night light — is written to
`~/.local/state/quickshell/by-shell/<id>/`.

## Layout

```
shell.qml       the root: one shell per screen, plus the launcher, toasts and IPC
windows/        surfaces — which windows exist and what each is for
components/     reusable pieces with no domain knowledge
modules/        the contents of a tab, a panel or a dialog
services/       singletons: shared state, and everything that talks to the system
theme/Theme.qml every colour, size, duration and font
```

`CLAUDE.md` in this repo documents the architecture, the traps behind a lot of the code, and every
deliberate departure from the design.
