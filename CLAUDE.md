# Working notes

A Quickshell config for Hyprland: a border framing the whole desktop, tabs ("notches")
hanging off the top edge, and an application launcher.

It is built from a Claude Design mockup the user keeps updating. Where it lives is in
`CLAUDE.local.md`, which is not published: it points into the user's own account.

**Re-read the design before implementing anything from it**; it has been revised many times and the
local copy in a scratchpad is always potentially stale.

This file records what is *not* obvious from the design, and every place the implementation
deliberately departs from it. Everything here was established the hard way.

## Keep README.md current

`README.md` is the **user's** document: what the shell does, what it needs installed, every IPC call,
the keys, and how each panel behaves. Update it **in the same commit as the change** whenever any of
those move — a new IPC function, a new dependency or companion unit, a changed default, a toggle that
means something different than it did.

This file is the opposite document: why the code is the way it is. A trap, a deviation from the
design or a reason belongs here and not there. If a change produces both, it produces two edits.

## Ask before working around a missing tool

**If something would be simpler, cleaner or cheaper with a package or a service installed, say so
and ask.** Do not quietly build a clever way round the gap. The machine is the user's and adding to
it is their call, but it is a call they can only make if they are told there is one.

This applies to setup as well as packages: a group membership, a udev rule, a systemd user service,
a daemon that is installed but not enabled. It applies before starting a feature as much as during
one — screenshotting and clipboard history both need tools this machine does not have, and the
right moment to say so is before the first line is written, not after a workaround exists.

The shape of the ask: what the feature needs, what it would cost without it, what to install, and
what it buys. Then wait. A workaround built on an unasked question is worth less than the question.

## Layout

```
shell.qml          ShellRoot: Variants over screens -> DesktopShell, plus the launcher and its IPC
windows/           surfaces: which windows exist and what they are for
components/        reusable pieces with no domain knowledge
modules/           the contents of a tab or a panel
services/          singletons: shared state and data (and Helper.qml, the one non-singleton)
theme/Theme.qml    every colour, size, duration and font in one place
scripts/           what runs outside the shell: the calendar fetcher, run by its own unit, and
                   the three d-bus helpers the shell runs as children, sharing kuori_bus.py
```

`services/Helper.qml` is the one file in `services/` that is not a singleton: a python helper as a
child process — JSON lines out, words in, respawned after `Theme.helperRespawn` — which the lock, the
pairing agent and `Display`'s screensaver each own one of. It cannot live in `qs.components`: `Notch` there imports
`qs.services`, and services importing the module that imports them is a cycle. It runs the scripts
with `python3 -B`, and the scripts set `sys.dont_write_bytecode` too, because importing
`kuori_bus` would otherwise write a `__pycache__` into the config directory.

The shared pieces a new surface should reach for before writing its own: `PillButton` (every button),
`Field` (a `TextInput` with the accent caret and a placeholder), `SecretField` and `StatusNote` (the
password field and the line under it, lock and polkit), `ListEntry` (a row in a panel list),
`ToastFrame` (a card on the toast stack), `windows/ModalWindow.qml` (a fullscreen overlay with a
scrim and a grab), `Rule`, `StatGrid`, `KeyHint`, `Meter` and `Glide` (the design's easing curve).
They exist because each was written out by hand two to five times, and the copies had drifted.

`services/Bluez.qml` is named for the daemon, not the radio: `Quickshell.Bluetooth` already exports a
singleton called `Bluetooth`, and a file in `qs.services` with that name could not say which one it
meant. It is the only file that imports `Quickshell.Bluetooth`, and everything else goes through it.
`services/Audio.qml` owns `Quickshell.Services.Pipewire` on the same terms, and for a second reason: a
pipewire node stays unbound, with its `audio` null, until a `PwObjectTracker` asks for it, and two
trackers on one node is two of everything for nothing.

Conventions: 2-space indent, `id: root` on reusable components, custom properties then inherited
assignments then children, unversioned imports with `qs.*` last, `//` lowercase comments explaining
**why** not what, backtick template literals, no `pragma ComponentBehavior`.

## Window architecture

`PanelWindow.exclusiveZone` is a **single int per window**, so reserving 30px at the top and 5px
elsewhere needs one window per edge. Hence: one fullscreen `FrameWindow` that paints everything, plus
four 1px `EdgeReservation` windows that paint nothing and only claim space.

Two things here are load-bearing and look redundant:

- `FrameWindow` must set `exclusionMode: ExclusionMode.Ignore`. Without it Hyprland places the frame
  *inside* the area its own reservation windows just claimed, and the border pulls inboard on every
  reload.
- `EdgeReservation`'s anchors are edge-plus-both-neighbours **triplets**. Hyprland only resolves an
  exclusive edge for a single anchor or that triplet. Do not "simplify" them to one anchor each.

The whole frame is drawn as **one** `Shape` path with the desktop punched out by the odd-even rule.
The hole has to be genuinely transparent, which a `Rectangle` cannot do.

## Deviations from the design

| What | Why |
|---|---|
| Frame's **outer** corners are square; the **inner** desktop opening is rounded | The design rounds the outer corners, which only makes sense for a screen floating on a web page. On real hardware that would reveal wallpaper in each corner. |
| A notch is **one box that grows**, not the design's two stacked boxes | Same picture, and it keeps the fillets and the drop shadow following the silhouette for free. |
| Notch shadows are drawn **before** the frame | The design paints them over the border band (notch z-index 50, band 40). At 5px offset and 14px blur that smears a dark wash along a 5px rail. Drawing first means the band covers the top of the shadow and only the part over the desktop survives. |
| The design's `box-shadow: 0 0 0 1px <surface>` outline is **not** ported | That is the CSS way to hide the hairline where a fillet meets a body. `Theme.seamBleed` already solves it, and two mechanisms for one seam is one too many. |
| Battery shows `85%` | The design shows a bare number. |
| Wifi/bluetooth/volume **dim** when off rather than turning red | The design paints every glyph the same shade; dimming is the smallest deviation that still makes a dead radio legible. |
| A wifi glyph reports **signal strength**; the design never does | The design draws every wifi glyph as a plain `wifi` and only one row of its mock data carries a weaker one, so there is no ladder in it to port. `Network.glyph` is this shell's own, in three steps because the design's own family (`wifi`, `wifi_2_bar`, `wifi_1_bar`) has no three-bar member. The strip and the panel rows had *two different* ladders in *two different* glyph families until it existed, so one access point could read three bars in one place and two in the other. The volume ladder beside it (`Audio.levelGlyph`) **is** the design's, taken from the one place it writes one down — its OSD — including that a muted sink reads as `volume_off` rather than as quiet. |
| The bluetooth glyph says **connected** — `bluetooth_connected` — on the strip and the panel row alike | The design draws a plain `bluetooth` everywhere. The strip had grown a three-step ladder of its own while the row kept the design's two, so one radio read two ways; `Bluez.radioGlyph` is now the one ladder, the way `Network.linkGlyph` is for the network. |
| The ETHERNET section is **hidden** on a machine with no wired interface | The design always draws it. This laptop has no port, so a permanent row would be a switch for nothing — the POWER PROFILE reasoning. A USB adapter or dock brings it in, one row per interface. |
| An ethernet row can say "Connecting…" | Not in the design, which has only connected, disconnected and unplugged. DHCP takes seconds, and a switch that moved with the line under it still saying "Disconnected" looks like it did nothing. |
| Launcher rows show `genericName` (then comment, then id), not the raw command | For real entries "Web Browser" says more than "chromium", and in the design's own mock data that line is context rather than literally the command. |
| The launcher sits in the desktop opening's **upper third**, not 96px from the top | The design is a 1200px-wide mockup; on a real 1600x1000 desktop its offset puts the panel high. It was centred until the clipboard preview arrived, which made a centred panel crowd the bottom of the screen whenever it opened. `Theme.launcherBias` (0.38) is the share of the free space above it. It is applied to **every** category and measured against `AppLauncher.fullHeight`, so the top never moves — not when a query shortens the grid, not when the preview appears. |
| A window row carries its application's **real icon**, not the design's tab glyph | The design draws every window with the same `tab`. A column of identical glyphs is a list you read rather than scan; the glyph is the fallback when the class matches no desktop entry. |
| Windows are listed **most recently focused first**, and the current one says `· current` | Neither is in the design. Hyprland hands over `focusHistoryID`, which is the only order a window switcher should offer — alphabetical would be actively unhelpful. |
| The power rows keep the design's order instead of sorting by name | Not cosmetic. Alphabetically "Power off" comes first, so opening the category and pressing return — the one gesture the launcher teaches — would shut the machine down. Suspend, Reboot, Power off: safest first, via the same `order` the clipboard uses. |
| Power rows confirm; nothing else does | The design added this after the category was built, and it keys off `cat === "power"` exactly as the design's `runApp` does. A row carries no flag of its own saying it is dangerous. |
| The clipboard is **left out of ALL** (`inAll: false`) | The user's call, and it is right: a log of what you copied, interleaved with applications by name, is noise in both directions. It is the only category with that flag. |
| No `· 2 min ago` on a clipboard row, and none in the preview header either | cliphist stores **no timestamps at all** — its ids are a counter, `1`, `2`, `3`. The order is real, the age is not knowable, so the second line says what the entry is instead and the preview's header is just `PREVIEW`. |
| The image preview draws the **actual image**, not the design's placeholder | The design puts a glyph and a filename on a chequered ground, because a mockup has no clipboard to read. The chequerboard is there for transparency, which only means something behind a real image — so the real one is drawn on it, with the placeholder kept for the moment before it decodes. |
| The preview's meta line names no mime type | The design writes `33 B · text/plain`. cliphist records no type: an image announces its size and format in the listing, and text is measured once decoded, so the line says what is actually known. |
| A clipboard image is named by type and size, not `Screenshot 2026-09-18.png` | There is no filename in the store either. The listing gives `[[ binary data 26 KiB png 400x229 ]]`, so the row reads "PNG image" over "400×229 · 26 KiB". |
| An empty category says "Nothing here yet" | The design only has `No matches for "…"`, which with an empty query would be answering a question nobody asked. |
| A wallpaper row is named from its filename, prettified | `0-winding-road.webp` becomes "Winding Road" — the leading number is somebody's sort key, not part of the name. The design's rows carry hand-written names it does not say where to get. |
| The wallpaper on screen says `· current` | Not in the design, which has no state for it. Six pictures with no mark is six pictures you cannot tell apart from the one you are looking at. |
| `Random wallpaper` sorts after the pictures | The design lists it last. An alphabetical sort would drop it wherever "random" falls, so a row may set `last: true`, which `AppSearch.byName` uses as a tiebreak only — a query that scores it higher still lifts it. |
| Focus mark / focus strip | Not in the design at all — the user's own feature. `Theme.focusStyle` picks `"mark"` (corner wedge) or `"strip"` (a bar on the window's edge, `Theme.focusStripEdge` top or bottom). Unfocused windows on screen carry the same shape in hyprland's own `inactive_border` grey (`Theme.focusMarkUnfocused`), one `WindowMarker` per window in `UnfocusedIndicators` — the focused one keeps its single moving indicator and its one-frame blank, which a per-window delegate has no need for. A special workspace is only known to be showing when focus is on it; asking would mean refreshing the monitors too. **Floating windows are not marked** (`Theme.focusMarkFloating: false`) and get hyprland's own 2px border from a `floating-border` rule in their `windows.lua`: hyprland emits no event while a window is dragged or resized — nothing on socket2, nothing in the lua event list — so a mark stayed where the window had been until something unrelated fired. Hiding the mark only *during* a drag was considered and dropped: a `non_consuming` bind can catch `SUPER` + mouse drags, but a client-side titlebar drag goes through no bind at all. |
| The focus strip's outer corners are rounded by their own `Theme.focusStripEndRadius` | Not by half the thickness: the horns make the outer edge four times taller than the bar, so a radius scaled to the bar is round in the arithmetic and square to the eye. It followed `windowRadius` until the user tuned it, and the horns still do — they have to ride hyprland's own curve. |
| A second click on the clock's time closes the panel | In the design the strip collapses to zero height when open, so its own toggle is unclickable. |
| The calendar's date line is clickable **only** when paged off the current month | On the current month it is already saying something true and has nothing to undo. |
| A bluetooth device says "Connecting…" and can say "Could not connect" | Not in the design, which has no state for either. BlueZ refuses a device that has stopped advertising, which is most of them a moment after the host dropped them — so without this a refused click and a dead click look identical. |
| Clicking an unpaired bluetooth device **pairs** it, then trusts it, then connects | The design's AVAILABLE rows only ever connect, and bluez refuses to connect a device it has never paired. Trust is what lets an input device reconnect on its own. |
| A pairing question arriving while the system panel is out on **another row** switches the panel to Bluetooth | The design shows its toast whenever the Bluetooth section is not on screen. Here the toasts stand aside for the system panel (see above), so with the panel out on Network the toast would be seen by nobody. |
| A legacy PIN on a keyboard card is shown whole, with no `N of 6 entered` | bluez's `DisplayPinCode` reports no keypresses and its PIN need not be six digits. The design only draws the six-digit passkey, which `DisplayPasskey` does count. |
| `AuthorizeService` is answered without asking | Not in the design. bluez only asks it for an untrusted device, and every device paired here is trusted as it lands, so a question would be about a device paired elsewhere — allowed if paired, refused otherwise. |
| A device arriving in CONNECTED does not replay the design's `qs-bt-in` drop | The design marks a freshly connected mock device `fresh`; nothing real carries that, and animating every delegate as the panel opens would be wrong. |
| The bluetooth AVAILABLE list is sorted, paired first | BlueZ hands devices over in the order it learned them, so an unsorted list rearranges itself under the pointer whenever discovery finds something. |
| The audio row's ENABLED switch is **mute**, read the right way up | The only thing about sound that can be switched off. The design names the switch and leaves what it does to the reader. |
| The battery grid shows **Health** and **Rate**, not the design's Limit and Cycles | Nothing under `/sys` on this machine exposes a charge threshold, and upower reports `charge-cycles: N/A`. Health and rate are both real here, and two permanent dashes would be worse than two readings the design did not think of. |
| The POWER PROFILE section is **hidden** when no daemon answers | Not in the design. Without power-profiles-daemon the buttons cannot do anything, and `PowerProfiles` has no flag saying so, so `hasPerformanceProfile` stands in for one. |
| The polkit dialog's DETAILS shows **ACTION and COOKIE**, not the design's COMMAND / PROGRAM / VENDOR / PID | polkit hands those to an agent in a details map that `AuthFlow` does not expose. The block shows what is actually known rather than inventing the rest. |
| No "N tries left" under the field | No attempt counter is exposed either. `supplementaryMessage` is shown verbatim — pam's own words. |
| The identity is **whoever polkit offers**, not a hardcoded "root" | On NixOS with `wheel` as admin this is the user, not root. The design's "Superuser · authenticating as root" is its mock data. |
| The field's placeholder is `inputPrompt` | pam says what it wants ("Password: "); the design hardcodes "Root password". |
| Clicking the scrim does **not** dismiss the polkit dialog | Unlike the launcher. polkit is still waiting on an answer, so the grab re-arms itself and only Cancel or a password ends it. |
| A click on an **open** network joins it with no confirmation | Straight from the design, and worth knowing: a stray click on a neighbour's open access point takes you off your own. |
| The temperature slider runs **2500K to 6500K**, not hyprsunset's 1000–20000 | 20000K is not a night light. The design puts 4200K at 42% of its track, and 2500..6500 is the range that lands it there, with 6500 the daylight end where the slider stops doing anything. |
| Night light persists across a restart; stay awake does not | Night light is visible — an orange screen under a switch reading Off would be worse than either state. An idle inhibitor is invisible, and one silently restored after a restart is a flat battery nobody can explain. |
| A toast's tile shows the sender's **icon**, the history's shows a coloured bell | The design gives each mock app its own glyph, which it can do because it knows its four apps by name. A real notification offers an icon, which the toast is big enough to show; at the history's 14px an application icon is mush, so there the colour carries the urgency and nothing else. |
| Toasts **stand aside** for the system panel | The design draws the panel over them (z-index 50 against 45) and they share the same corner. Layer-shell has no such ordering — two surfaces on one layer stack by creation order, and the toast surface is always the later one — so it hides while that one panel is open. Nothing is lost by it: that panel is where the history is. |
| Clicking a history entry forgets it | The design hovers an entry like something clickable but gives clicking no meaning. Throwing that one away is the only thing it could sensibly do. |
| Clicking a toast, or one of its buttons, **forgets it from the history** | The user's call, 2026-09-22: a toast they had clicked was still lighting the bell and sitting in the history. The design's toasts only time out, so it has no rule here. Expiry, `DISMISS ALL`, Do Not Disturb and a client withdrawing its own notification all keep the entry — nothing was read in any of those. |
| A strip icon whose section is already open **closes the panel** | The design's `notchGo` sets the row unconditionally, so the icon of the open section does nothing. Every other latched thing here — the notch itself, each launcher category bind — answers a second press by closing, and the user asked for the same. |
| Strip icons name themselves in a tooltip **drawn by the shell** | The design writes each as a `title`, which a browser draws in its own chrome; the words are the design's, the pill is ours — the tab's surface and a small shadow. It is one `StripTip` per frame, drawn last and outside the input region, fed by `Notches.tip`, so it can never swallow a click. It stands aside for an open panel and for the osd, and the cup adds whose hold is lighting it (`kept awake by …`), which the design has no state for. The network and volume tips also name what they are on — the access point or `Ethernet · 1 Gb/s`, and the sink (`· muted` when it is) — the user's call, 2026-09-24, over the design's bare "Wi-Fi" and "Audio". |
| The lock turns the screen **off** a minute after it locks | The design has a lock and no blank. The user's call: lock first, dark after, which is what `Theme.lockIdle` then `Theme.lockBlank` are. |
| The lock's prompt is on the monitor **with the keyboard** | The design's secondary scene draws a second screen without saying which is which. The keyboard is where a typed password goes, so that is the screen that asks for it, and it follows focus. |
| The lock's name and initial come from the passwd entry | The design's "Veera Laine" is mock data. The GECOS field is what `getent` gives, up to its first comma. |
| A recording lights a red dot on the system strip | The design gives a recording no indicator anywhere. One you cannot see is one you forget you started, and this is a laptop. |
| Ping measures the path to the **internet**, not to the gateway | A router three metres away answers in single digits whatever the connection is doing. `Network.pingTarget` is the one line to change. |
| The **primary** calendar of an account is named after the account, not after itself | Google names it after the account's email address, which is not a legend entry. The name the account was given at `auth` — "personal", "work" — is what the design's legend shows. |
| An all-day event's time column is `—` | The design's 32px column fits `09:30` and nothing has an all-day event in it. "All day" does not fit; a dash in the calendar's colour says "no time" and keeps the titles aligned. All-day events list first. |
| The list stops at `Theme.eventMax` rows and says `+N more` | The design's mock data never has more than three. A panel that grows to a day of back-to-back meetings pushes its own bottom off the screen. |
| `Not synced yet` and `Not synced this far` | The design has "No events" and a calendar by construction. Here "no events" is only true once a file has been read and its window reaches the month on screen, and saying it before that would be a lie about a day nothing knows about. |
| Declined and working-location events are **dropped** by the fetcher | A working-location entry is Google's "in the office" marker, one per weekday, and would dot every day of the month. A declined event is one you said you are not at. Neither is a rule of the design, which has no such rows in its data. |

