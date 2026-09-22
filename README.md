# kuori

A desktop shell for Hyprland, written in [Quickshell](https://quickshell.org) and QML. *Kuori* is
Finnish for shell, husk, envelope.

It draws a border around the whole desktop with tabs — "notches" — hanging off the top edge, and
provides an application launcher, a notification daemon, and an authentication agent.

## What it does

- **A frame** around the desktop, with the rounded opening your windows live in.
- **Four notches** on the top edge: workspaces (left), clock and calendar (centre), then the switches
  and the system tab (right). The calendar shows your Google Calendar events.
- **A launcher** with six categories: everything, applications, clipboard history, wallpapers,
  windows and power, each openable straight from a keybind.
- **An on-screen display** for the volume and brightness keys, dropping out of the system tab.
- **Notifications**: kuori *is* the session's notification daemon. Toasts appear top-right, and the
  history lives in the system panel.
- **An authentication agent**: kuori answers polkit, so privileged actions raise its own dialog.
- **A focus indicator** on the active window, either a corner wedge or a strip along one edge.

## Screenshots

![The desktop, with the frame and the four notches](docs/desktop.webp)

At rest: the frame around the desktop and the four tabs on the top edge — workspaces on the left, the
clock in the middle, and the switches beside the system tab on the right.

![Three windows, with the focused one marked along its top edge](docs/focus.webp)

Which window has focus, said by kuori rather than by a window border: a strip along one edge, with
horns at its ends that follow Hyprland's own corner radius. `Theme.focusStripEdge` moves it to the
bottom.

![The same three windows, with the focused one marked by a corner wedge](docs/focus-mark.webp)

The same three windows with `Theme.focusStyle: "mark"` — a wedge filling the focused window's
upper-right corner instead. It is the quieter of the two.

![The launcher, on the applications category](docs/launcher.webp)

The launcher, on applications, with a toast in the corner behind it.

![The system panel, with the display row folded out](docs/system-panel.webp)

The system tab open, with the display row folded out and the capture block underneath. One row folds
out at a time.

![A toast and the on-screen display](docs/notifications.webp)

The on-screen display dropping out of the system tab on a volume key, with a toast moving down out of
its way.

![The clock tab, showing the calendar](docs/calendar.webp)

The clock tab.

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
| Picking a colour off the screen | `hyprpicker` |
| Every capture's notification | `libnotify` (`notify-send`) |
| Knowing where captures go | `xdg-user-dirs` |
| Night light | `hyprsunset` |
| Calendar events | `python3`, and a Google OAuth client — see *Calendar* |
| Focusing a window, colour temperature | `hyprctl` |
| Icons in the launcher | any installed icon theme (Adwaita, MoreWaita) |
| Text | `JetBrainsMono Nerd Font` and `Manrope` |
| Every icon and glyph | `Material Symbols Rounded` |

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
| `kuori-calendar.service`, `.timer` | Runs `scripts/kuori-calendar sync` every 15 minutes, which writes `~/.cache/kuori/calendar.json` from Google. The clock panel reads that file and nothing else; without the timer it shows whatever was last synced, or "Not synced yet". |

## Installing

kuori is a Quickshell config rather than a program you build, so installing it is putting the files
somewhere and pointing Quickshell at them. Everything below assumes `~/.config/kuori`:

```sh
git clone https://github.com/syvanpera/kuori.git ~/.config/kuori
qs -p ~/.config/kuori
```

The second line runs it in the foreground, which is the quickest way to find out whether anything from
*Requirements* is missing — its complaints go to the terminal, and `Ctrl+C` stops it.

**`-p` names the config for every command**, and it is not optional. Quickshell's own default
directory is `~/.config/quickshell`, so a bare `qs` or `qs ipc` talks to whatever lives there — which
is a different shell, or a stale copy of this one. Keeping kuori outside that directory means nothing
resolves by accident.

### As a systemd user unit

Running it from a terminal is fine for a look, but the shell is also this session's notification
daemon and authentication agent, so it wants to start at login and come back if it dies:

```ini
# ~/.config/systemd/user/kuori.service
[Unit]
Description=kuori desktop shell
PartOf=graphical-session.target
After=graphical-session.target
ConditionEnvironment=WAYLAND_DISPLAY

[Service]
Type=simple

# the absolute path to the binary -- `command -v quickshell` gives it. a bare
# name is resolved against systemd's own compiled-in search path, /usr/bin and
# friends, which on NixOS is not where quickshell lives.
ExecStart=/usr/bin/quickshell -p %h/.config/kuori

# a unit gets systemd's own minimal PATH, not your login shell's. everything in
# Requirements has to be on this one, or it fails silently: the launcher simply
# stops launching, with nothing in the log.
Environment=PATH=/run/wrappers/bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin

Slice=session.slice
TimeoutStopSec=5s
Restart=on-failure

[Install]
WantedBy=graphical-session.target
```

```sh
systemctl --user daemon-reload
systemctl --user enable --now kuori
```

On NixOS the same thing belongs in your configuration as a `systemd.user.services` block rather than
a file — that is how this machine runs it — but the fields are the ones above, `Environment` included.

## Running it

```sh
systemctl --user restart kuori      # restart it — never launch a second copy by hand
journalctl --user -u kuori -f       # follow its output
qs log -p ~/.config/kuori           # or quickshell's own log
```

Starting a second instance by hand while the unit is running gives you two shells, each claiming its
own exclusive zone, and a border that reserves twice the space it should.

## Keyboard

Nothing is bound by kuori itself — every entry point is an IPC call, so the binds live in your
Hyprland config. These are the ones this machine uses, from `~/.config/hypr/hyprland.lua`:

| Keys | Does |
|---|---|
| `ALT` + `SPACE` | Open the launcher |
| `ALT` + `SHIFT` + `C` | Open it on the clipboard history |
| `SUPER` + `SHIFT` + `S` | Screenshot a region |
| Brightness up / down | One step of the backlight, through kuori itself |

Binding anything else is one more line, and the `-p` goes in every one of them:

```lua
local kuori = "qs ipc -p ~/.config/kuori call "

hl.bind(altMod .. " + SPACE", hl.dsp.exec_cmd(kuori .. "launcher toggle"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd(kuori .. "notifications dnd"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(kuori .. "launcher wallpapers"))
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

A power row does not run on `Enter` — it raises a confirmation, and while that card is up it owns the
keyboard: the launcher behind it stops answering keys entirely.

| Keys | In the confirmation |
|---|---|
| `←` / `→`, `Ctrl+h` / `Ctrl+l` | Pick Cancel or the action — the one the keyboard is on is lit |
| `Tab` / `Shift+Tab` | The same, toggling |
| `Enter` | Answer with whichever is lit. It starts on the action, as the card says |
| `Escape` | Cancel, leaving the launcher where it was |

## IPC

Every call is `qs ipc -p ~/.config/kuori call <target> <function>`. `qs ipc -p ~/.config/kuori show`
lists them, and `-p .` works from inside the directory.

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

### `calendar`

| Call | Does |
|---|---|
| `toggle` | Open or close the clock tab's calendar |

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
| `color` | Pick a colour off the screen and copy it |

`Print` is the obvious bind for `region`.

### `polkit`

Walks the authentication dialog through each state it can be in, against a mock request, so it can be
looked at without a real one. `close` puts it away.

| Call | Does |
|---|---|
| `prompt` | Raise the dialog, waiting for a password |
| `busy` | Show it verifying |
| `error` | Show a refused attempt |
| `ok` | Show it accepted |
| `close` | Dismiss it |

A real request from polkit raises the same dialog on its own; nothing here is needed for that.

### `display`

| Call | Does |
|---|---|
| `night` | Toggle the night light |
| `awake` | Toggle the idle inhibitor |
| `temperature <K>` | Set the colour temperature, 2500–6500 |

### `backlight`

| Call | Does |
|---|---|
| `up` / `down` | One step of the screen brightness, 5 points of the real range |
| `level` | Print the current percentage |

Bind these to the brightness keys and one press is one step of the scale the panel and the OSD show:

```lua
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("qs ipc -p ~/.config/kuori call backlight up"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("qs ipc -p ~/.config/kuori call backlight down"), { locked = true, repeating = true })
```

`brightnessctl`'s own percentages are **not** this scale. Its `-e4` moves 5% along a gamma-4
perceptual curve, which from 56% steps to 44, 34, 26, 19, 14 — each press a different amount of the
range the readings report. A bare `brightnessctl set 5%-` is linear and would agree with these
readings too; going through kuori also writes sysfs directly instead of starting a process per press,
and stops at 1% so a key held one press too long cannot leave a dark screen.

## The notches

**Workspaces** (left) opens on hover, since it has nothing to click. The others latch open on a
click, and a click anywhere else closes them.

**Clock** (centre) opens a calendar. The month arrows page; the date line is clickable to come back
to today, but only when you have paged away from it. Clicking the time again closes the panel.

A day with something on carries a dot per calendar, in each calendar's colour, and clicking it lists
that day's events under the grid — a bar and the time in the calendar's colour, all-day events first
with a dash for a time, and `+N more` past four. A legend under the list says which colour is which;
an account's primary calendar is named after the account. It opens on today. Paging the month drops the pick, and an
empty day cannot be picked. Under the header, "No events" means exactly that; "Not synced yet" means
no sync has ever run, and "Not synced this far" means the month on screen is outside what the last
sync fetched (the month before this one to three months ahead).

Opening the tab re-reads the file, and if it is older than five minutes starts the sync unit as
well, so what you see is at most a few minutes behind Google while you are looking and costs
nothing while you are not.

**Toggles** (right, just left of the system tab) is three switches and nothing else — a moon for the
night light, a cup for the idle inhibitor and a crossed circle for Do Not Disturb. Each is accent
while on and dim while off, and a click toggles it. The tab steps out of the way while the system
panel is open or the on-screen display is out, both of which grow over it.

**System** (far right) shows Wi-Fi, Bluetooth, volume, notifications and battery, and a red dot while
a recording is running. It opens a panel of rows, one folded open at a time:

- **Wi-Fi** — known and available networks, signal, band, IPv4 and a latency reading. Clicking an
  open network joins it with **no confirmation**.
- **Bluetooth** — paired devices first. A device that has stopped advertising will refuse to connect;
  the row says so rather than looking dead.
- **Audio** — output and input devices, volume, and a switch that is mute read the right way up.
- **Battery** — level, time remaining, health, rate, and power profiles when a daemon offers them.
- **Display** — night light, stay awake, brightness, and a colour temperature slider that appears
  while the night light is on.
- **Notifications** — the Do Not Disturb switch and the history.

**Every icon on the system tab is a button.** Clicking one opens the panel with that row already
folded out, and the icon is accented and underlined for as long as it is the row you are looking at;
clicking it again closes the panel. A click on the gap between icons opens and closes the panel
without choosing a row.

The bell is the exception in one way: it is accent whenever anything is in the history, whether or not
its section is open, and its glyph changes with it. Clicking it opens the history — it does not
silence anything and does not clear anything. Do Not Disturb is the switch on the toggles tab, and
`CLEAR` in the notifications row is what empties the history.

The red recording dot reports only; it is the one thing on the tab that opens nothing.

Panels only do work while they are open: the Wi-Fi scan and the latency probe both stop when their row
folds away.

### The on-screen display

Press a volume or brightness key and a box drops out of the system tab with the glyph, the name, the
percentage and a bar. It follows further presses and takes itself away 1.7 seconds after the last one.
Muted says `Muted` and `—`, with the bar at nothing in grey rather than accent.

**It does not need to be what your keys are bound to.** kuori watches the two values rather than the
keys: pipewire reports volume, udev reports the backlight. So the display answers a change made by
`wpctl` from a volume key, by `brightnessctl` in a terminal, or by anything else on the machine — and
it would work with no change to your Hyprland config at all. (The brightness keys here do go through
kuori, but for a different reason: see `backlight` above.)

Toasts move down while it is out, and it stays away entirely while the system panel is open, since the
panel is showing those same sliders.

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
- The history keeps the last 50. Clicking an entry forgets it; `CLEAR` empties the lot, and takes any
  toast still on screen with it. Anything a sender marked *transient* — volume popups and the like —
  is never kept.
- The bell on the system tab is accent while there is anything in the history. Clicking it opens the
  history; `CLEAR` inside that section is what empties it.

## Calendar

The events come from Google Calendar, from every calendar you have ticked in Google's own sidebar,
across as many Google accounts as you sign in. Working-location entries and events you have declined
are left out. A calendar shared into two of your accounts appears once.

Nothing in the shell talks to Google. `scripts/kuori-calendar` does, on the `kuori-calendar.timer`
(see *Companion services*), and writes `~/.cache/kuori/calendar.json`. Setting it up once:

1. In [Google Cloud Console](https://console.cloud.google.com/), create a project, enable the
   **Google Calendar API**, and under *Credentials* create an **OAuth client ID** of type **Desktop
   app**. Note the client ID and secret, or download the client JSON.
2. For each Google account, run the consent once, signing in as that account when the browser asks:

   ```sh
   scripts/kuori-calendar auth personal            # prompts for the client id and secret
   scripts/kuori-calendar auth work client.json    # or reads them from the downloaded file
   ```

   The account names are yours to choose; they only label the token. The refresh tokens land in
   `~/.local/state/kuori/google-oauth.json`, mode 0600. Keep that file out of any repository.
3. `scripts/kuori-calendar sync`, or `systemctl --user start kuori-calendar`, and open the clock tab.

**A Google Workspace account** may be barred by its admin from apps that are unverified or still in
"testing". If the consent page says so, create the OAuth client in a project owned by *that* account
and mark it **Internal** under *OAuth consent screen* — internal apps need no verification — and use
that client for that account. Each account keeps its own client, so mixing is fine.

`journalctl --user -u kuori-calendar` is where a failed sync explains itself. One account failing
does not stop the others; the file is only left untouched when every account fails.

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

Selecting an entry shows a **preview** under the list: the whole text rather than the truncated line,
an image drawn on a chequerboard so transparency reads as transparency, or a colour as a swatch beside
its value. The footer gives the size, and the dimensions and format for an image.

Anything a password manager marked with `x-kde-passwordManagerHint` is **never recorded**.

## Capture

The block at the foot of the system panel: pick **Screenshot** or **Record**, pick a target — Region,
App or Monitor — and press **Capture!**.

- **Screenshots are saved and copied at once**, so the file is kept *and* ready to paste.
- The pointer becomes a **crosshair** while you are selecting, for every target.
- **Region** drags a rectangle. **App** dims the screen and lets you click the window you want, not
  whichever happens to be focused. **Monitor** does the same for screens — and skips the picker when
  there is only one, since there is nothing to choose.
- **Where they go is not kuori's decision**: `XDG_SCREENSHOTS_DIR` then `XDG_PICTURES_DIR` from
  `~/.config/user-dirs.dirs`, which on this machine means `~/Pictures/Screenshots`. Recordings go to
  `XDG_VIDEOS_DIR`. Change the file and everything follows, including other tools.
- Every capture announces itself with a notification, and a screenshot's notification carries the
  screenshot as its thumbnail.
- **A recording shows a red dot** on the system strip until you stop it, and the button reads
  `Recording…`. Press it again, or `qs ipc … call capture stop`, to finish.

**Color** freezes the screen, magnifies whatever is under the pointer, and copies the colour you click
in the format you chose — HEX, RGB or HSL. The panel keeps the last one with a swatch, and it lands in
the clipboard history as a colour entry too.

Recording adds one switch, **Record microphone**, off by default. Desktop sound is not offered:
wf-recorder takes a single audio device and mixing two needs a virtual source nothing here builds.

Two things worth knowing:

**Encoding is hardware when a VAAPI driver is loadable, software otherwise**, and the notification
says which you got. The check is whether a driver sits in `/run/opengl-driver/lib/dri` — a driver
merely installed into `environment.systemPackages` is invisible to libva; it has to be in
`hardware.graphics.extraPackages`. wf-recorder exits rather than falling back, so the shell only asks
for hardware when it can see a driver. It looks once at startup, so a driver installed while kuori is
running is picked up after `systemctl --user restart kuori`.

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
| How far the calendar fetches, how often | `MONTHS_BACK` / `MONTHS_AHEAD` in `scripts/kuori-calendar`; `OnUnitActiveSec` in the timer |
| How old the calendar may be when the tab opens before it re-syncs | `Theme.calSyncStale` |
| How many events a day lists before `+N more` | `Theme.eventMax` |
| How many clipboard entries the launcher shows | `cliphist`'s own `-max-items` |
| Where captures are written | `~/.config/user-dirs.dirs` — not kuori |

State that has to survive a restart — currently the night light and its colour temperature — is
written to `~/.local/state/quickshell/by-shell/<id>/display.json`. Stay awake deliberately does not:
an idle inhibitor is invisible, and one silently restored after a restart is a flat battery nobody can
explain.

## Layout

```
shell.qml       the root: one shell per screen, plus the launcher, the polkit
                dialog, toasts and IPC
windows/        surfaces — which windows exist and what each is for
components/     reusable pieces with no domain knowledge
modules/        the contents of a tab, a panel or a dialog
services/       singletons: shared state, and everything that talks to the system
theme/Theme.qml every colour, size, duration and font
scripts/        what runs outside the shell: the calendar fetcher
```
