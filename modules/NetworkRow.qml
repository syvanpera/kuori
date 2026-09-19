import QtQuick
import qs.components
import qs.services
import qs.theme

// the wi-fi row of the system panel: the link at a glance, and what the design
// folds out under it -- the radio switch, six readings, and what is in range.
PanelRow {
  id: root

  icon: Network.enabled ? "wifi" : "wifi_off"
  label: "Wi-Fi"
  lit: Network.enabled

  value: {
    if (!Network.enabled) return "Off"
    return Network.ssid || "Not connected"
  }

  // the scan, the ping and the counter poll all run off this. nothing in the
  // service ticks while the row is folded away.
  Binding {
    target: Network
    property: "detailed"
    value: root.expanded
  }

  Item {
    width: root.bodyWidth
    height: Math.max(enabledLabel.implicitHeight, radio.height)

    Text {
      id: enabledLabel

      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter

      text: "ENABLED"
      color: Theme.sysCap
      font.family: Theme.monoFont
      font.pixelSize: Theme.sysCapSize
      font.weight: Font.Medium
      font.letterSpacing: Theme.sysCapSpacing
    }

    Switch {
      id: radio

      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter

      checked: Network.enabled

      onToggled: Network.setEnabled(!Network.enabled)
    }
  }

  // the readings describe an association, so there is nothing to say without one.
  Grid {
    width: root.bodyWidth
    visible: Network.connected

    columns: 2
    columnSpacing: Theme.sysStatGapH
    rowSpacing: Theme.sysStatGapV

    // two equal columns of whatever the gutter leaves.
    readonly property real cell: (width - Theme.sysStatGapH) / 2

    StatPair {
      width: parent.cell
      key: "Ping"
      value: Network.pingMs < 0 ? "--" : `${Network.pingMs} ms`
    }

    StatPair {
      width: parent.cell
      key: "Loss"
      value: Network.loss < 0 ? "--" : `${Network.loss}%`
    }

    StatPair {
      width: parent.cell
      key: "Down"
      value: Network.formatBytes(Network.rxBytes)
    }

    StatPair {
      width: parent.cell
      key: "Up"
      value: Network.formatBytes(Network.txBytes)
    }

    StatPair {
      width: parent.cell
      key: "IP"
      value: Network.ip || "--"
    }

    StatPair {
      width: parent.cell
      key: "Band"
      value: Network.band || "--"
    }
  }

  Rectangle {
    width: root.bodyWidth
    height: 1
    visible: Network.enabled
    color: Theme.sysLine
  }

  Text {
    visible: Network.enabled

    text: "KNOWN NETWORKS"
    color: Theme.sysCap
    font.family: Theme.monoFont
    font.pixelSize: Theme.sysCapSize
    font.weight: Font.Medium
    font.letterSpacing: Theme.sysCapSpacing
  }

  Column {
    width: root.bodyWidth
    visible: Network.enabled
    spacing: Theme.sysNetSpacing

    Repeater {
      model: Network.visible

      Rectangle {
        id: entry

        required property var modelData

        readonly property bool active: entry.modelData.connected

        width: parent.width
        height: Theme.sysNetIcon + Theme.sysNetPaddingV * 2

        radius: Theme.sysNetRadius
        color: entry.active ? Theme.sysNetActive : "transparent"

        Glyph {
          id: entryIcon

          x: Theme.sysNetPaddingH
          anchors.verticalCenter: parent.verticalCenter

          size: Theme.sysNetIcon
          icon: Network.locked(entry.modelData) ? "wifi_lock" : "wifi"
          iconColor: entry.active ? Theme.accent : Theme.tint.alpha(0.45)
        }

        Column {
          anchors.left: entryIcon.right
          anchors.leftMargin: Theme.sysNetGap
          anchors.right: parent.right
          anchors.rightMargin: Theme.sysNetPaddingH
          anchors.verticalCenter: parent.verticalCenter

          spacing: Theme.sysNetTextSpacing

          Text {
            width: parent.width

            text: entry.modelData.name
            color: entry.active ? Theme.text : Theme.sysNetName
            font.family: Theme.monoFont
            font.pixelSize: Theme.sysNetNameSize
            font.weight: Font.Medium
            elide: Text.ElideRight
          }

          Text {
            // only the one you are on has anything to report. the rest are just
            // names until the design gives them something to do.
            visible: entry.active

            text: "Connected"
            color: Theme.sysNetState
            font.family: Theme.monoFont
            font.pixelSize: Theme.sysNetStateSize
          }
        }
      }
    }
  }
}