`Theme.surface` is `#0b0f16`. It began as the user's own departure from the design's lighter
`#0f1726` — still commented beside it — and on 2026-09-21 **the design adopted it**, along with the
text base, the well alpha and the shadow alphas this shell had tuned against it. Those are no longer
deviations and have been struck from the table above.

**The two palettes are now identical.** Every colour this shell defines appears in the design, and
what is left in the design that `Theme` does not name is mock content — wallpaper swatches, the
colours of its four example notifications — its own trigger buttons, and the defaults in its editor
schema. So a colour that differs from here on is a mistake rather than a decision, and the way to
check is to pull both palettes and diff them rather than to read either one.

The launcher's chips are **all six the design has**, in its order: ALL, APPS, CLIPBOARD,
WALLPAPERS, WINDOWS, POWER. ACTIONS was dropped from the design on 2026-09-21, before it was built —
its rows are still in the mock data, with no chip to reach them. The list is data-driven, so the
order is `categories` and nothing else depends on it.

The design states a panel's width **outside its padding** — css pads outside a stated width — so the
286 it writes for the system panel is a 314 box. It says so itself: the system tab's strip grows to
exactly `314px` when the panel opens. Both panel widths in `Theme` are therefore the whole
box: 314 for the system tab, 260 for the clock.

The system tab is the only one that **keeps its strip** while open (`Notch.keepStrip`): the glyphs it
reports stay on screen and the panel hangs underneath them, rather than the strip folding to nothing
the way the workspaces and clock tabs do.

Its glyphs are also clickable, and three things had to move for that:

- **Which row is folded out lives in `services/Notches.qml`**, not in `modules/SystemPanel.qml` where
  it started. The strip has to set it and read it, and the panel does not exist to be asked until the
  tab is already open — the same reason the launcher's category lives in its service. It could not go
  in a `services/SystemPanel.qml`: that name would collide with the module across the `qs.services`
  and `qs.modules` imports, which is what `Bluez` is named around.
- **`contentItem` in `components/Notch.qml` carries `z: 1`.** The bare `MouseArea` that toggles a
  click-opened tab covers the whole strip band and is declared *after* the content, and among siblings
  at equal z qt delivers to the later one — so without this every per-glyph handler is shadowed and
  never fires. With it, an icon takes its own click and the gaps between icons still toggle the tab.
- **`StripGlyph` is only an indicator now.** It animates its width from nothing, so a glyph that uses
  it cannot be clicked before whatever it reports has happened; the recording dot is the last thing on
  the strip that still works that way. The three switches were `StripGlyph`s until the design made
  them permanent, which is what made them switches rather than lamps: a control that is invisible
  while off can only ever be turned off. They have since left this tab altogether — see below.

`components/StripButton.qml` is the other half: it wraps content rather than drawing a glyph, because
the battery is a glyph *and* its percentage and the design makes the pair one target. Its underline is
a `Rectangle` drawn **below** the item's own height — a font underline honours neither the design's
1.5px thickness nor its 4px offset, and keeping it outside the height is what stops a section opening
from making the strip taller and shoving every glyph on it sideways.

### The system panel's keyboard

`↑` `↓` and return are answered by `FrameWindow`'s key sink, which already holds the keyboard while a
panel is open, and passed to `SystemPanel.step()` and `press()` through `Notch.panelItem`. Nothing
registers anywhere: a target is any item with `keyTarget: true`, a `keyed` flag and a `press()`, and
the panel **walks its own children** on every key to find them, in reading order — a Column lists
children in drawn order, and a Repeater inserts its items at its own place in that list. `PanelRow`
says `keyChildren: expanded`, which is what keeps the walk out of folded rows. The list is walked
rather than kept because the lists under it change by themselves — a scan, a device connecting.

The targets are row headers, `SectionSwitch`, `DisplayToggle`, a clickable `ListEntry` and the power
profile buttons. The panel remembers the one item it lit (`lit`), because the cursor can be left in a
row that then folds shut, where the walk would not reach it to put its wash out. A pairing card's keys
still win: `steering` is off while one is up. The first arrow starts from the row that is out.

## The toggles tab

Night light, stay awake and do-not-disturb live in a tab of their own, floating `Theme.togglesGap`
clear of the system tab with no panel under it: the three glyphs are all of it. The system tab beside
it is now six **reports**, each opening the section of the panel that is about it — wifi, bluetooth,
volume, display, notifications, battery — so the two tabs divide cleanly into things you read and things you
throw.

- **The bell in the system tab opens the history; it does not silence anything.** Do-not-disturb is
  the `do_not_disturb_on` switch in the toggles tab, one glyph either way with only its colour moving.
  The bell is `notifications_active` or `notifications_none`, and it is accent whenever there is a
  history — open or not, which is the design's own "hot" — while the underline still means only that
  its section is showing.
- **`Notch.aside`** is how it gets out of the way of the system panel and the OSD, both of which grow
  over the space it occupies. It fades, and **its hit area goes to nothing with it**: a wayland input
  region knows nothing about opacity, so a faded tab left in the region would go on swallowing clicks
  meant for the desktop under it.
- **`Notch.padding` is a property rather than a rule.** The wide variant belongs to the clock; this
  tab is centre-placed, for its corners and its two fillets, but padded like the tabs that carry
  glyphs.
- It is placed from the system tab's **strip** width rather than its body, so it stays where it is
  when that tab grows a panel — which it does leftwards, over this.
