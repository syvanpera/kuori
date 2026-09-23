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

  // a bluetooth pairing question is a card on this surface too, though it is not
  // a notification.
  readonly property bool wanted: Notifications.popups.length > 0 || Bluez.asking

  onWantedChanged: {
    if (!root.wanted) {
      loader.active = false
      return
    }

    if (!loader.active) root.openScreen = Screens.focused

    loader.active = true
  }

  // the toasts' monitor unplugged. the notifications go, as they always have --
  // they are in the history -- but a pairing question is still waiting on an
  // answer and keeps `wanted` up, so the surface has to follow it somewhere that
  // exists rather than stay on a screen that does not.
  Connections {
    target: Quickshell

    function onScreensChanged(): void {
      if (Array.from(Quickshell.screens).includes(root.openScreen)) return

      Notifications.dismissAll()

      if (loader.active) root.openScreen = Screens.focused
    }
  }

  LazyLoader {
    id: loader

    ToastWindow {
      screen: root.openScreen
      screenName: root.openScreen?.name ?? ""
    }
  }
}
