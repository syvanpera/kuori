import Quickshell
import QtQuick
import qs.services

// owns the authentication dialog's lifetime. the same arrangement as
// LauncherLoader: the surface exists only while there is something to answer,
// because a layershell surface holds the keyboard for as long as it is mapped.
Scope {
  id: root

  // captured when the request arrives rather than bound live: writing
  // PanelWindow.screen rebuilds the wayland surface, which would throw away a
  // half-typed password every time focus wandered.
  property var openScreen: null

  Connections {
    target: Polkit

    function onFlowChanged(): void {
      if (Polkit.flow === null) return

      root.openScreen = Screens.focused
      loader.active = true
    }
  }

  LazyLoader {
    id: loader

    PolkitWindow {
      screen: root.openScreen

      onDismissed: loader.active = false
    }
  }
}
