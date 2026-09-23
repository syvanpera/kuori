import Quickshell
import QtQuick
import qs.services

// owns the launcher window's lifetime. the window exists only while the launcher
// is open, because a layershell surface holds the keyboard for exactly as long as
// it is mapped, and a shell that eats every keystroke while idle is worse than no
// launcher at all.
Scope {
  id: root

  // captured when the launcher opens rather than bound live. writing
  // PanelWindow.screen destroys and rebuilds the wayland surface, so a live
  // binding would tear the launcher down mid-word every time focus wandered.
  property var openScreen: null

  Connections {
    target: Launcher

    // ordered on purpose: the screen has to be chosen before the component is
    // created, and two bindings on two properties have no ordering between them.
    // closing is not handled here, because the window plays its exit animation
    // and calls back when there is nothing left to draw.
    function onOpenedChanged(): void {
      if (Launcher.opened) {
        root.openScreen = Screens.focused
        Launcher.mapped = true
        loader.active = true
      }
    }
  }

  // a monitor unplugged while the launcher is open leaves the window pointing at
  // a screen that no longer exists. closing is the only sane recovery -- and only
  // that monitor: one plugged in, or another one leaving, changes nothing here.
  Connections {
    target: Quickshell

    function onScreensChanged(): void {
      if (!Array.from(Quickshell.screens).includes(root.openScreen)) Launcher.close()
    }
  }

  LazyLoader {
    id: loader

    // active, not activeAsync: the surface, its keyboard grab and its first frame
    // should land in the same turn, because a launcher that appears one frame
    // after the keybind swallows the first letter typed.
    LauncherWindow {
      screen: root.openScreen

      onDismissed: {
        loader.active = false
        Launcher.mapped = false
      }
    }
  }
}
