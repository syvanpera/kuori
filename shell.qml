import Quickshell
import Quickshell.Io
import qs.services
import qs.windows

ShellRoot {
  id: shell

  Variants {
    model: Quickshell.screens

    DesktopShell {}
  }

  // this is a read, and it is here for the side effect of being one: a QML
  // singleton is not constructed until something reads it, and mentioning it
  // inside a function body does not count. the notification server has to be
  // holding org.freedesktop.Notifications from startup -- not from whenever a
  // panel first opens -- or every notification before that is lost.
  readonly property int notificationCount: Notifications.history.length

  // the same trick again, for a cost you can watch: `DesktopEntries` is not
  // scanned until something reads it, and until this line the something was the
  // first launcher open. So the first open of a session waited for the scan, and
  // the rows sat there with empty tiles until it landed. Reading it here moves the
  // scan to startup, where nobody is looking.
  readonly property int applicationCount: DesktopEntries.applications.values.length

  // one launcher for the whole session, on whichever monitor has focus, so it
  // hangs off the root instead of off Variants.
  LauncherLoader {}

  // and one authentication dialog, for the same reason.
  PolkitLoader {}

  // and one stack of toasts, which exists only while something is in it.
  ToastLoader {}

  // the shell's only external entry point. hyprland cannot talk to a quickshell
  // window, so the keybind shells out to `qs ipc call`. it lives here rather than
  // in the singleton because the reload hook belongs in the root tree, and because
  // referencing Launcher from here is what constructs the singleton at startup
  // instead of on first use.
  IpcHandler {
    target: "launcher"

    // IpcHandler only exposes functions whose parameters and return type are
    // annotated. an untyped function is silently not registered.
    function toggle(): void {
      Launcher.toggle("all")
    }

    function open(): void {
      Launcher.open("all")
    }

    function close(): void {
      Launcher.close()
    }

    // one function per category rather than one taking the name, so a hyprland
    // bind is a fixed string with nothing to mistype and `qs ipc show` lists
    // everything that can be bound. each toggles: the same bind twice opens and
    // closes, a different one switches category without closing.
    function apps(): void {
      Launcher.toggle("apps")
    }

    function wallpapers(): void {
      Launcher.toggle("wallpapers")
    }

    function clipboard(): void {
      Launcher.toggle("clipboard")
    }

    function windows(): void {
      Launcher.toggle("windows")
    }

    function power(): void {
      Launcher.toggle("power")
    }
  }

  // a screenshot is the thing a key is for. these take the target with them, so a
  // bind does not depend on what the panel was last left set to.
  IpcHandler {
    target: "capture"

    function region(): void {
      Capture.shortcut("shot", "region")
    }

    function app(): void {
      Capture.shortcut("shot", "app")
    }

    function monitor(): void {
      Capture.shortcut("shot", "monitor")
    }

    // the target is an argument here, unlike the screenshot calls above, because a
    // recording is the one a key would want to start on something other than
    // whatever the panel was last left showing. empty means whatever that is.
    function record(target: string): void {
      Capture.shortcut("rec", target.length > 0 ? target : Capture.target)
    }

    function stop(): void {
      Capture.stop()
    }

    function color(): void {
      Capture.shortcut("pick", Capture.target)
    }
  }

  // the display's two switches are three folds deep in a panel, and both are the
  // kind of thing a key should reach.
  // the brightness keys, so one press is one step of the shell's own scale and the
  // reading it shows. hyprland's binds ran brightnessctl, whose percentages are
  // points on a perceptual curve rather than the level this shell reports.
  IpcHandler {
    target: "backlight"

    function up(): void {
      Backlight.step(1)
    }

    function down(): void {
      Backlight.step(-1)
    }

    function level(): string {
      return `${Backlight.percent}`
    }
  }

  IpcHandler {
    target: "display"

    function night(): void {
      Display.setNight(!Display.night)
    }

    function awake(): void {
      Display.setAwake(!Display.awake)
    }

    function temperature(kelvin: int): void {
      Display.setTemperature(kelvin)
    }
  }

  // the calendar is a click on the clock, and now that it says something a key
  // may as well reach it. toggles, like every other latched thing here.
  IpcHandler {
    target: "calendar"

    function toggle(): void {
      Notches.toggle("clock", "")
    }
  }

  // the system tab onto one of its rows, exactly as that row's icon on the strip
  // would -- which is otherwise a click, and a click is ydotool and a password.
  IpcHandler {
    target: "system"

    function toggle(row: string): void {
      Notches.toggleRow(row, "")
    }
  }

  // notifications are the one thing here with no window of its own to click: a
  // toast is gone by the time you reach for it, and the switch is three folds deep
  // in a panel. so the two verbs worth binding a key to live here.
  IpcHandler {
    target: "notifications"

    function dnd(): void {
      Notifications.toggleDnd()
    }

    function clear(): void {
      Notifications.clear()
    }

    function dismiss(): void {
      Notifications.dismissAll()
    }
  }
}
