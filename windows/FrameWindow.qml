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
    Region { item: toggles.hitArea }
  }

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "qs-frame"

  // a press that lands over a window hands focus to that window, and the pointer
  // leave that follows cancels the click before it finishes. the grab keeps input
  // on the shell while a panel is out, which is also what makes a click anywhere
  // else dismiss it.
  HyprlandFocusGrab {
    windows: [root]
    active: Notches.open !== ""

    onCleared: Notches.close()
  }

  // escape shuts whatever is latched open. the grab above is what makes this
  // reachable: it routes the keyboard here as well as the pointer, so the frame
  // needs no keyboard focus of its own -- and asking for one breaks both the
  // other things on this page. WlrKeyboardFocus.Exclusive is a focus change in
  // the same frame as the grab, which answers it with an immediate cleared() and
  // shuts the panel as it opens; and once held, it stops hyprland counting a
  // click elsewhere as breaking the grab, so click-outside-to-dismiss dies too.
  //
  // no size: this exists to hold focus, and an item filling the window would sit
  // over the tabs for no reason.
  // an idle inhibitor is a property of a surface, not of a session, so it hangs
  // off the one window this shell always has mapped. the flag it follows lives in
  // the service, where the switch that sets it can reach it.
  IdleInhibitor {
    window: root
    enabled: Display.awake
  }

  Item {
    focus: true

    Keys.onEscapePressed: Notches.close()
  }

  // before the frame on purpose: the band is drawn over the top of these, so a
  // notch casts onto the desktop below it without smearing the rail it hangs off.
  NotchShadow { notch: workspaces }
  NotchShadow { notch: clock }
  NotchShadow { notch: system }

  NotchShadow {
    notch: toggles

    visible: toggles.visible
    opacity: toggles.opacity
  }

  // the osd's shadow belongs here with the tabs' own, for the same reason: it is
  // flush against the side border, and a shadow drawn after the frame would smear
  // down the band instead of falling on the desktop beside it. its corners are not
  // a tab's -- it is square where it tucks under the strip.
  NotchShadow {
    notch: osd

    visible: osd.visible
    opacity: osd.opacity

    topLeftRadius: Theme.notchRadius
    topRightRadius: 0
    bottomLeftRadius: Theme.notchRadius
    bottomRightRadius: 0
  }

  DesktopFrame {
    anchors.fill: parent
  }

  // between the frame and the notches, so a window sitting against the top edge
  // gets its indicator drawn under the tabs rather than over them.
  FocusIndicator {
    monitor: root.monitor
  }

  Notch {
    id: workspaces

    x: Theme.borderWidth
    y: Theme.borderWidth
    placement: "left"
    notchId: "workspaces"

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
    notchId: "clock"
    trigger: "click"

    panel: Component {
      ClockPanel {}
    }

    ClockLabel {
      peeking: clock.hovered
    }
  }

  // the switches, in a tab of their own between the clock and the system tab. it
  // has no panel: the three glyphs are the whole of it.
  //
  // it is placed from the system tab's *strip* rather than its body, so that it
  // stays where it is when that tab grows a panel -- which it does towards the
  // left, over this.
  Notch {
    id: toggles

    x: root.width - Theme.borderWidth - system.stripWidth - Theme.togglesGap - width
    y: Theme.borderWidth
    placement: "center"
    notchId: "toggles"

    // centre-placed for its corners and its fillets, but padded like the tabs that
    // carry glyphs rather than like the clock.
    padding: Theme.notchPadding

    // both of the things that would grow over it.
    aside: Notches.open === "system" || Osd.shown

    Toggles {}
  }

  Notch {
    id: system

    x: root.width - width - Theme.borderWidth
    y: Theme.borderWidth
    placement: "right"
    notchId: "system"
    trigger: "click"

    // the one tab that keeps its strip: the glyphs it reports stay on screen while
    // its panel is out, and the panel hangs underneath them.
    keepStrip: true

    // and the one tab something else hangs off: the osd drops out of it.
    hangHeight: osd.visible ? osd.height : 0

    panel: Component {
      SystemPanel {}
    }

    SystemStatus {}
  }

  // last, so it is over the frame and over the focus indicator, like the tabs. it
  // shares the system tab's right edge and hangs directly below its strip.
  OsdBox {
    id: osd

    stripWidth: system.width
    x: root.width - width - Theme.borderWidth
    y: Theme.borderWidth + system.bodyHeight
  }
}
