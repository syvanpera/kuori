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

  // one launcher for the whole session, on whichever monitor has focus, so it
  // hangs off the root instead of off Variants.
  LauncherLoader {}

  // and one authentication dialog, for the same reason.
  PolkitLoader {}

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
  }
}
