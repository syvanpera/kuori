import QtQuick
import qs.components
import qs.services
import qs.theme

// the wi-fi row of the system panel: the link at a glance, and what the design
// folds out under it -- the radio switch, six readings, and the air around you
// split into networks you have joined before and networks you have not.
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

  NetworkList {
    width: root.bodyWidth
    heading: "KNOWN NETWORKS"
    networks: Network.known
  }

  NetworkList {
    width: root.bodyWidth
    heading: "AVAILABLE"
    networks: Network.available
    stranger: true
  }
}