- The recording dot stays at the end of the system tab (the user's call): it is a report like the rest
  of that tab, even though it is the one thing there that opens nothing.

## More than one monitor

**The tabs are on one monitor by default** (`Theme.tabScreens: "main"`; `"all"` is every screen,
which is how it was until 2026-09-24). Hyprland has no primary monitor — nothing in `hyprctl
monitors` is marked as one — so `Screens.main` is the monitor workspace 1 is on: their
`monitors.lua` pins that workspace, so kuori follows their config instead of keeping a monitor name of
its own. Every question goes through `Screens.hasTabs(name)` and `Screens.tabsName` (the screen an
unnamed request means: main, or focused in `"all"`), so the switch lives in one place:

- `DesktopShell` reserves `borderWidth + notchHeight` on top only where there are tabs, and 5
  elsewhere, so windows get the band back.
- `FrameWindow` hides the four tabs and their shadows, and takes their hit areas out of the mask.
  A hidden `Notch` keeps its size, so the region has to be gated rather than left to visibility,
  and the toggles tab is hidden through `aside` because `Notch` binds its own `visible` to its
  fade.
- `Notches.resolve("")` is `Screens.tabsName`, so keybinds and ipc open on the screen that has the
  tab. The osd follows the system tab it hangs from.
- The launcher and the toasts still follow focus, and on a screen without tabs they subtract the band
  they no longer need to clear. A toast only makes room for the osd on the screen the osd is on.

Every screen gets a whole `DesktopShell` — frame, four reservations, all four tabs — from the
`Variants` in `shell.qml`, and that part worked the first time three monitors were plugged in
(2026-09-23: `eDP-1` 1440x960 logical at scale 2, and two 2560x1440 LGs at scale 1, `DP-11` and
`DP-12`). What did not was every panel, and the reason is worth knowing:

- **Hyprland holds one focus grab at a time.** Each `FrameWindow` activated its own
  `HyprlandFocusGrab` off the one global `Notches.open`, so opening a tab started three grabs, the
  later ones cleared the first, and a cleared grab is this shell's "clicked elsewhere": the clock
  panel opened and shut in 6ms, before it was ever drawn. Logged as `open = "clock"`, `grab cleared on
  eDP-1`, `open = ""`.
- So `Notches` carries the **screen** as well as the tab — still one panel for the whole shell,
  because one grab — and everything per-screen asks `Notches.openOn(screenName)`. Tabs are handed
  `screenName` explicitly, the way `FocusIndicator` is handed its monitor; a call with `""` means the
  focused monitor, which is what keybinds and ipc want.
- **A grab also clears when the panel moves away from it**, and not only on a click elsewhere. The
  handler only closes when `Notches.screen` is still its own screen, or moving the calendar from one
  monitor to another would shut it on arrival.
- **The OSD shows on the focused monitor only.** It was on all three at once, which for brightness
  meant two external monitors reporting a laptop backlight they do not have. `OsdBox.here` gates it,
  and the toggles tab steps aside for its own screen's box rather than for `Osd.shown`.
- Verified by moving the pointer with `hl.dsp.cursor.move` to change the focused monitor and opening
  the calendar over ipc on each in turn: open on that screen only, moved on the next, stayed open.
  Real clicks on the tabs across the three monitors were then tried by the user and work.

## The bluetooth pairing agent

bluez asks an agent to confirm **every** pairing, a mouse's included — with no agent it refuses
outright: `new_auth() No agent available for request type 2` and `Authentication Failed`, seen on an
MX Master 3S. Quickshell 0.3.1 cannot export a D-Bus object and its `Quickshell.Bluetooth` has no
agent (upstream closed PR #138 unmerged; issue #417 is open). So `scripts/kuori-btagent`, python3 plus
`jeepney` from the package's wrapper, registers `org.bluez.Agent1` and relays each question to the shell
as one JSON line on stdout; `services/Bluez.qml` answers on stdin. It is a child `Process`, not a
unit: an agent with no dialog behind it is useless, so it lives and dies with the shell, and is
restarted five seconds after it exits.

- **It must be the default agent**, not merely registered. bluez gives a pairing to the agent owned
  by whoever called `Pair` — quickshell's own connection — and only falls back to the default.
  `RegisterAgent` then `RequestDefaultAgent`, in that order.
- **A registration dies with bluetoothd, silently.** The helper watches `NameOwnerChanged` for
  `org.bluez` and registers again with the new owner.
- **`RequestAuthorization` means two things.** It is how bluez asks about a just-works device the
  shell is pairing (the design's "Pair with …?") *and* how a device that started pairing itself asks
  to be let in ("… wants to pair"). The only way to tell is whether `Bluez.pending` names it.
- **A keyboard card has no question waiting.** `DisplayPasskey` is answered at once and repeats per
  key typed, so cancelling it is `cancelPair()` on the device, and its card ends when `paired` goes
  true rather than on any button.
- **Pairing reads connected with no profiles up**, so `Bluez.isConnected` holds a device out of
  CONNECTED until it is paired, done pairing and no longer pending — otherwise it jumps lists, card
  and all, mid-question. Failure is checked 500ms after `pairing` drops, because bluez can clear it a
  beat before setting `paired`.
- **The pin field takes the keyboard and Qt gives it back to nobody.** When a focused `TextInput` is
  destroyed, active focus goes to no item and the frame's escape handler stops hearing anything.
  `Notches.refocus()` is the field's `onDestruction` asking `FrameWindow`'s key sink to take it back.
  The network passphrase field does the same.
- **Nothing but root can call an agent.** The system bus policy lets only bluez's side send to
  `org.bluez.Agent1`, so `busctl call` on the helper is `Access denied`. It was tested against a fake
  connection — every method, every answer, the serialised replies — and then for real on
  2026-09-23: an MX Master 3S and an MX Mechanical keyboard both paired from the panel and came out
  paired, trusted and connected, where the same mouse had failed three times without the agent. `qs ipc -p . call bluetooth mock confirm|compare|type|pin|incoming`, `typed <n>`,
  `cancel` and `fail` fake the helper's lines, which is how every card was checked on screen.
- `bluetoothctl` and `bluetui` register agents of their own while they run and take the default;
  ours gets the questions back when they exit.

## The network row

It was Wi-Fi only until 2026-09-23, when the design added an ETHERNET section. `services/Network.qml`
still calls the radio `device` — it has the most uses — and the wire is `wired`, the first connected
`WiredDevice`. `linkDevice` is whichever of the two is carrying traffic, **wire first**, which is also
NetworkManager's own route metric order (ethernet 100, wifi 600). The IP, the counters and the ping
follow `linkDevice`; the band and the scan stay the radio's.

- **`WiredDevice` has what the row needs**: `hasLink` is carrier (cable in), `linkSpeed` is Mb/s, and
  `network` is the profile. No nmcli for any of it.
- **The switch is `disconnect()` one way and `network.connect()` the other.** NetworkManager answers
  a device disconnect by blocking autoconnect on it, so off stays off across a re-plug until the switch
  goes back on — which is what a switch should mean. An `nmcli device connect` fallback covers a wire
  with no profile to hand. Verified 2026-09-23 on a USB adapter: off deactivates, on runs the profile
  all the way to connected, and a pulled cable reads `Cable unplugged` with the switch faded.
- `Switch` fades when `enabled` is false and its `MouseArea` inherits that, which is all "unclickable
  while unplugged" needed.
- `qs ipc … call system toggle wifi` opens the panel on the row, so the no-click states can be
  checked without ydotool. The row id is still `wifi`; renaming it would touch `Notches` and every
  strip button for a string nobody sees.

## Hyprland here is configured in Lua

This is the single biggest source of silent failures. Dispatch strings are **Lua expressions**, not
the classic space-separated form. `Hyprland.dispatch("workspace 4")` comes back
`')' expected near '4'` and the shell never sees the error — the click just quietly does nothing.

```
hl.dsp.focus({ workspace = 4 })        switch workspace   (see services/Workspaces.qml)
hl.dsp.cursor.move({ x = …, y = … })   move the pointer   (for testing)
hl.dsp.exec_cmd("…")                   run something
```

Their config lives in `~/.config/hypr/` (a symlink into `~/work/personal/dotfiles`). `hyprland.lua`
is the entry point and `require`s the rest; the binds are in `bindings.lua`, which **is** loaded now
(checked 2026-09-23 — an older note here said it was not). `hyprctl binds` shows a lua bind only as
`dispatcher: __lua` with a handle, so find one by `key` and `modmask` (SUPER 64, CTRL 4, SHIFT 1).

The launcher is opened by an `IpcHandler`, bound in their config through the package's wrapper:

```lua
local kuori = "kuori ipc call "
hl.bind(altMod .. " + SPACE", hl.dsp.exec_cmd(kuori .. "launcher toggle"))
```

`kuori` is quickshell with `QS_CONFIG_PATH` set — quickshell's own environment spelling of `-p` —
so `kuori ipc`, `kuori log` and the unit all name the same config (see *The flake*). With bare `qs`
the `-p` is required: a bare `qs ipc` resolves to `~/.config/quickshell/`.

**And the path has to be spelled the way the unit spells it.** `qs ipc` matches instances by the
literal path the shell was started with — `qs ipc -p . call …` from the repo answers `No running
instances` while the unit runs `~/.config/kuori`, a symlink to it (seen 2026-09-23). The wrapper is
what makes this impossible to get wrong. Every `qs ipc -p . call` below is `kuori ipc call`.

## Panels: why click-to-open

A press that lands **over a window** makes Hyprland hand focus to that window, and the pointer leave
that follows cancels the click before it completes. A hover-held panel is gone by then, so its
buttons never fire — the calendar's month arrows did nothing for exactly this reason.

So: panels with controls **latch open on a click** (`Notch.trigger: "click"`), and a
`HyprlandFocusGrab` holds input on the shell while one is open, which is also what makes a click
anywhere else dismiss it. Only the workspaces tab, which is read-only, opens on hover.
`services/Notches.qml` holds which tab is open, because only one can be.

A hovering tab also stays shut while another tab is open, so brushing past it cannot yank a panel
away from under the pointer.

The system panel folds one row open at a time, and `services/Network.qml` hangs everything it costs
off `Network.detailed`, which is bound to that row being open: the wifi scan, the ping and the
counter poll all stop the moment it folds away. A panel nobody is looking at does no work, which is
the same bargain the calendar's event data is meant to make.

## The launcher's rows

Everything in the result grid is one plain object, whatever produced it:

```
{ cat, name, detail, icon, image, glyph, path, run }
```

plus the fields `AppSearch` scores — `genericName`, `keywords`, `comment`, `command` — named after
the desktop entry ones **on purpose**, so the ranking scores a wallpaper without knowing it is not an
app. `modules/LauncherRow.qml` picks the tile in that order: a picture of its own, a material
symbol, the icon a desktop entry names, then a letter.

The rows have to be **stable objects**. `ScriptModel` diffs by identity, so building them per
keystroke would read as a whole new list, reset the view and reload every icon. They are rebuilt only
when a source changes — `DesktopEntries` for apps, `Wallpapers.files` for pictures — and they live in
`services/LauncherRows.qml`, not in the panel: the panel's window is destroyed on close, so rows built
there were rebuilt, window lookups and all, on every open. `AppSearch` keeps each row's lowercased
fields on the row the first time it scores it (`haystack`), which only works because they are stable.

`Windows.entries` is `[]` unless `Launcher.mapped` — true from the open until the window has finished
fading out. It reads every window's title, and a terminal with a spinner renames itself several times
a second; `opened` would have emptied the window list during the fade.

Which category is showing lives in `services/Launcher.qml`, not in the panel: the panel is destroyed
on close, and a keybind that opens straight into a category has to say so before there is a panel to
tell. Each category gets its own IPC function, so a bind is a fixed string and `qs ipc show` lists
what can be bound:

```
qs ipc -p . call launcher wallpapers | apps | clipboard | windows | power | open | close | toggle
```

They toggle: the same bind twice opens and closes, a different one switches category without closing.

Inside the panel the field always has focus, so every navigation key needs either to be one the caret
has no use for or to carry a modifier: the arrows and `Ctrl+n`/`Ctrl+p` step the results in reading
order, **`Ctrl+hjkl` moves over the grid as drawn** — h and l across the two columns, j and k a whole
row, wrapping within the column — and **Tab and Shift+Tab move between the category chips** (the
user's call, 2026-09-23; it used to be Tab stepping results and `Ctrl+h`/`Ctrl+l` the chips). Tab's
handler still answers the confirmation card first, like every specific key handler. `Ctrl+h` reaching the handler at all depends on
`Keys.onPressed` running before the item: a `TextInput` would otherwise take it as a backspace.

## Wallpapers

`awww` (LGFae's swww) already runs as a user unit and owns the picture. It keeps its own cache of the
last image per output, and its `ExecStartPost` runs `awww restore`, so **nothing in this shell
remembers a wallpaper across a session**. `services/Wallpapers.qml` lists the directory, asks awww
what it is showing, and tells it to show something else.

- The library is `~/Pictures/wallpapers`, listed by a **`FolderListModel`** (`Qt.labs.folderlistmodel`,
  which is in qtdeclarative). Nothing in `Quickshell.Io` lists a directory, and this costs no process
  and notices a file dropped in while the shell runs.
- `awww query` is the only way to ask what is displayed. It prints one line per output ending in
  `currently displaying: image: <path>`, or `color: <hex>` for a daemon that has never been told
  anything. Asking beats remembering, because the wallpaper can be set from a terminal too — so it is
  re-read whenever the launcher opens.
- **qtimageformats is installed**, which is what makes webp, tiff and jp2 thumbnails render; qtbase
  alone reads png, jpeg, gif and ico, and four of the wallpapers here are webp. The plugin is found
  through `QT_PLUGIN_PATH`, which already contains `/run/current-system/sw/lib/qt-6/plugins`, so
  installing the package was the whole change. It is version-coupled: a Qt plugin built against a
  different Qt refuses to load, silently.
- Thumbnails are decoded at the tile's size (`sourceSize.height`), not the file's. Only the height is
  set, so a panorama stays a panorama and still covers the square after `PreserveAspectCrop`. There
  is **no thumbnail cache** — six files do not need one. A library of hundreds would.
- The tile is a **`ClippingRectangle`** (`Quickshell.Widgets`). `Item.clip` is a scissor rectangle
  and would leave a square picture inside a round tile.

## Windows

`HyprlandToplevel` carries `title`, `workspace`, `address`, a `wayland` handle and `lastIpcObject`.
Two things about it are not obvious:

- **`focusHistoryID` is the useful order** — 0 is focused, counting back from there — and it lives on
  `lastIpcObject`, so it is only as fresh as the last `refreshToplevels()`. `services/Windows.qml`
  refreshes when the launcher opens, which is the only moment anything looks.
- **`activated` cannot be trusted**, for the same reason `Hyprland.activeToplevel` cannot: it is
  driven by events a freshly started shell never saw, and reads false for every window until focus
  next changes. Use `focusHistoryID === 0`.

**Focusing a window is a dispatch, and the wayland route does not work.** The foreign-toplevel handle
has an `activate()`, it returns without error, and hyprland simply does not move focus — verified
from a probe with no launcher, no focus grab and nothing else running, so it is the compositor
refusing rather than anything in this shell. What works:

```
hl.dsp.focus({ window = "address:0x57bcbf5d2a20" })
```

`HyprlandToplevel.address` comes **without** the `0x`, which the dispatch needs. And hyprland's lua
errors are worth reading: a wrong argument answers *"hl.focus: unrecognized arguments. Expected one
of: direction, monitor, window, urgent_or_last"*, which is the fastest way to discover this API.

## Power

Three static rows running the design's own commands — `systemctl suspend`, `reboot`, `poweroff` —
through `execDetached`, with no service behind them: there is no state to poll and the command is the
whole of what each row does.

**None of them prompts for a password.** `pkcheck` answers `authorized` for
`org.freedesktop.login1.power-off`, `.reboot` and `.suspend` for this user, because the session is
local and active. If that ever changes, kuori's own polkit dialog is what would appear, on a launcher
that has already closed.

These are the only rows in the shell that cannot be tested by running them. The exec path itself is
the one the app rows use, and `systemctl --dry-run poweroff|reboot|suspend` all exit 0 here, which is
as far as verification can honestly go.

### The confirmation

`modules/ConfirmDialog.qml` is the card the design puts in front of one: the row's own glyph on an
accent tile, its name as the question, its command underneath, Cancel and a button labelled with the
action — so the last thing read before a machine turns off is the words "Power off".

It is drawn by `windows/LauncherWindow.qml` **after** the panel, because a QML sibling declared later
paints on top and the question must sit over the launcher rather than under it. The launcher stays up
behind its scrim, so cancelling puts you back where you were, and clicking the scrim cancels — unlike
the polkit dialog, which has a caller waiting on an answer.

Two things hold it together:

- **The card outlives the answer by one animation.** `pending` clears immediately, so the dialog
  reads the last row from `lastPending` while it fades, rather than emptying itself on screen.
- **A pending question owns the keyboard, and each key is answered where it actually arrives.**
  `Keys.onPressed` is **not** the first handler to see a key — the opposite is true, see the trap
  below — so return, escape, up, down and tab are answered in their own handlers, each of which asks
  whether a confirmation is up first. Only the keys with no handler of their own reach
  `Keys.onPressed`, where the arrows move between the card's buttons and everything else is swallowed
  rather than typed into a field nobody can see behind the card.
- **The keyboard's selected button wears the hover look**, and starts on the action rather than on
  Cancel. Neither is in the design, which has only a mouse: the card says "ENTER to confirm" and
  getting to it took a deliberate return already. Hover and keyboard selection mean the same thing
  here — "this is the one you are about to press" — so they say it the same way.

## The clipboard

`cliphist` is a **store, not a daemon**: nothing is ever recorded unless `wl-paste --watch` feeds it.
Two user units in **their nixos config's `modules/services.nix`** do that — `cliphist-text` and `cliphist-image`, split by type the way
cliphist's own README splits them. The text one runs through a generated script first, because a
password manager marks its offer with `x-kde-passwordManagerHint` and cliphist 0.7.0 has no ignore of
its own; without that filter every password copied would sit in `~/.cache/cliphist/db` in plain text
for the next 750 copies.

What the store does and does not hold, established by probing it:

- `cliphist list` prints `<id>\t<preview>`, newest first. **The ids are a plain counter**, not clock
  values, and there is no timestamp anywhere — hence no "2 min ago" (see the deviations table).
- A binary entry previews as `[[ binary data 26 KiB png 400x229 ]]`, which is where the type and the
  dimensions on an image row come from. There is no filename.
- The preview is capped at `-preview-width`, 100 characters by default, so the true length of a text
  entry is not knowable from the listing either.

The preview pane decodes the **whole** entry, since the list only ever carries that 100-character
preview. Three things keep that cheap: the decode waits 120ms for the selection to settle, so arrowing
through the list does not run a process per keystroke; asking for the same entry twice is free; and an
image is decoded to a **file** rather than through a QML string, because it is bytes. Those files are
named per entry — so switching back costs nothing and no URL ever changes contents under QML's image
cache — and the whole lot is swept at startup, which bounds them to a session.

`services/Clipboard.qml` classifies each line — image, colour, link, text — and the row takes the
design's own glyph for its kind. A hex code gets a **swatch** instead: the tile is painted that colour
with nothing drawn on it, which is the design's own idea and the same `swatch` field name it uses.

Activating a row runs `cliphist decode <id> | wl-copy`, through `sh` because the whole point is the
pipe: decode writes bytes, binary ones included, and those must not pass through a QML string. It puts
the entry back on the clipboard rather than typing it into the focused window — pasting for someone is
a keystroke this shell has no business synthesising.

Two things that bit while building it:

- **Recency has to survive the ranking.** `AppSearch` sorts by name when there is no query, which
  turns a history into nonsense, so a row may carry an `order` and `byName` prefers it. Rows without
  one still sort by name, and the two never mix because the clipboard is out of ALL.
- **A QML singleton is not built until something reads it**, and `DesktopEntries` is one of them: its
  scan does not start until the first read, which used to be the first launcher open of the session.
  The rows arrived with empty tiles and filled in when the scan landed. `shell.qml` now reads
  `DesktopEntries.applications.values.length` at startup for the side effect, beside the same trick
  for `Notifications`. The scan itself is quick once triggered — 8 entries in ~250ms here — so what
  this buys is paying for it while the shell starts rather than in front of somebody who has just
  pressed the launcher key.
- **A QML singleton is not built until something reads it.** `Clipboard` is first touched when
  `LauncherRows` is, which is the first time the panel asks for rows, by which time `Launcher.opened` has already changed and a `Connections` on it
  has missed the signal. The first `cliphist list` therefore runs on creation (`running: true`), with
  the connection covering every open after that. `Wallpapers` has the same shape for the same reason.

## The lock screen

`WlSessionLock` (ext-session-lock) in `windows/LockScreen.qml`, one `LockSurface` per output, and
`services/Lock.qml` holding the flag and everything that decides when to raise it. While the lock holds
hyprland draws nothing else and hands the surfaces the keyboard: it is a lock, not a window on top.

- **Two PAM services, not one.** `/etc/pam.d/kuori` is pam_unix alone and `kuori-fingerprint` is
  pam_fprintd alone, declared by `programs.kuori.lock` in `nix/module.nix`. Both conversations run at
  once. One stack with both — `/etc/pam.d/swaylock` is exactly that — asks pam_fprintd first, and it
  holds the conversation for up to 30 seconds and three tries before pam_unix ever sees the password.
- **The fingerprint line waits for fprintd to speak.** pam_fprintd sends a `PAM_TEXT_INFO` when it is
  listening and a `PAM_ERROR_MSG` per unknown finger, and asks nothing. With nothing enrolled (the case
  on 2026-09-23 — `fprintd-list` says so) it fails at once and silently, so a conversation that ends
  without ever having spoken is not retried until the next lock. One that was listening and gave up is
  started again a second later.
- **A touch raises the prompt.** The fingerprint line is inside the prompt, which is down at rest, so
  a miss shook a line nobody could see and a match unlocked with no "Fingerprint recognised" first —
  the first real test reported the wrong finger as doing nothing at all. The journal showed fprintd
  had answered all along (`Failed to match fingerprint`, as an error): the answer was there, the
  prompt was not.
- **Never abort a finger conversation and start the next one straight away.** `PamContext.abort()`
  SIGKILLs the helper, and fprintd only frees the reader once it sees that client leave the bus. A
  start in the same breath is refused (`Device was already claimed` in fprintd's log) and fails
  without speaking, which looks exactly like nothing enrolled, so it was never retried. Every resume
  did this until 2026-09-25: the wake handler replaced a conversation that was still listening, and
  the finger was dead until the password. Now a live conversation is kept on wake, and `listen()`
  waits `lockFingerRetry` before replacing one. The first test of this ran with only the second
  half loaded: the two edits landed 20ms apart and the shell reloaded once, on the first. The log
  gave it away — the old conversation killed on wake and a new one exactly a second later.
  **After editing a file twice in quick succession, restart the unit** rather than trusting the
  hot reload to have seen the last write. The reader *can* come back stale from a sleep —
  `Device reported an error during verify: transfer timed out` two seconds after resume, then a
  usb reset — and that is what the retry on a conversation that had spoken already covers:
  verified 2026-09-25, finger accepted on the retry four seconds after the lid opened.
- **It refuses to lock without `/etc/pam.d/kuori`.** Built before the rebuild that made the service,
  the idle timer would have locked a machine nothing could unlock. It checks at every lock, not once.
- **A restart must not unlock.** hyprland keeps the session locked when the client dies and, with
  `misc:allow_session_lock_restore` (set in their `looknfeel.lua`), lets the next one take over. But a
  fresh `Lock` starts with `locked: false`, and the new `WlSessionLock` would release what it inherited.
  So the state is in `lock.json` with the boot id, read with **`blockLoading`** in the singleton's
  `onCompleted` — before anything has bound `locked` to a false value it would act on. The same covers
  a hot reload, which rebuilds singletons too.
- **There is no IPC unlock and `Unlock` from logind is ignored.** Either would let any process of this
  user open the lock, which is the one thing a lock is for.
- **Sleep holds a delay inhibitor** (`scripts/kuori-lockd`, the btagent's shape: python3 and jeepney,
  a child `Process`, restarted on exit). On `PrepareForSleep` it asks for the lock and lets go of the
  inhibitor when the shell answers `locked` — which it does off `WlSessionLock.secure`, the compositor
  saying every output is covered — or after 4s, inside logind's 5s `InhibitDelayMaxSec`. It takes a new
  one on the way back up.
- **The shell is not in the session's scope**, so logind's `auto` session and `GetSessionByPID` both
  miss. `XDG_SESSION_ID` reaches the unit through the user manager's environment (uwsm puts it there),
  with the user's `Display` session as the fallback. `SetLockedHint` goes through the same path.
- **The lid is `LidClosed` on the manager**, which emits `PropertiesChanged`. A docked machine does not
  suspend on it (`HandleLidSwitchDocked=ignore`), and locks anyway.
- **The field is focused while the prompt is hidden.** That is how the first key both raises the prompt
  and is typed, as the design has it — and it means nothing above the field may be `enabled: false`:
  a disabled item cannot hold focus, and the first version typed its first keys into the terminal
  driving the test. The field is `readOnly` while PAM thinks, for the same reason.
- **Caps Lock comes from `hyprctl devices -j`**, each keyboard's `capsLock`, asked 80ms after each key.
  Qt reports no lock keys, and the leds under `/sys/class/leds` are the physical keyboard's while keyd's
  virtual one is `main` here.
- **The blur is a `MultiEffect`**, the only one in the shell. What rules it out elsewhere is a
  downsample pyramid held for the life of the session; this one exists only while locked, over a
  picture that does not change, decoded at a third of the screen's width.
- **`hl.dsp.dpms()` with no argument toggles**, and returns `ok` — found by calling it to see whether it
  existed, which turned the screen off. Always pass `{ action = "on" | "off" }`.

```
qs ipc -p ~/.config/kuori call lock now | preview <scene>
```

`preview` draws the surfaces on overlay windows with nothing locked, and its field talks to the real
PAM. That is how every state was looked at, and how the wrong-password path can be tested by typing
with wtype — never test by really locking with nobody at the machine to type the password.

## Qt and Quickshell traps, all hit in practice

- **`target: parent` inside a `Repeater` delegate does not mean the delegate.** An animation has no
  `parent` property of its own, so the name resolves against the delegate's scope and yields the
  delegate's parent -- the `Column` holding every sibling. A per-card entry animation written that
  way animates the whole stack. Give the delegate an `id` and target that. It fails silently: the
  animation runs, on the wrong object.
- **Anything spliced into an `sh -c` script is script.** Every `sh -c` here passes its variable parts
  as arguments instead -- `["sh", "-c", 'cmd "$1"', "sh", value]` -- and quotes `"$1"` inside. The
  values are cliphist ids, slurp geometries and paths out of `user-dirs.dirs`, none of them hostile
  today, and that is exactly the property that stops being true without anyone hearing about it. The
  one exception is `Capture`'s cursor nudge, which is mostly `${...}` parameter expansions and so
  cannot be a backtick literal either; it is concatenated, with a comment saying why.
- **`QQuickShape` derives its own implicit size from its contents** and will fight an
  `implicitWidth`/`implicitHeight` binding. Set `width`/`height` explicitly on any `Shape` whose path
  is written in terms of `root.width`/`root.height`. Symptom: the shape renders at about half size,
  with nothing in the log.
- **A mirroring `Scale` needs both origins set**, even when only one axis is used. With `origin.x`
  left at its default the shape renders as *nothing at all*, identity scale or not.
- **`bottom` is a FINAL anchor line on `Item`** — you cannot name a property that. Same for `top`,
  `left`, `right`, `baseline`. Use `atBottom` or similar.
- **A `Process` that is still running ignores a new `command`.** Setting it and then `running = true`
  does nothing while the last run is alive, and the new command is simply gone. Anything
  fire-and-forget — `notify-send`, `wl-copy`, `hyprctl hyprsunset`, a `cliphist` restore — goes through
  `Quickshell.execDetached`. The one that bit: a recording that fails at once has its "Recording" and
  "Recording failed" notifications race for one `Process`, and the second was lost.
- **`Image.sourceSize` is in logical pixels.** Qt multiplies it by the screen's scale before decoding:
  measured offscreen at `QT_SCALE_FACTOR=2`, `sourceSize.height: 32` decoded within 1% of a 64-pixel
  decode. Three places here doubled it by hand, which decoded four times the pixels on the laptop.
- **`font.pixelSize` is an int and rounds a real half up**: 9.5, 11.5 and 12.5 draw at 10, 12 and 13,
  measured. Theme keeps the design's half-pixel sizes as written, as a record, knowing they round.
- **A property and a function with the same name in one object** compile, pass qmllint and pass the
  compile probe below. `Bluez` briefly had both a `glyph` property and `glyph(device)`; the lint in
  "Verifying UI changes" checks for it now.
- **A window's `visible` bound to its own `screen` loops.** `screen` changes as the surface maps, so
  the binding re-enters itself — `ToastWindow` logged "Binding loop detected for property visible"
  on every toast until the loader handed it the screen's name instead.
- **`Pipewire.defaultAudioSink` can be a stream.** PipeWire stores the default by `node.name`, and
  a filter chain gives its sink and the stream it plays through the same name — the Framework
  Speakers convolver is `audio_effect.laptop-convolver` on both. Quickshell resolved it to the
  stream, fixed at 1.00, so the volume keys (`wpctl`, which resolves to the sink) moved nothing the
  panel or the OSD could see. `Audio.device()` trades a stream for the device of the same name. The
  other fix is a distinct `node.name` on the chain's playback side, in their nixos config.
- **A `Behavior`'s animation never emits `finished()`**. Time the teardown instead. A launcher window
  once stayed mapped forever because it was waiting on that signal.
- **Qt prunes input delivery by the parent's bounds.** A `HoverHandler` on a body wider than its item
  goes dead exactly over the part that overflows. `Notch` sizes itself to its body for this reason.
- **`TapHandler` takes an exclusive grab** that cancels a hover an ancestor is holding itself open
  with. Everything clickable here is a `MouseArea`.
- **`Region.item` masks input only**, never painting — and a Wayland input region gates pointer
  *enter and leave*, so a `HoverHandler` outside the mask never fires at all.
- **`JsonAdapter` cannot hold a variable-length list of records.** Its list elements must be
  pre-declared `JsonObject`s with fixed fields. Use `JSON.parse(fileView.text())` into a
  `property var`. `FileView` can also write (`setText`) and watch (`watchChanges`).
- **A long QML `Timer` runs on Qt's animation driver**, so it keeps the clock ticking at ~16ms rather
  than sleeping until it fires. For a coarse schedule use `SystemClock` (`services/Time.qml`), which
  is a real `QTimer` aligned to wall-clock boundaries.
- **Naming an IPC function `show`** collides with the `qs ipc show` subcommand: the call silently
  lists targets instead of doing anything. It is `open`.
- **`IpcHandler` only registers functions whose parameters and return type are annotated.** An
  untyped function is silently skipped.
- **`DesktopEntries` fills in asynchronously**, one entry at a time from empty, and an imperative
  `byId()` or `heuristicLookup()` call **creates no binding dependency**. A binding that only calls
  the lookup therefore evaluates once against an empty list and keeps its fallback for the life of
  the panel — window rows showed raw class names and a generic glyph for exactly this reason. Read
  `DesktopEntries.applications.values` in the same binding to make it re-run as the scan lands.
- **A variable font axis near its own maximum can render wrong.** Material Symbols' `FILL` axis runs
  0 to 1, and qt draws a glyph near `1` speckled and eaten away — as though the inner contour were
  XORed out of the outer one rather than merged into it. The window is narrow and it goes glyph by
  glyph: `0.998` breaks everything, `0.997` still breaks the bell, and `0.99` is clean but leaves the
  moon's last sliver visibly unfilled at 14px. `Theme.iconAxesFilled` therefore asks for **0.995**,
  which is filled and clean for every glyph in the shell. It looks exactly like a missing or
  substituted icon, which is what sent me looking at the font first: rendering the same names from
  the same file through chromium, where `FILL` 1 is correct, is what proved it was qt.
- **The specific `Keys` handlers fire *before* `Keys.onPressed`, and default to accepted.** Qt looks
  up a per-key signal first (`onReturnPressed`, `onEscapePressed`, `onUpPressed`, `onTabPressed` and
  the rest), and if one is connected it marks the event accepted *before* calling it — so
  `Keys.onPressed` is only reached by keys that have no handler of their own. A guard written at the
  top of `Keys.onPressed` therefore cannot catch return or escape, however early it looks. The
  launcher's confirmation was built on the opposite belief and its return re-activated the row behind
  the card while escape closed the whole launcher. Proved by logging every key that reached
  `Keys.onPressed`: left and right arrived, return, escape, up, down and tab never did.
- **The launcher's window is destroyed on close, and the decoded icons go with it.** Qt's pixmap cache
  only keeps what something still references, so every open re-decoded every theme svg: measured at
  ~600ms of decoding per open, the last icon landing ~700ms after the open, every time. `FrameWindow`
  — the one window always mapped — now holds an invisible `IconImage` per desktop entry at the
  launcher's own size, which is enough of a reference to keep them. One set per screen **scale**, not
  per screen: the cache keys a picture by the size it was decoded at, so two monitors at scale 1 share
  a set and the laptop's scale-2 panel needs its own. Same measurement after: 92ms.
  Nothing draws them; they exist to be held. The visible rows were already arriving at ~200ms either
  way, so what this buys is the rows further down, the ones a query reveals, and 600ms of decoding
  that no longer competes with the frame the launcher is trying to draw.
- **An icon lookup that finds nothing is not cached, and costs ~15ms.** `Quickshell.iconPath` keeps
  what it resolves — a hit is ~8ms once and free after — but a name no theme answers for walks every
  theme directory again on every call: measured at 41ms for five hits, 97ms for five misses and
  **1537ms for a hundred**, all on the gui thread. The launcher asks once per row *and again on every
  delegate the grid recycles*, so a list that scrolls asks the same dead question dozens of times.
  `services/Icons.qml` remembers both answers; the same hundred cost 1228ms once and 0ms thereafter.
  Worth knowing why misses are dear here: `MoreWaita` ships 3787 files and **no `icon-theme.cache`**,
  so there is no index to consult and the lookup is a directory walk.
- **A `git checkout` can hot-reload the shell into a broken state.** Quickshell reloads on any file
  change under the config, and a checkout that removes a file — switching to a branch that does not
  have `services/Calendar.qml` yet, for the instant before a fast-forward merge brings it back — is
  one. The engine built at that instant has no `Calendar` singleton and never re-resolves it, so
  every binding that names it fails with `ReferenceError: Calendar is not defined` and the panel
  draws nothing, with no error at the moment anyone looks. Seen 2026-09-22 16:48, caught half an
  hour later. **Restart the unit after any checkout or merge**, and when a panel is inexplicably
  empty, grep the journal for `ReferenceError` before reading any code.
- **`Component.onCompleted` does not exist on `ShellRoot`** — "Non-existent attached object", and the
  config fails to load, which with `Restart=on-failure` means five restarts and a session with no
  shell. Put startup work in a child object, or in a `Timer` with a zero interval.
- **`FileView.text()` is a function, not a notifying property.** A binding on it reads once and then
  never updates, however often the file is reloaded. Push from `onLoaded` instead.
- **`NetworkDevice.address` is the *hardware* address.** The IPv4 one is not in `Quickshell.Networking`
  at all, and neither is the association's frequency; both come from `nmcli`.
- **`HyprlandFocusGrab` routes the keyboard, not just the pointer.** A grabbed surface receives key
  events with no `WlrLayershell.keyboardFocus` of its own, and asking for one breaks the grab twice
  over: `Exclusive` is a focus change in the same frame, which answers the grab with an immediate
  `cleared()`, and once held it stops hyprland counting a click elsewhere as breaking the grab, so
  click-outside-to-dismiss stops working. See `windows/FrameWindow.qml`.
- **`UPower.displayDevice` is synthetic.** It aggregates the machine's cells, which is what you want
  for a level and a time, but it carries no `nativePath` — so anything that has to reach sysfs must
  find the real battery in `UPower.devices` by `isLaptopBattery`.
- **`UPowerDevice.healthSupported` reads false on this laptop** even though upower's own CLI prints
  `capacity: 69.8%`, and no design-energy figure is exposed to work it out from. `services/Power.qml`
  reads `charge_full` over `charge_full_design` from sysfs instead, which is where upower reads them.
- **`WifiNetwork.signalStrength` runs 0 to 1**, not 0 to 100. Both ladders in the shell are written
  against that, and a fraction compared to 0-100 thresholds silently pins every network at full bars.
- **No `WifiNetwork` carries its frequency**, so the band under each available network comes from one
  `nmcli` read of the whole scan table. Take the band for the network you are *on* from the row nmcli
  stars, not the strongest row for that ssid: a mesh answers to one ssid on both bands at once.

## Notifications

Quickshell owns the D-Bus side — `Quickshell.Services.Notifications` registers
`org.freedesktop.Notifications`, parses the spec's hints and hands QML a live `Notification` per
message. `services/Notifications.qml` keeps two lists: `popups`, the live toasts, and `history`,
plain snapshots. **Nothing else on this machine answers that bus name**, so while this shell is down
notifications are not merely undrawn, they are dropped.

Hard-won details:

- **A notification is destroyed the moment the handler returns unless `tracked` is set.** Everything
  downstream depends on the object still existing.
- **The server must exist before the first notification, not when a panel first opens.** A QML
  singleton is not constructed until something reads it, and a mention inside a function body is not
  a read — so `shell.qml` holds `readonly property int notificationCount: Notifications.history.length`
  purely for the side effect of being one. Same laziness as `Clipboard`'s first listing.
- **History is snapshots, not objects**, because the design gives it no buttons and an action can
  only be invoked on a notification that is still alive.
- **A click on a toast is a read.** `dismiss(key)` — the card's own click and, through
  `activate`, its buttons — forgets the history entry as well as dropping the popup. `dismissAll`
  deliberately does not go through it: sweeping four cards off the screen says nothing about
  having read them.
- **Clearing is total.** `clear()` empties the history *and* dismisses whatever is still on screen,
  because a toast and the history entry behind it are one notification — the design's own CLEAR does
  the same. Nothing tracks "seen" any more: the system tab's bell is accent while there is a history
  and dim once there is not, so the panel's CLEAR is the only thing that puts it out. The bell itself
  only opens the section — it stopped clearing when the design gave do-not-disturb its own switch.
- `transient` is the spec asking not to be kept, so those get a toast and no history entry.
- **Critical urgency never auto-expires**, nor does an `expireTimeout` of 0; anything else takes the
  client's timeout, or the design's 5.2s when it did not ask. Expiry is **one** timer set to whichever
  toast goes first, not a timer per card: a QML `Timer` runs on qt's animation driver and keeps the
  shell awake while pending.
- `expire()` and `dismiss()` are different answers to the client — timed out versus waved away — and
  a client can withdraw its own notification, so each popup connects to `closed` and drops itself.
- **An icon name given to `notify-send` arrives as `image://icon/firefox`** on `image`, ready for
  `Image`. `appIcon` is usually empty.
- The design's second line is one sentence and a notification arrives as two fields, so
  `Notifications.textOf()` joins summary and body with an em dash — which is exactly how the mockup
  writes its Thunderbird row.
- Markup is claimed and rendered with `Text.StyledText`: clients send pango markup whether or not a
  server advertises it, and StyledText understands the subset the spec allows.

The toast surface is the launcher's window turned inside out — **no focus grab, no keyboard focus, no
scrim** — and it is sized to the cards themselves (308px wide, as tall as the stack), so the rest of
the desktop stays live by construction rather than by masking. The design's
`backdrop-filter: blur(10px)` is `BackgroundEffect.blurRegion`, which hands the region to hyprland;
their `decoration:blur` is already on, and no framebuffer of ours is involved.

```
qs ipc -p . call notifications dnd | clear | dismiss
```

DND silences the toasts and nothing else: a muted notification still reaches the history, which is
the only place you would find out it arrived.

## The polkit agent

Quickshell ships `Quickshell.Services.Polkit`, which is an **agent** API, not a client one:
`PolkitAgent` registers with the Authority on `componentComplete()` and hands QML a live
`AuthFlow`. The D-Bus object and the PAM conversation are both done in C++, so the shell only draws
the dialog. Nothing extra is installed; polkit 127's socket-activated
`polkit-agent-helper.socket` is what runs PAM as root, and it is active here.

**`modules/PolkitDialog.qml` never imports the module.** It is handed a `flow`-shaped object and
reads properties off it — `message`, `actionId`, `inputPrompt`, `supplementaryMessage`,
`selectedIdentity` and so on — calling only `submit(value)` and `cancelAuthenticationRequest()`.
That is not decoration: `AuthFlow` is `isCreatable: false` and its `request`/`showError` methods are
**private slots**, so a mock cannot be a real one. `services/Polkit.qml` owns both the mock and
(eventually) the agent, and the dialog cannot tell them apart.

Two things worth knowing about the shape:

- **"Verifying" is not a flag.** A real flow signals work in flight by `isResponseRequired` going
  false while `isCompleted` is still false. The mock does the same rather than inventing a busy
  property the dialog would then depend on.
- **`responseVisible` is not the eye toggle.** It is pam saying whether to echo at all — a username
  prompt does, a password does not. The eye is the user overriding that for their own eyes, so the
  field echoes when *either* is true.

Every state is reachable without touching anyone's password:

```
qs ipc -p . call polkit prompt | busy | error | ok | close
```

The agent is wired up and works: a real `systemctl start ydotoold` raises this dialog, polkit's own
message ("Authentication is required to start 'ydotoold.service'"), the user's real display name, and
the password reaches PAM. Cancel refuses the caller promptly — `Access denied`, exit 4 — rather than
leaving it hanging.

**hyprpolkitagent is gone from the system entirely** — unit and package both, removed once the shell
proved it could hold the role across a login. The ordering mattered on the way there: while nothing
started the shell at login, dropping hyprpolkitagent would have left a fresh session with no
authentication agent at all. The unit came first, disabling it second, removal last.

The package had to go with the unit. `environment.systemPackages` puts a complete unit under
`/run/current-system/sw/share/systemd/user`, which is on the user manager's `UnitPath`, plus a D-Bus
activation file for `org.hyprland.hyprpolkitagent` naming that same unit. Nix's `enable = false`
generates an **empty** unit in `/etc/systemd/user`, and that file shadowing them was the only thing
keeping either out of reach. Removing the declaration alone would have uncovered both.

The escape hatch, if the shell ever fails to start and takes the session's only agent with it, is
**`pkttyagent`** — polkit's own terminal agent, which comes with polkit and needs nothing installed.
Run it in one terminal and the prompt appears there; the privileged command goes in another.

Only one agent can register per session, which is why there is now exactly one on the machine.
Registration failure is quiet by design: `isRegistered` stays false and emits nothing, so the flag
alone cannot report it. Quickshell logs the reason itself — *"An authentication agent already exists
for the given subject"* — which is what a second shell instance would produce.

## Capture

Screenshots are **grimblast**, which already knows how to select a region, find the active window,
copy and save in one go, and — at lines 47-50 of its script — reads `~/.config/user-dirs.dirs` for
itself. So a capture lands wherever every other tool on the machine would put it, and this shell
needs no opinion about that. The design's targets map straight on: Region → `area`, App → `active`,
Monitor → `output`.

**The three targets are one grimblast verb with three different sets of boxes.** `area` feeds slurp
every window as a selectable box *unless told otherwise*, and takes `SLURP_RECTS` and `SLURP_ARGS`
from the environment for exactly this:

| Target | What it passes | What you get |
|---|---|---|
| Region | `SLURP_RECTS=""` | no boxes: a free drag over a clean veil |
| App | `SLURP_ARGS=-r` | grimblast's own window boxes, and only those are selectable |
| Monitor | `SLURP_RECTS=<one box per monitor>`, `-r` | pick a screen — or, with one monitor, no picker at all and a straight `output` shot, because asking which is silly when there is no choice |

Without `SLURP_RECTS=""` a region drag happens over a screen covered in window outlines, which is
what "the overlay looks wrong" turned out to mean. Monitor boxes are built from `Hyprland.monitors` and
divided by `scale`: hyprland reports a monitor in physical pixels and slurp works in layout ones.

**The colour picker is hyprpicker, asked for hex whatever the format.** The swatch needs a colour QML
can parse and one pick has to answer both it and the value, so `hyprpicker -f hex -q` runs once and
`ColourPicker.formatted()` derives rgb and hsl from Qt's own colour, which carries HSL. The picker is
its own service, `services/ColourPicker.qml`; it shares the capture button, so its flash and its
notification still go through `Capture`. The clipboard is
written here rather than with hyprpicker's `-a`, because what lands there must be the string the panel
is showing. A picked colour then reappears in the clipboard history as a colour entry with a swatch,
which is the classifier in `services/Clipboard.qml` doing its job.

Two things about hyprpicker itself, both of which made it look as though nothing had been picked:

- **`-q` silences the colour, not just the logs.** It prints the value through the same logger, so
  `--quiet` means it prints nothing at all and the pick does nothing. Its logs go to stderr anyway.
- **It only learns where the pointer is from motion events after its overlay is up.** Click without
  moving first — to take the colour already under the cursor, which is a reasonable thing to want —
  and it has no position and answers `#000000`. `Capture` therefore nudges the pointer one pixel and
  straight back once the overlay exists: the move away is the event it needs, the move back is what
  makes the answer the pixel that was under the pointer rather than its neighbour. Verified both
  ways; without the nudge a still pointer picks black, with it the answer is exact.

And `-b`, because otherwise the value arrives wrapped in ANSI truecolor escapes.

The design's example reads `hsl(219, 88%, 72%)` for `#7aa2f7`; the computed answer is
`hsl(221, 89%, 72%)`, and that one is right — by hand the hue is 220.8° and the saturation 88.7%. The
design's numbers there are mock data, not a specification.

**`slurp` blocks forever on a stdin that is an open pipe**, which is what `Process` hands it. It reads
its list of selectable boxes from there, so it waits for a list that never comes: the process runs,
maps no surface, dims nothing, and the screen looks untouched while a capture is supposedly in
progress. `stdinEnabled: false` does **not** help — the pipe is still there. Every bare `slurp` here
therefore runs as `sh -c "exec slurp < /dev/null"`; the ones fed boxes are already behind a shell
pipeline, which closes stdin for them, which is why this only surfaced when region stopped going
through grimblast.

**slurp shows a crosshair only if it can load one.** It asks its cursor theme for `crosshair` and
silently keeps the compositor's own pointer if there is none. `XCURSOR_THEME` was unset — hyprland
draws a built-in cursor and needs no theme — so slurp looked for a theme called `default`, which does
not exist here. It is now set to `Adwaita` in their `~/.config/hypr/envs.lua`, so nothing in this
shell has to carry a cursor variable. uwsm finalises `XCURSOR_THEME` into the systemd user
environment, which is how it reaches kuori's own children; a change there needs a re-login, or
`systemctl --user set-environment` to take effect before one.

**And grimblast always passes `slurp -o`** — "select a display output". With boxes to choose from that
is harmless, and for picking a monitor it is exactly right. With *no* boxes it is ruinous: the whole
output becomes the selection the moment the pointer moves, and slurp draws a selection by not dimming
it, so the veil vanishes and you are dragging blind. That is why a free-form region cannot go through
grimblast at all and runs `grim -g … | tee <file> | wl-copy` itself.

Things learned the hard way here:

- **`--notify` is deliberately not used.** grimblast announces itself as `$(basename $0)`, which under
  nix is `.grimblast-wrapped`. It prints the path it saved to on stdout instead, so
  `services/Capture.qml` sends the notification itself, as `kuori`, passing the file as the image so
  a screenshot is its own thumbnail. It goes through `notify-send`, which comes back through this
  shell's own notification server — the server has no API for emitting one.
- **Its exit codes carry meaning**: 0 saved, **1 cancelled** (slurp closed without a selection, which
  is the ordinary way out and says nothing), 2 the lock — a second capture while one is still
  selecting.
- **The panel has to close first**, and not only because it would be in the picture: slurp cannot have
  the pointer while the notch is holding a focus grab. `Theme.capSettle` is that wait.

Recording is **wf-recorder**, which knows none of the above and is told everything:

- **SIGINT, never SIGTERM.** `Process.signal(2)` is what makes it finalise the file; killed any other
  way it leaves nothing usable. Verified by doing it both ways.
- **Hardware encoding is asked for only when a driver is actually loadable**, because wf-recorder
  **exits** rather than falling back: `-c h264_vaapi` against a broken VAAPI connection means no
  recording at all. `Capture.accelerated` decides by listing `/run/opengl-driver/lib/dri` for
  `iHD_drv_video.so` — one `FolderListModel`, no process — and the recording's notification says
  which encoder it got. **That check is resolved when the service is built**: `/run/opengl-driver` is
  a symlink a rebuild swaps, and a shell already running keeps watching the directory it resolved at
  startup. A driver installed mid-session is therefore noticed at the next `systemctl --user restart
  kuori`, which is exactly how this was first seen — the notification still said software with a
  working driver on disk.
- **A VAAPI driver in `environment.systemPackages` does nothing.** libva loads from
  `/run/opengl-driver/lib/dri`, and only `hardware.graphics.extraPackages` puts anything there. That
  is why the check above asks where the driver *is* rather than whether the package is installed —
  the two are different questions and only one of them matters.
- **Timestamps must be local.** `toISOString()` is UTC, and a recording named three hours before it
  happened is a file you cannot find again. `Qt.formatDateTime` is local.
- Region recording needs a geometry, so `slurp` runs first as its own process and the recorder starts
  in its `onExited`. Hyprland reports a window in the same layout coordinates `-g` wants.
- The recorder is a `Process` this shell owns, so **restarting the shell ends a recording**.

```
qs ipc -p . call capture region | app | monitor | record <target> | stop
```

## Features whose daemon is missing

hyprsunset and awww are the machine's daemons, not this shell's — they are useful without kuori,
so they stay in the user's nixos config rather than the flake — and kuori cannot assume either is
there. `Display.available` and `Wallpapers.available` say whether they are, and the UI goes through
`Theme.shows(available)`, so `Theme.unavailableFeatures: "show"` gets the old draw-regardless
behaviour back from one place.

- **Ask the daemon, not the filesystem.** hyprsunset **leaves its socket behind** when it stops, so
  `test -S` says it is up while `hyprctl hyprsunset temperature` answers `Couldn't connect … (3)`.
  That query is the probe: exit 0 is a live daemon. awww does remove its socket, but `awww query`
  exits 1 without the daemon and is already being run, so its exit code is the answer.
- **`FolderListModel` does not list sockets**, which is why this is not a watched directory like
  `Capture.accelerated`. Measured: it finds `hyprland.log` in hyprland's instance directory and
  not `.socket.sock` beside it — qt calls a socket a "system" entry.
- **hyprsunset is asked on the minute tick and when the display section opens**; awww only when the
  launcher opens, the one thing that shows it. The first answer is false, so a feature appears a
  beat late rather than being offered and withdrawn.
- **The night light re-applies on arrival.** A restarted hyprsunset comes back at identity with a
  6000 it is not applying, and the switch used to go on saying "Warm 4200K" over an unwarmed
  screen. Now `apply()` does nothing while the daemon is down and runs when it appears.
- **`Launcher.requested` is what an open asked for.** A category not on offer opens on ALL, but the
  query that finds awww back lands just after the open that wanted it, so the launcher moves there
  when `categories` changes. `toggle` has to pass `open()` the original argument, not the resolved
  one, or `requested` is always ALL.
- **The clipboard is deliberately not gated** (the user's call): an empty history already says
  there is nothing, and cliphist's watchers could only be found by scanning processes.
- Stopping and starting `awww-daemon` to test this used to leave every screen black: its
  `ExecStartPost` ran `awww restore` before the daemon had a socket (`Broken pipe`). Their nixos
  config now polls `awww query` first (fixed 2026-09-24); if a screen is black anyway, `awww restore`.

## The display section

`hyprsunset` owns the colour temperature and runs as a user unit from login with **`-i`**, the
identity matrix: present to be talked to, changing nothing. Without `-i` it applies its own 6000K
default at every login, which is a colour shift nobody asked for. `hyprctl hyprsunset temperature <K>`
and `hyprctl hyprsunset identity` are the two commands, sent as a `Process` — not through
`Hyprland.dispatch`, which would only be asking hyprland to run the same thing.

**hyprsunset cannot be asked whether it is applying anything.** After `identity` it still reports the
last temperature it was given, so `services/Display.qml` is the only record of whether the night light
is on. That record is written to `Quickshell.statePath("display.json")` and re-applied on load —
verified by restarting the daemon (fresh, it reports its 6000 default) and then the shell, after which
it reports the saved value again.

A drag moves the slider every frame, so the daemon and the state file get the value it **settles** on,
120ms later, rather than every value it passed through. The reading on screen still follows the knob,
because that reads the property rather than the daemon.

`IdleInhibitor` (`Quickshell.Wayland`) is a property of a *surface*, not of a session, so it hangs off
`FrameWindow` — the one window this shell always has mapped — while the flag it follows lives in the
service where the switch can reach it. Whether the inhibit is actually taken is not observable from
outside the compositor; nothing in `hyprctl` reports it.

**It is also the only idle inhibit the lock hears.** `IdleMonitor.respectInhibitors` means the wayland
idle-inhibit protocol, and nothing else. Applications that ask over d-bus — `org.freedesktop.ScreenSaver`
directly, or the portal's `Inhibit`, whose gtk backend forwards an idle inhibit to that same name —
found nobody owning it: `proxy is for the well-known name org.freedesktop.ScreenSaver without an
owner` in the journal, and the request dropped, so a video playing in one could be locked over.
`scripts/kuori-screensaver` owns the name (the btagent's shape again) and reports who holds what;
`Display.inhibited` is the switch or any holder, and is what the inhibitor and the toggles glyph
follow. `awake` stays the switch alone, so an application letting go never leaves it thrown.

- **A hold ends when its owner leaves the bus**, not only on `UnInhibit`, or a crashed player keeps the
  machine awake until the shell restarts. The portal passes an empty application name and holds on
  behalf of its caller, releasing when that caller goes — checked 2026-09-24.
- **The name is requested queued**, not `DO_NOT_QUEUE`: with hypridle or a second shell holding it,
  exiting would respawn the helper every five seconds for nothing.
- `Theme.appInhibit: false` still answers every call and ignores it, so the portal's log stays quiet.
- "Inhibiting other than idle not supported" from the portal is a caller also asking to block logout
  or suspend. That is refused whatever owns the name, and is harmless.

The old `modules/BrightnessRow.qml` is gone: the design folded brightness into this section, and its
glyph-slider-reading shape became `components/DisplaySlider.qml`, which the temperature row uses too.

```
qs ipc -p . call display night | awake | temperature <K>
```

## The backlight

Quickshell has no module for it, so `services/Backlight.qml` is sysfs both ways. `acpilight` is
enabled and this user is in the `video` group, which makes
`/sys/class/backlight/<device>/brightness` `root:video rw-rw-r--` — so the shell writes the file
itself. Before that it went through `brightnessctl` and logind, which cost a process per step of a
drag plus the coalescing to stop those piling up; one line of nix removed all of it.

Three things the write needs:

- **`atomicWrites: false`.** An atomic write is a write to a temporary followed by a rename, and
  nothing can be renamed over a sysfs attribute.
- **`blockWrites: true`.** Five bytes to a kernel attribute, so blocking costs nothing and the write
  has landed before the poll below could ask about it.
- **Errors left visible.** `printErrors` stays at its default, because a write that starts failing —
  a regressed udev rule, a group dropped — should say so rather than look like a dead slider.

`brightnessctl -m` survives for one thing only: naming the device and its maximum. The file has to be
named before it can be read, and nothing in `Quickshell.Io` lists a directory. It now runs at startup
rather than when a panel first asks, because the watcher below cannot name the file until it has.

**The kernel does report a backlight change, through udev.** This service polled every two seconds
while the panel was up until the OSD needed to know promptly and always; now one process sits on
`udevadm monitor --udev --subsystem-match=backlight` and reloads the file per event. Measured 13 to
55 ms from the change to the line, and it is line buffered through a pipe, so no `stdbuf` is needed.
It catches every change whoever made it — the function keys, `brightnessctl` in a terminal, this
shell's own slider — which is why the OSD needed no change to their hyprland binds. A reload after our
own write costs a read and reports the value `set()` already published, so it raises no display.

`udevadm` is systemd's own and on the unit's PATH. Nothing about this needed installing.

**brightnessctl's percentages are a curve, not a share of the range.** `-e4` moves 5% along a gamma-4
perceptual scale, so from 56% their brightness keys stepped to 44, 34, 26, 19 and 14 — every press a
different amount of the number the panel and the OSD report, which is what "the steps feel arbitrary"
turned out to mean. `Backlight.step()` moves `stepSize` of the real range instead, and the keys are
bound to `qs ipc call backlight up|down` so one press is one step of the scale the readings are on.
It stops at `floorLevel`, 1%: the slider may still go to nothing, because that is done deliberately
while looking at it, but a key held one press too long should not leave a black screen and no way to
see the way back.

## The on-screen display

The volume and brightness keys are hyprland's binds and run `wpctl` and `brightnessctl`, so **nothing
tells this shell a key was pressed**. `services/Osd.qml` watches the two values instead — pipewire
pushes volume and mute, udev pushes brightness — and shows whichever moved. That is why the feature
needed no keybind changes, and why it also answers a change made from a terminal.

- **A service's first reading is a change like any other.** There is no sink at startup and no
  backlight probed yet, so both values arrive late and would throw the display up at login. The
  service keeps the last value it saw and treats the first one as something to record, not report.
- **Not while the system panel is open**, and it goes away if that panel opens under it. Not in the
  design, which draws it over the panel at z-index 60; but the panel is showing those same sliders and
  a box over them says nothing new. This also covers dragging the panel's own slider, which would
  otherwise throw a display over the thing being dragged.
- **It does not replay its drop-in on every step.** The design re-keys the element on each change, so
  its animation restarts; with a held key repeating that is a box bouncing ten times a second. Here it
  drops in once and the bar and the reading follow while it is up.
- The design's OSD buttons at the bottom left are a mock affordance, like the launcher's trigger
  button, and are not built.

`modules/OsdBox.qml` is the box, named that way because `services/Osd.qml` has the plain name and a
window importing both modules could not say which it meant — the collision `services/Bluez.qml` is
named around.

It hangs off the system tab and is **wider than the strip**, which is what `Notch.hangHeight` is for:
the tab squares off the corner they share and moves the fillet where it meets the side border down
past whatever hangs, and a second fillet in the tab's own colour rounds the inside corner where the
strip meets the wider box. Its shadow is declared with the tabs' own, before the frame, because it is
flush against the side border and a shadow drawn after the frame would smear down the band.

## Effects and cost

`RectangularShadow` (QtQuick.Effects) is **analytic**: an `Item` wrapping one `ShaderEffect`, one
quad drawn straight into the scene graph, no framebuffer, nothing dirty while idle. Measured: six of
them versus none made no difference to idle CPU or RSS.

`MultiEffect` holds a source proxy plus a list of blur effects — a downsample pyramid of render
targets *per instance*. `Qt5Compat.GraphicalEffects` is worse still. Neither belongs in this shell.
`RectangularShadow` only does rounded rectangles, so a non-rectangular shape gets no glow (see
`FocusMark`).

## Hyprland state: two fixes worth remembering

`Hyprland.activeToplevel` is driven off `activewindowv2`, which only fires when focus **changes**. On
a freshly started shell it is null and stays null — on a one-window desktop, for the whole session.
`services/FocusedWindow.qml` falls back to the refreshed snapshot's `focusHistoryID === 0`.

`refreshToplevels()` at startup runs **before** this shell's own reservation windows have claimed
their edges, so it reads the layout from before everything reflowed — a window five px wider and
thirty higher than it ends up. Hyprland emits no event for that reflow, so there is a second
"settle" refresh after a delay.

## Environment

- Fonts: `"JetBrainsMono Nerd Font"` — the plain name `"JetBrains Mono"` does **not** resolve and
  silently falls back to DejaVu. `"Manrope"` is installed, but it is one variable file whose default
  instance is **ExtraLight**, so weight must be pinned through `font.variableAxes`
  (`Theme.uiAxesSemiBold`), not just `font.weight`.
- `Glyph.nudge` defaults to **0** and that is calibrated, not arbitrary. It sat at `-0.5` uncalibrated
  for a long time, lifting every glyph most of a device pixel above the text beside it.
- Apps launch through **uwsm** (`uwsm app -- <id>.desktop`), matching the rest of their session. It
  expands Exec field codes and `Terminal=true` itself, so nothing here needs to know about terminals.
- Icons need an installed **icon theme**; Qt's lookup reaches nothing without one and every row falls
  back to a letter. Adwaita and MoreWaita are present now.
- The monitor is 2880x1920 at scale **2** as of 2026-09-23 (it was 2560x1600 at 1.6 before), so
  one logical px is 2 device px. Geometry checks must convert — ask `hyprctl monitors` rather than
  trusting this line.
- The shell runs as a **systemd user unit**, declared by this repo's `nix/module.nix` and switched on
  in their nixos config (`~/work/personal/nixos`) with `programs.kuori` — see *The flake*. So
  **restart it with `systemctl --user restart kuori`** — not
  by killing it and relaunching, which would leave systemd's copy running and stack a second instance
  on top (each one claims its own exclusive zone, and the reserved edge reads as a multiple of the
  real value). `journalctl --user -u kuori -f` follows the output; `kuori log` still works.
  `Restart=on-failure` is there because a crashed shell now means a session with no
  authentication agent.
- **A unit gets systemd's minimal PATH**, not the session's — coreutils, findutils, grep, sed and
  systemd, and nothing else. Started from hyprland the shell inherited the whole session PATH, so
  every `Process` and `execDetached` here was written against it: `uwsm` (launching an app), `nmcli`
  (the wifi band and the IPv4 address), `brightnessctl` (naming the backlight) and `ping`. All four
  stopped resolving the day the unit landed, and **every one of those failures is silent** — the
  launcher simply stops launching, with nothing in the log. The unit therefore sets
  `PATH=/run/wrappers/bin:/run/current-system/sw/bin`, and the wrapper puts the package's own tools
  ahead of it. Anything new the shell shells out to goes in `runtime` in `nix/package.nix` if it
  talks to no daemon, and is left to the system if it does.

## The flake

`flake.nix` exports the package, an overlay, `nixosModules.default` (`programs.kuori`) and a dev
shell. The rule for what is in the module is the user's: **only what is no use without kuori.** The
unit, the calendar timer, the two PAM services, the fonts Theme names. Hyprland, the wallpaper, night
light and clipboard daemons, xdg-user-dirs, bluetooth, upower and the rest stay in their nixos
config, because they are useful under niri or a hyprland without kuori; kuori hides what it cannot
drive instead (*Features whose daemon is missing*).

- **The module builds the package from the consumer's `pkgs`**, not the flake's nixpkgs.
  qtimageformats has to be the same Qt as quickshell or it refuses to load, silently, and it saves a
  second nixpkgs besides.
- **The wrapper bundles tools that talk to no daemon** — python with jeepney, grim, slurp,
  grimblast, wf-recorder, hyprpicker, libnotify, wl-clipboard, brightnessctl — **and nothing that
  does.** awww's client must speak its daemon's protocol version, cliphist's must read the watchers'
  db format, so those come from the system PATH, as do hyprctl, nmcli, uwsm and ping.
- **`programs.kuori.configDir`** is `"~/.config/kuori"` here, so the unit runs the checkout and QML
  edits hot-reload as before; a rebuild is only needed when `nix/` changes. `null` runs the store
  copy.
- **A store copy is served from `/etc/kuori`, not its store path.** Quickshell finds an instance
  through `$XDG_RUNTIME_DIR/quickshell/by-path/<hash of the literal config path>`, a symlink to
  `by-shell/<shell id>`. A store path changes with every rebuild, so a bind rebuilt against the new
  one would find nothing while the old shell still ran. `/etc/kuori` is the same on every
  generation.
- **`//@ pragma ShellId kuori`** in `shell.qml` fixes the state and cache directories at
  `by-shell/kuori` whatever path the shell runs from. **It does not fix ipc** — checked: a second
  copy of the tree answers `No running instances` with the pragma in place, because the lookup is
  by path first. Adding it moved `display.json` and `lock.json` out of
  `by-shell/b9825fbcc2dbe70fd4817691dcd59a2f/`; they were copied across by hand.
- **A changed user unit is restarted on switch** (`restartIfChanged` defaults to true), so a store
  copy is live after `nixos-rebuild switch` with no restart by hand. In store mode that is every
  rebuild that touches the package; with `configDir` it is only when the wrapper changes.
- `nix flake check` builds the package and evaluates the module into a throwaway system, building
  the units and the pam file it writes — no VM, no whole system.
- Until the branch is merged, their nixos config points at
  `git+file://…/kuori?ref=nix-flake`. After the merge it is `github:syvanpera/kuori`, and
  `nix flake update kuori` is how a change here reaches the system.

## Verifying UI changes

**ImageMagick is installed; python3 is not** on the system PATH any more (removed 2026-09-24 once the
flake bundled its own for the helpers — `nix develop` has one with jeepney). `magick` is the quickest
way to sample or compare pixels now; the hand-rolled node PNG decoder still works and needs no
dependency, but reach for `magick` first.

- `grim -g "<x>,<y> <w>x<h>"` crops natively, in **Hyprland layout coordinates** — `eDP-1` sat at
  `512,1472` for a long time and is at `0,0` as of 2026-09-23; read it from `hyprctl monitors`.
- Rendering a region as an ASCII map, one character per device pixel, still beats squinting at a
  screenshot.
- For "did this render at all", **diff two captures** (feature on versus off) so the wallpaper cancels
  out — and **restart the shell between them** rather than trusting hot-reload timing.
- For sub-pixel questions, weight each pixel by its distance from the background and take the
  centroid. A binary threshold flips antialiased edge rows and will report a real half-pixel shift as
  no change.
- Driving input. Three tools, and only one of them needs a daemon — reach for them in this order:

  - **Pointer movement**: `hl.dsp.cursor.move({ x, y })`. Hyprland moves its own cursor, no daemon.
  - **Keyboard**: `wtype` — it speaks `virtual-keyboard-unstable-v1` straight to the compositor, so
    it needs no daemon and no privileges. Hyprland's `sendshortcut` and `sendkeystate` dispatchers
    are a second option. **Never use ydotool for keys**; it was only ever habit.
  - **Pointer buttons**: `ydotool`, and only here. Hyprland 0.56.2 has no click dispatcher — its
    dispatcher list runs `movecursor`, `movecursortocorner`, `sendshortcut`, `sendkeystate` and the
    window ones, with nothing that presses a button — and `wtype` is keyboard only. Clicks and
    press/move/release drags are the only reason the daemon is ever needed.

  **Starting it costs the user a password.** The daemon is the **system** unit and does not autostart:

  ```
  systemctl start ydotoold          # hyprpolkitagent prompts them, on their screen
  YDOTOOL_SOCKET=/run/ydotoold/socket ydotool click 0xC0
  systemctl stop ydotoold           # prompts again
  ```

  Not `--user`, and no `sudo` — polkit is what makes this work without a password in the terminal.
  The socket is `/run/ydotoold/socket`, `root:ydotool 0660`, and the user is in the `ydotool` group,
  so no membership of `uinput` is needed or wanted any more.

  **So batch the clicking.** Each start and each stop puts a dialog in front of them, and the
  authorisation is not cached between the two. Start once at the beginning of a round of click
  testing, do every click in that one lifetime, stop at the end — do not wrap start/stop around each
  individual test. And they have to be **at the machine**: with nobody to answer, the command simply
  blocks.

  Unlike the old user service, this one **removes its socket on stop**, so the socket's presence is a
  reliable liveness check.

  **A warp inside a surface sends it no motion.** `hl.dsp.cursor.move` into a surface delivers
  `wl_pointer.enter` with a position, so a hover from outside works; a second warp within the same
  surface delivers nothing, and qt only hears where the pointer went when it next leaves. The strip
  tooltips looked stuck on the first icon for exactly this reason — the logs showed the next icon's
  enter arriving at the moment the pointer left the frame. Hovers across one surface need a real
  pointer, or ydotool.

  Never synthesise **Escape**: it lands in the terminal, not the shell, and kills the session driving
  the test. To prove a key reaches a surface, log an inert one (F13) instead.

**Compile every file without starting anything.** A scratch config whose `shell.qml` imports all five
`qs.*` modules — the scanner registers only what the root imports, and it does not follow symlinked
directories, so the tree is copied in — and on a zero timer calls
`Qt.createComponent(url, Component.PreferSynchronous)` for every file, printing `errorString()` for
each that fails, then `Qt.quit()`. Run it with `qs -p <dir>/shell.qml`. Nothing is instantiated, so
no singleton, helper, agent or reservation window ever starts beside the real shell. It catches
unknown types, unknown properties and bad imports, and misses everything that only happens when a
binding runs: a `ReferenceError` from a renamed id, `root.x` for an `x` the component does not have.
For those, two greps are worth running over every file — lowercase `name.member` where nothing in the
file defines `name`, and `root.member` where neither the file nor the repo component it extends
declares `member` — and then the branch itself, in the real shell, with the journal open: the
polkit DETAILS table came up empty for exactly that reason, and only a run showed it.

`qml` with `QT_QPA_PLATFORM=offscreen` answers rendering questions without touching the desktop. It
swallows `console.*`, so report a number through `Qt.exit(n)`, or `grabToImage` to a file and
compare with `magick`.

Screenshots have repeatedly misled me in this repo. Assert on state the shell logs where you can, and
use screenshots for appearance.

## The calendar

Google Calendar, through the API, synced to a file. The decisions and why:

- **A fetcher of its own, not a `Process` in the shell.** `scripts/kuori-calendar` runs on
  `kuori-calendar.timer` (every 15 minutes, and a minute after login, declared by `programs.kuori.calendar` in `nix/module.nix` — it was missing until 2026-09-23, and nothing had ever synced) and
  writes `~/.cache/kuori/calendar.json`. `services/Calendar.qml` reads that file and nothing else.
  The OAuth tokens and their renewal never pass through QML, a shell restart fetches nothing, and
  offline is a stale file rather than an empty panel. **`Quickshell.cachePath` could not be the
  path**: it is `~/.cache/quickshell/by-shell/<id>/`, named after the shell instance, which a unit
  outside the shell has no way to compute. The fetcher honours `$CACHE_DIRECTORY` and
  `$STATE_DIRECTORY` from systemd and falls back to the xdg names from a terminal.
- **Per-calendar colour was this shell's deviation for half a day.** It was the user's call against
  a design that drew every dot in accent, and on the afternoon of 2026-09-22 **the design adopted
  it**: a dot per calendar on a day (gap 1.5px), a 2px bar in the calendar's colour at the start of
  each event row, and a legend of calendars under the list. All three are built. `Calendar.list`
  is the calendars in the file's order, which is the order the legend reads and the dots come in.
  The legend's Flow wants 11px across and 4px down and a `Flow` has one spacing, so each item
  carries the row gap under it and the wrapper takes the last one back off.
- **The API, not vdirsyncer.** Google's CalDAV needs the same OAuth client, and `.ics` files would
  still need recurrence and timezone expansion — khal, or Python calendar libraries — before a day
  grid could use them. `singleEvents=true` has Google do it. The comparison was re-opened once
  python3 was installed, as the old note here asked, and this is where it landed: one stdlib file
  against two packages plus an interactive setup.
- **Accounts, plural.** Consent and refresh tokens are per Google account, so the credentials file
  is `{ accounts: { personal: {...}, work: {...} } }`, each with its own client id and secret. One
  client can serve both, but a Workspace admin may block an unverified or in-testing third-party
  app, and the way round is a client created in the work account's own project as an *Internal*
  app — hence the client is stored per account. Calendars are deduplicated by id across accounts
  and events by `(calendar, id)`, because a calendar shared into both accounts arrives twice. One
  account failing is logged and the others still write the file; only every account failing
  leaves it alone.
- **`FileView.watchChanges` does not survive the fetcher's rename.** The file is written to a
  temporary and `os.replace`d, and the watch follows the old inode: rewriting, deleting and
  recreating the file under an open panel reloaded nothing, proved on 2026-09-22. So the reads are
  explicit — at startup, on every open of the tab, and after each run of the fetcher — and
  `blockLoading` is on so the staleness test that follows the read sees what the timer last wrote
  rather than what this shell last read.
- **Opening the tab pokes the unit** when the file is older than `Theme.calSyncStale`, through
  `systemctl --user start kuori-calendar.service`, which on a oneshot **waits for the run**, so the
  `onExited` reload reads what it just wrote. Before the unit exists that is exit 5 and a warning
  in the log, nothing more. The panel pushes `Calendar.watching` with a `Binding`, the
  `Network.detailed` shape.
- **A failed load clears the data.** Without it a deleted file left the previous read flagged as
  ready and the panel said "No events" about days it no longer knew anything about.
- **All-day dates must not go through `new Date("2026-09-23")`**: that is utc midnight, which
  east of Greenwich is still the 22nd. `Calendar.localDate` splits the string. Google's all-day
  `end` is exclusive, so a one-day event ends tomorrow and the fold into `byDay` runs to `< end`.
- **Qt's JavaScript has `??` but not `??=`**: `days[k] ??= []` is `Unexpected token '='` and the
  whole config fails to load, which under `Restart=on-failure` is five restarts and a session with
  no shell and no polkit agent. `reset-failed` before the restart that fixes it.
- **The `calendar` IPC target** exists so the tab can be opened from a keybind and from a test;
  before it, opening the calendar meant a click, which meant ydotool and a password.

```
qs ipc -p . call calendar toggle
```

What was **not** verified by doing it, as of 2026-09-22: a real sync against Google (the user has
to create the OAuth client and consent first), the timer (needs their rebuild), and clicking a day
(needs ydotool). The panel was exercised with a hand-written `calendar.json`: dots in two colours,
the dark dot on today, the all-day dash, `+2 more`, both "Not synced" texts, the reload on open and
the poke on a stale file.
