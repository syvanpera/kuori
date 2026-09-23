import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.components
import qs.modules
import qs.services
import qs.theme

// the toast surface: a column of cards hanging off the top right, over everything
// and in the way of nothing.
//
// it is the launcher's window turned inside out. the launcher wants the keyboard,
// a scrim and a grab that closes it on the first click elsewhere; a toast must
// have none of those, because it appears while you are working on something else
// and must not interrupt it.
PanelWindow {
  id: root

  // the screen the loader put this on, by name. handed in rather than read off
  // `screen`: that one changes as the surface maps, and a visibility bound to it
  // re-entered its own binding every time a toast appeared.
  property string screenName: ""

  anchors {
    top: true
    right: true
  }

  margins {
    // the osd drops out of the same corner, so the toasts move down out of its way
    // while it is up rather than being covered by it.
    top: Osd.shown ? Theme.toastTopOsd : Theme.toastTop
    right: Theme.toastRight

    Behavior on top {
      Glide { duration: Theme.notchExpandDuration }
    }
  }

  implicitWidth: Theme.toastWidth
  implicitHeight: stack.implicitHeight

  // like every other surface here: anchored windows reserve space unless told not
  // to, and these must never push a window aside.
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"

  // above the frame, as the design draws them, and deliberately below the polkit
  // and launcher overlays: a toast arriving mid-password must not land on top of
  // the field.
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "qs-toasts"

  // never. a toast that takes the keyboard steals the keystroke you were in the
  // middle of typing.
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  // the toasts and the system panel hang off the same corner, and the design
  // draws the panel over them (z-index 50 against 45). layer-shell has no such
  // ordering -- two surfaces on one layer stack by creation order, and this one is
  // always created later -- so the toasts stand aside for the one panel they
  // overlap instead. nothing is lost by it: that panel is where the history is.
  visible: Notches.openOn(root.screenName) !== "system"

  // only the cards are clickable; every other pixel of this surface belongs to
  // whatever is behind it. without this the whole top-right corner of the desktop
  // would stop answering the pointer whenever a toast was up.
  mask: Region { item: stack }

  // the design's `backdrop-filter: blur(10px)`. hyprland does the blurring, on the
  // region we hand it -- no framebuffer of our own, which is what a MultiEffect
  // would have cost.
  BackgroundEffect.blurRegion: Region { item: stack }

  Column {
    id: stack

    anchors.right: parent.right
    width: Theme.toastWidth

    spacing: Theme.toastGap

    // first, over the notifications: bluez is waiting on this one, and gives up
    // after a minute or so.
    PairingToast {
      visible: Bluez.asking
    }

    Repeater {
      model: Notifications.popups

      ToastCard {
        id: card

        required property int index
        required property var modelData

        popup: modelData
        depth: index

        // the design slides each card in from the right as it arrives.
        Component.onCompleted: entry.start()

        Glide {
          id: entry

          // the card itself, named rather than reached for: a NumberAnimation has
          // no parent property of its own, so `parent` here resolves against the
          // delegate's scope and animates the Column holding every card.
          target: card
          properties: "x"
          from: Theme.toastSlide
          to: 0
          duration: Theme.toastEnter
        }
      }
    }

    // the design only offers this once there is more than one card to clear.
    Rectangle {
      anchors.right: parent.right

      visible: Notifications.popups.length > 1
      width: dismissAll.implicitWidth + Theme.toastDismissPaddingH * 2
      height: dismissAll.implicitHeight + Theme.toastDismissPaddingV * 2

      radius: height / 2
      color: Theme.toastFill
      border.width: 1
      border.color: Theme.pkOutline

      Text {
        id: dismissAll

        anchors.centerIn: parent

        text: "DISMISS ALL"
        color: dismissHover.containsMouse ? Theme.tintBright : Theme.toastDismissText
        font.family: Theme.monoFont
        font.pixelSize: Theme.toastDismissSize
        font.weight: Font.Medium
        font.letterSpacing: Theme.toastDismissSpacing

        Behavior on color {
          ColorAnimation { duration: Theme.notchFadeDuration }
        }
      }

      MouseArea {
        id: dismissHover

        anchors.fill: parent
        hoverEnabled: true

        onClicked: Notifications.dismissAll()
      }
    }
  }
}
