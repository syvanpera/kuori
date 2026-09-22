import Quickshell
import QtQuick
import qs.services

// owns the toast surface's lifetime. it exists only while there is something to
// show, so an idle desktop carries no extra layer surface at all.
Scope {
  id: root

  // captured when the first toast appears rather than bound live: writing
  // PanelWindow.screen rebuilds the wayland surface, and a toast that flickers
  // every time focus wanders is worse than one on the wrong monitor.
  property var openScreen: null

  Connections {
    target: Notifications

    function onPopupsChanged(): void {
      if (Notifications.popups.length === 0) {
        loader.active = false
        return
      }

      if (!loader.active) root.openScreen = Screens.focused

      loader.active = true
    }
  }

  Connections {
    target: Quickshell

    function onScreensChanged(): void {
      Notifications.dismissAll()
    }
  }

  LazyLoader {
    id: loader

    ToastWindow {
      screen: root.openScreen
    }
  }
}
