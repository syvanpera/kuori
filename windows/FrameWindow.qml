import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import qs.components
import qs.modules
import qs.services
import qs.theme

// the only window that paints. it covers the whole screen so the border, the
// notches and the panels that drop out of them share one coordinate space, which
// is the only way the rounded corners come out seamless.
PanelWindow {
  id: root

  // anchored to every edge with exclusion ignored, so this item's origin is the
  // monitor's top-left in logical pixels -- the same space hyprland reports window
  // positions in, offset by the monitor's own origin.
  readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)

  // what Notches knows this screen by.
  readonly property string screenName: root.screen?.name ?? ""

  // whether the tabs are drawn here at all (Theme.tabScreens). the border, the
  // focus indicator and the key sink are on every screen either way.
  property bool tabs: true

  // whether this is the first screen at its scale, and so the one that keeps the
  // launcher's icons decoded for every screen at that scale.
  readonly property bool holdsIcons: Array.from(Quickshell.screens)
    .find(other => other.devicePixelRatio === root.screen?.devicePixelRatio) === root.screen

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
    // a hidden tab still has a size, so a screen without tabs takes itself out of
    // the region rather than trusting visibility to.
    Region { item: root.tabs ? workspaces.hitArea : null }
    Region { item: root.tabs ? clock.hitArea : null }
    Region { item: root.tabs ? system.hitArea : null }
    Region { item: root.tabs ? toggles.hitArea : null }
  }

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "qs-frame"

  // a press that lands over a window hands focus to that window, and the pointer
  // leave that follows cancels the click before it finishes. the grab keeps input
  // on the shell while a panel is out, which is also what makes a click anywhere
  // else dismiss it.
  //
  // only on the screen the panel is open on. hyprland keeps one grab at a time, so
  // a grab per screen has each new one clearing the last -- and a cleared grab is
  // read as a click elsewhere, which shut every panel the instant it opened.
  HyprlandFocusGrab {
    windows: [root]
    active: Notches.openOn(root.screenName) !== ""

    // a grab also clears when the panel moves to another screen and this one lets
    // go. that is not a click elsewhere, and closing on it would shut the panel
    // that just opened over there.
    onCleared: if (Notches.screen === root.screenName) Notches.close()
  }

  // an idle inhibitor is a property of a surface, not of a session, so it hangs
  // off the one window this shell always has mapped. the flag it follows lives in
  // the service, where the switch that sets it can reach it.
  IdleInhibitor {
    window: root
    enabled: Display.inhibited
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
  Item {
    id: keySink

    // a bluetooth pairing card is up on the row that is showing. it owns the keys
    // it has a meaning for, the way the launcher's confirmation does -- and each is
    // answered in its own handler, because those run before Keys.onPressed and a
    // guard written there would never see them.
    readonly property bool pairing: Bluez.asking && Notches.openOn(root.screenName) === "system" && Notches.row === "bluetooth"
    readonly property bool choosing: keySink.pairing && Bluez.request.kind !== "type"

    // the system panel is open here, so the arrows and return are its cursor's.
    readonly property bool steering: Notches.openOn(root.screenName) === "system" && !keySink.pairing

    focus: true

    Keys.onEscapePressed: keySink.pairing ? Bluez.reject() : Notches.close()

    // a keyboard being paired types its code on itself, and enter there is the
    // device's. an enter reaching the shell is some other keyboard's, and means
    // nothing to that card.
    Keys.onReturnPressed: keySink.answer()
    Keys.onEnterPressed: keySink.answer()
    Keys.onUpPressed: if (keySink.steering) system.panelItem?.step(-1)
    Keys.onDownPressed: if (keySink.steering) system.panelItem?.step(1)

    // the launcher's two home-row pairs as well: ctrl+n and ctrl+p the readline
    // way, ctrl+j and ctrl+k the vim way. the panel is one column, so both pairs
    // mean the same thing here. these keys have no handler of their own, which is
    // why they reach this one at all.
    Keys.onPressed: event => {
      if (!keySink.steering || !(event.modifiers & Qt.ControlModifier)) return

      const delta = { [Qt.Key_N]: 1, [Qt.Key_J]: 1, [Qt.Key_P]: -1, [Qt.Key_K]: -1 }[event.key]

      if (delta === undefined) return

      system.panelItem?.step(delta)
      event.accepted = true
    }
    Keys.onTabPressed: if (keySink.choosing) Bluez.selected = 1 - Bluez.selected
    Keys.onLeftPressed: if (keySink.choosing) Bluez.selected = 1 - Bluez.selected
    Keys.onRightPressed: if (keySink.choosing) Bluez.selected = 1 - Bluez.selected

    function answer(): void {
      if (keySink.choosing) keySink.choose()
      else if (keySink.steering) system.panelItem?.press()
    }

    function choose(): void {
      if (Bluez.selected === 0) Bluez.accept()
      else Bluez.reject()
    }

    Connections {
      target: Notches

      function onRefocus(): void {
        keySink.forceActiveFocus()
      }
    }
  }

  // the launcher's window is built and thrown away on every open, and the decoded
  // icons go with it: measured at ~600ms to decode eleven theme svgs, paid again
  // on every single open. these hold the same images at the same size for the life
  // of the session, so the launcher's own IconImages find them already decoded.
  // nothing draws them -- they exist to be a reference qt's pixmap cache respects.
  //
  // one set per scale rather than per screen. the cache keys a picture by the size
  // it was decoded at, so two monitors at the same scale would hold two copies of
  // one set, and a monitor at another scale needs its own.
  Repeater {
    model: root.holdsIcons ? DesktopEntries.applications.values : []

    IconImage {
      required property var modelData

      visible: false
      asynchronous: true
      implicitSize: Theme.launcherIconInner
      source: Icons.path(modelData.icon ?? "")
    }
  }

  // before the frame on purpose: the band is drawn over the top of these, so a
  // notch casts onto the desktop below it without smearing the rail it hangs off.
  NotchShadow { notch: workspaces; visible: root.tabs }
  NotchShadow { notch: clock; visible: root.tabs }
  NotchShadow { notch: system; visible: root.tabs }

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

    visible: root.tabs && osd.visible
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
  // gets its indicator drawn under the tabs rather than over them. the unfocused
  // marks first, so the focused one is never under a neighbour's.
  UnfocusedIndicators {
    monitor: root.monitor
  }

  FocusIndicator {
    monitor: root.monitor
  }

  Notch {
    id: workspaces

    visible: root.tabs

    x: Theme.borderWidth
    y: Theme.borderWidth
    placement: "left"
    notchId: "workspaces"
    screenName: root.screenName

    panel: Component {
      WorkspacePanel {}
    }

    WorkspaceDots {}
  }

  Notch {
    id: clock

    visible: root.tabs

    x: Math.round((root.width - width) / 2)
    y: Theme.borderWidth
    placement: "center"
    notchId: "clock"
    screenName: root.screenName
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
    screenName: root.screenName

    // centre-placed for its corners and its fillets, but padded like the tabs that
    // carry glyphs rather than like the clock.
    padding: Theme.notchPadding

    // both of the things that would grow over it -- and on a screen without tabs,
    // always. aside rather than visible, because the tab's own visibility follows
    // its fade.
    aside: !root.tabs || Notches.openOn(root.screenName) === "system" || osd.visible

    Toggles {}
  }

  Notch {
    id: system

    visible: root.tabs

    x: root.width - width - Theme.borderWidth
    y: Theme.borderWidth
    placement: "right"
    notchId: "system"
    screenName: root.screenName
    trigger: "click"

    // the one tab that keeps its strip: the glyphs it reports stay on screen while
    // its panel is out, and the panel hangs underneath them.
    keepStrip: true

    // and the one tab something else hangs off: the osd drops out of it.
    hangHeight: osd.visible ? osd.height : 0

    panel: Component {
      SystemPanel {}
    }

    SystemStatus {
      screenName: root.screenName
    }
  }

  // last, so it is over the frame and over the focus indicator, like the tabs. it
  // shares the system tab's right edge and hangs directly below its strip.
  OsdBox {
    id: osd

    stripWidth: system.width
    // where the system tab it hangs from is: the main screen, or with tabs on
    // every screen, the focused one.
    here: root.tabs && root.screenName === Screens.tabsName
    x: root.width - width - Theme.borderWidth
    y: Theme.borderWidth + system.bodyHeight
  }
}
