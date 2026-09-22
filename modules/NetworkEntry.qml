import QtQuick
import qs.components
import qs.services
import qs.theme

// one access point in the network row's lists, and whatever it needs from you.
// a locked network you have never joined opens a passphrase field underneath
// itself, and shows there what NetworkManager said if the passphrase was wrong.
Column {
  id: root

  required property var network

  // whether this entry is in the AVAILABLE list rather than the KNOWN one.
  property bool stranger: false

  readonly property bool active: root.network.connected
  readonly property bool picked: Network.selected === root.network.name

  // connected, or the one whose field is open. the design lights both the same
  // way, because both are the network this list is currently about.
  readonly property bool highlighted: root.active || root.picked

  readonly property bool locked: Network.locked(root.network)

  // a known network is drawn plain -- you have been here before and the only
  // question is whether you are on it now. a stranger is drawn by its signal,
  // because that is what decides whether joining is worth trying.
  readonly property string glyph: root.stranger ? Network.glyph(root.network.signalStrength) : "wifi"

  readonly property string detail: {
    if (root.active) return "Connected"
    if (root.stranger) return Network.detail(root.network)
    return ""
  }

  Rectangle {
    id: line

    width: root.width
    height: Math.max(Theme.sysNetIcon, text.implicitHeight) + Theme.sysNetPaddingV * 2

    radius: Theme.sysNetRadius
    color: {
      if (hover.containsMouse) return Theme.sysNetHover
      return root.highlighted ? Theme.sysNetActive : "transparent"
    }

    Behavior on color {
      ColorAnimation { duration: Theme.notchFadeDuration }
    }

    Glyph {
      id: entryIcon

      x: Theme.sysNetPaddingH
      anchors.verticalCenter: parent.verticalCenter

      size: Theme.sysNetIcon
      icon: root.glyph
      iconColor: root.highlighted ? Theme.accent : Theme.sysNetGlyph
    }

    // the lock sits at the far end rather than replacing the signal, so a row can
    // say how strong a network is and that it is shut at the same time.
    Glyph {
      id: lock

      x: line.width - Theme.sysNetPaddingH - width
      anchors.verticalCenter: parent.verticalCenter
      visible: root.locked

      size: Theme.sysLockIcon
      icon: "lock"
      iconColor: Theme.sysNetLock
    }

    Column {
      id: text

      anchors.left: entryIcon.right
      anchors.leftMargin: Theme.sysNetGap
      anchors.right: root.locked ? lock.left : parent.right
      anchors.rightMargin: Theme.sysNetGap
      anchors.verticalCenter: parent.verticalCenter

      spacing: Theme.sysNetTextSpacing

      Text {
        width: parent.width

        text: root.network.name
        color: root.highlighted ? Theme.text : Theme.sysNetName
        font.family: Theme.monoFont
        font.pixelSize: Theme.sysNetNameSize
        font.weight: Font.Medium
        elide: Text.ElideRight
      }

      Text {
        width: parent.width
        visible: root.detail !== ""

        text: root.detail
        color: Theme.sysNetDetail
        font.family: Theme.monoFont
        font.pixelSize: Theme.sysNetDetailSize
        elide: Text.ElideRight
      }
    }

    MouseArea {
      id: hover

      anchors.fill: parent
      hoverEnabled: true

      onClicked: Network.select(root.network)
    }
  }

  // the field is for a network we have no way into yet: a saved one is joined by
  // the click itself, and a refusal replaces the field until it has been read.
  Loader {
    width: root.width
    active: root.stranger && root.picked && !root.active && Network.error === ""

    sourceComponent: Component {
      PassphraseField {}
    }
  }

  Loader {
    width: root.width
    active: root.picked && Network.error !== ""

    sourceComponent: Component {
      Item {
        implicitHeight: Theme.sysFieldHeight

        Glyph {
          id: errorIcon

          x: Theme.sysFieldPaddingH
          y: Theme.sysFieldTop

          size: Theme.sysErrorIcon
          icon: "error"
          iconColor: Theme.sysError
          filled: true
        }

        Text {
          anchors.left: errorIcon.right
          anchors.leftMargin: Theme.sysErrorGap
          anchors.verticalCenter: errorIcon.verticalCenter

          text: Network.error
          color: Theme.sysError
          font.family: Theme.uiFont
          font.pixelSize: Theme.sysErrorSize
          font.weight: Font.Medium
        }
      }
    }
  }
}
