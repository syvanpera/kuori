import QtQuick
import Quickshell.Hyprland
import qs.services
import qs.theme

// decides whether the focused window should be marked on this monitor and where,
// then draws whichever indicator the theme asks for. the two styles differ only in
// what they paint: everything about when to show one, and the geometry to show it
// against, is the same, so it lives here once.
Item {
  id: root

  required property HyprlandMonitor monitor

  // a special workspace is open over the top of a normal one, so its windows are on
  // screen and focusable while never being their monitor's activeWorkspace. their
  // ids are the negative ones, and they have to be let through by hand or the
  // indicator vanishes exactly when a scratchpad is pulled up.
  readonly property bool onShownWorkspace: {
    const ws = FocusedWindow.toplevel?.workspace ?? null
    if (!ws) return false

    return ws.id < 0 || ws === root.monitor?.activeWorkspace
  }

  // and a fullscreen window is alone on its monitor, so there is nothing to tell
  // apart and nothing to mark.
  readonly property bool eligible: FocusedWindow.monitor === root.monitor
    && root.onShownWorkspace
    && !FocusedWindow.fullscreen
    && FocusedWindow.geometry.width > 0

  // dark for one frame after focus moves to a different window, so the geometry has
  // already jumped to the new window by the time anything is drawn again.
  property bool swapping: false

  readonly property bool lit: root.eligible && !root.swapping

  readonly property string address: FocusedWindow.toplevel?.address ?? ""

  // hyprland reports window geometry in global logical pixels; this window's origin
  // is its monitor's, so the monitor's origin comes off.
  readonly property real windowX: FocusedWindow.geometry.x - (root.monitor?.x ?? 0)
  readonly property real windowY: FocusedWindow.geometry.y - (root.monitor?.y ?? 0)
  readonly property real windowWidth: FocusedWindow.geometry.width

  anchors.fill: parent

  opacity: root.lit ? 1 : 0
  visible: root.opacity > 0

  onAddressChanged: {
    root.swapping = true
    swap.restart()
  }

  // fading in is animated, going dark is not. an animated fade-out would run
  // against the live position bindings and show the indicator travelling from the
  // old window to the new one, which is the whole thing this avoids. the duration
  // is read when the animation starts, by which point lit already holds the value
  // that started it.
  Behavior on opacity {
    NumberAnimation {
      duration: root.lit ? Theme.focusFade : 0
      easing.type: Easing.OutCubic
    }
  }

  Timer {
    id: swap

    // one frame at 60Hz. the position and the blanking apply in the same frame
    // anyway; this only guarantees the fade restarts from a repainted indicator.
    interval: 16
    onTriggered: root.swapping = false
  }

  // the corner wedge, tucked into the window's top-right.
  FocusMark {
    visible: Theme.focusStyle === "mark"

    x: root.windowX + root.windowWidth - width
    y: root.windowY
  }

  // or the strip, sitting on the window's top edge. placed against that edge
  // rather than inside the gap above it, so changing hyprland's gaps moves the
  // window and the strip together and nothing here needs to know what they are.
  // it is taller than the bar, by the horns that reach down into the window's
  // rounded corners, so it is the bar that is positioned here and not the item.
  FocusStrip {
    id: strip

    visible: Theme.focusStyle === "strip"

    width: root.windowWidth
    x: root.windowX
    y: root.windowY - strip.thickness
  }
}
