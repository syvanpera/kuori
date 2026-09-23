import QtQuick
import qs.components
import qs.services
import qs.theme

// the network row of the system panel: the link at a glance, and what the design
// folds out under it -- the wire, the radio switch, six readings about whichever
// of the two is carrying traffic, and the air around you split into networks you
// have joined before and networks you have not.
PanelRow {
  id: root

  icon: Network.linkGlyph
  label: "Network"
  lit: Network.online

  value: Network.linkName

  // the scan, the ping and the counter poll all run off this. nothing in the
  // service ticks while the row is folded away.
  Binding {
    target: Network
    property: "detailed"
    value: root.expanded
  }

  // the section is the machine's ethernet ports, and a laptop without one has no
  // business showing a switch for it.
  DeviceSection {
    width: root.bodyWidth
    heading: "ETHERNET"
    model: Network.wiredDevices
    ruled: false

    delegate: WiredEntry {
      required property var modelData

      width: root.bodyWidth
      device: modelData
    }
  }

  Rule {
    width: root.bodyWidth
    visible: Network.wiredDevices.length > 0
  }

  SectionSwitch {
    width: root.bodyWidth
    label: "WI-FI"
    checked: Network.enabled

    onToggled: Network.setEnabled(!Network.enabled)
  }

  // the readings describe a link, so there is nothing to say without one.
  StatGrid {
    width: root.bodyWidth
    visible: Network.online

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
      // a wire has no band, and what it has instead is how fast it negotiated.
      key: Network.onWire ? "Link" : "Band"
      value: (Network.onWire ? Network.speedName(Network.wired.linkSpeed) : Network.band) || "--"
    }
  }

  DeviceSection {
    width: root.bodyWidth
    heading: "KNOWN NETWORKS"
    model: Network.known

    delegate: NetworkEntry {
      required property var modelData

      width: root.bodyWidth
      network: modelData
    }
  }

  DeviceSection {
    width: root.bodyWidth
    heading: "AVAILABLE"
    model: Network.available

    delegate: NetworkEntry {
      required property var modelData

      width: root.bodyWidth
      network: modelData
      stranger: true
    }
  }
}
