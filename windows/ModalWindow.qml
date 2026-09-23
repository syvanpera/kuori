import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.theme

// a fullscreen overlay on one monitor that holds the keyboard and a scrim, for as
// long as something is asking. the launcher and the polkit dialog are both one of
// these with a card on top; what they put on it, and what a click on the scrim or
// on another monitor means, is theirs to say.
PanelWindow {
  id: root

  // drives every transition. false for the first frame because a Behavior never
  // runs on the value a property was initialised with, and an entry animation
  // needs somewhere to come from.
  property bool shown: false

  // how long the scrim takes to fade, and so how long the window outlives the
  // close.
  property int fade: Theme.launcherFade

  property color scrimColor: Theme.launcherScrim

  // the loader waits for this instead of destroying the window the moment it
  // closes, which would cut the exit animation off at frame one.
  signal dismissed()

  // a click that reached the scrim, which is to say one outside whatever card sits
  // on it: the card eats its own.
  signal scrimClicked()

  // the compositor is the only thing that can see a click on another monitor, or
  // focus being handed to a window by a keybind. cleared(), not activeChanged:
  // active also drops when the grab is released here, and answering that would be
  // a loop.
  signal grabCleared()

  // take the grab back after it was cleared, for a question a click elsewhere
  // does not answer.
  function holdGrab(): void {
    grab.active = true
  }

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  // same reasoning as the frame: a surface anchored to all four edges can never
  // reserve space, and anything but Ignore would fight the reservation windows
  // for the area they already claimed.
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"

  // Overlay, not Top: the frame sits on Top, and hyprland draws fullscreen windows
  // above Top, so a surface on Top would be invisible in exactly the case where it
  // is most needed -- and a password prompt a fullscreen window can cover is worse
  // than none.
  WlrLayershell.layer: WlrLayer.Overlay

  // Exclusive because whatever opened this never clicked it, and without an
  // exclusive grab the first keystroke goes to whatever hyprland still thinks is
  // focused. dropped the instant the close starts, so an app just launched gets
  // the keyboard rather than an overlay on its way out. do not also set
  // PanelWindow.focusable: it writes this same value.
  WlrLayershell.keyboardFocus: root.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  // and the input region goes with it. a mapped layer surface eats every click in
  // its region, including through the fade; an empty region hands the pointer back
  // to the desktop for those frames.
  mask: Region { item: root.shown ? scrim : null }

  Component.onCompleted: root.shown = true

  onShownChanged: {
    if (root.shown) {
      exit.stop()
      return
    }

    grab.active = false
    exit.restart()
  }

  // the window outlives the close only to play the fade out. a Behavior runs its
  // animation without ever emitting finished(), so the teardown is timed rather
  // than chained off the animation.
  Timer {
    id: exit

    interval: root.fade

    onTriggered: root.dismissed()
  }

  HyprlandFocusGrab {
    id: grab

    windows: [root]

    onCleared: root.grabCleared()
  }

  // one turn of the event loop after the surface is mapped. asking hyprland to
  // grab a surface it has not seen yet is answered with an immediate cleared(),
  // which would close the window on the frame it opened.
  Timer {
    interval: 1
    running: root.shown

    onTriggered: grab.active = true
  }

  // the backdrop. declared first, so everything a caller puts in the window is
  // drawn over it and answers its own clicks.
  MouseArea {
    id: scrim

    anchors.fill: parent
    opacity: root.shown ? 1 : 0

    onClicked: root.scrimClicked()

    Behavior on opacity {
      NumberAnimation { duration: root.fade }
    }

    Rectangle {
      anchors.fill: parent
      color: root.scrimColor
    }
  }
}
