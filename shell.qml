import Quickshell
import qs.windows

ShellRoot {
  id: shell

  Variants {
    model: Quickshell.screens

    DesktopShell {}
  }
}
