import QtQuick
import qs.components
import qs.services
import qs.theme

// one access point in the network row's lists. the two lists label it
// differently: a known network is a name you have already joined, an available
// one is a stranger, and the design says how strong it is and what it would take
// to get on.
Rectangle {
  id: root

  required property var network

  // whether this entry is in the AVAILABLE list rather than the KNOWN one.
  property bool stranger: false

  readonly property bool active: root.network.connected

  // a locked network shows the lock instead of its signal. that loses the signal,
  // which is the design's choice: what you need to know about a network you have
  // never joined is first whether you can.
  readonly property string icon: {
    if (Network.locked(root.network)) return "wifi_lock"
    if (!root.stranger) return "wifi"

    const strength = root.network.signalStrength
    if (strength >= 0.66) return "wifi"
    if (strength >= 0.33) return "wifi_2_bar"
    return "wifi_1_bar"
  }

  readonly property string detail: {
    if (root.active) return "Connected"
    if (root.stranger) return Network.detail(root.network)
    return ""
  }

  // the entry grows with its text rather than sitting at one height, because the
  // second line is only there some of the time.
  implicitHeight: Math.max(Theme.sysNetIcon, text.implicitHeight) + Theme.sysNetPaddingV * 2

  radius: Theme.sysNetRadius
  color: root.active ? Theme.sysNetActive : "transparent"

  Glyph {
    id: entryIcon

    x: Theme.sysNetPaddingH
    anchors.verticalCenter: parent.verticalCenter

    size: Theme.sysNetIcon
    icon: root.icon
    iconColor: root.active ? Theme.accent : Theme.sysNetGlyph
  }

  Column {
    id: text

    anchors.left: entryIcon.right
    anchors.leftMargin: Theme.sysNetGap
    anchors.right: parent.right
    anchors.rightMargin: Theme.sysNetPaddingH
    anchors.verticalCenter: parent.verticalCenter

    spacing: Theme.sysNetTextSpacing

    Text {
      width: parent.width

      text: root.network.name
      color: root.active ? Theme.text : Theme.sysNetName
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
}
