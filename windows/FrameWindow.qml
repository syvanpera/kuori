import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.components
import qs.modules
import qs.services
import qs.theme

// the only window that paints. it covers the whole screen so the border, the
// notches and (stage 2) the panels that drop out of them share one coordinate
// space, which is the only way the rounded corners come out seamless.
PanelWindow {
  id: root

  // anchored to every edge with exclusion ignored, so this item's origin is the
  // monitor's top-left in logical pixels -- the same space hyprland reports window
  // positions in, offset by the monitor's own origin.
  readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  // a surface anchored to all four edges can never reserve space, and without
  // Ignore hyprland would place this one inside the area the reservation windows
  // already claimed, pulling the frame inboard on every reload.
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"

  // the border is decoration and never takes a click; only the tabs do. a wayland
  // input region gates pointer enter and leave as well as clicks, so hover in
  // stage 2 only works for what is listed here. the focus mark is deliberately
  // absent: it sits on top of a window and must never eat its clicks.
  mask: Region {
    Region { item: workspaces.hitArea }
    Region { item: clock.hitArea }
    Region { item: system.hitArea }
  }

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "qs-frame"

  // before the frame on purpose: the band is drawn over the top of these, so a
  // notch casts onto the desktop below it without smearing the rail it hangs off.
  NotchShadow { notch: workspaces }
  NotchShadow { notch: clock }
  NotchShadow { notch: system }

  DesktopFrame {
    anchors.fill: parent
  }

  // between the frame and the notches, so a window sitting against the top edge
  // gets its mark drawn under the tabs rather than over them.
  FocusMark {
    id: mark

    // a special workspace is open over the top of a normal one, so its windows are
    // on screen and focusable while never being their monitor's activeWorkspace.
    // their ids are the negative ones, and they have to be let through by hand or
    // the mark vanishes exactly when a scratchpad is pulled up.
    readonly property bool onShownWorkspace: {
      const ws = FocusedWindow.toplevel?.workspace ?? null
      if (!ws) return false

      return ws.id < 0 || ws === root.monitor?.activeWorkspace
    }

    // and a fullscreen window is alone on its monitor, so there is nothing to tell
    // apart and nothing to mark.
    readonly property bool eligible: FocusedWindow.monitor === root.monitor
      && mark.onShownWorkspace
      && !FocusedWindow.fullscreen
      && FocusedWindow.geometry.width > 0

    // dark for one frame after focus moves to a different window, so x and y have
    // already jumped to the new corner by the time the triangle is drawn again.
    property bool swapping: false

    readonly property bool lit: mark.eligible && !mark.swapping

    readonly property string address: FocusedWindow.toplevel?.address ?? ""

    x: FocusedWindow.geometry.x + FocusedWindow.geometry.width - mark.width - (root.monitor?.x ?? 0)
    y: FocusedWindow.geometry.y - (root.monitor?.y ?? 0)

    opacity: mark.lit ? 1 : 0
    visible: mark.opacity > 0

    onAddressChanged: {
      mark.swapping = true
      swap.restart()
    }

    // fading in is animated, going dark is not. an animated fade-out would run
    // against the live position binding and show the triangle travelling from the
    // old window's corner to the new one, which is the whole thing this avoids.
    // the duration is read when the animation starts, by which point lit already
    // holds the value that started it.
    Behavior on opacity {
      NumberAnimation {
        duration: mark.lit ? Theme.focusMarkFade : 0
        easing.type: Easing.OutCubic
      }
    }

    Timer {
      id: swap

      // one frame at 60Hz. the position and the blanking apply in the same frame
      // anyway; this only guarantees the fade restarts from a repainted corner.
      interval: 16
      onTriggered: mark.swapping = false
    }
  }

  Notch {
    id: workspaces

    x: Theme.borderWidth
    y: Theme.borderWidth
    placement: "left"

    panel: Component {
      WorkspacePanel {}
    }

    WorkspaceDots {}
  }

  Notch {
    id: clock

    x: Math.round((root.width - width) / 2)
    y: Theme.borderWidth
    placement: "center"

    ClockLabel {}
  }

  Notch {
    id: system

    x: root.width - width - Theme.borderWidth
    y: Theme.borderWidth
    placement: "right"

    SystemStatus {}
  }
}
