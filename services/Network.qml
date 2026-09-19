pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

// everything the system tab knows about the wireless link.
//
// Quickshell.Networking answers most of it from NetworkManager directly. three
// of the readings the design puts in the panel are not in that api at all: the
// round trip time, how many bytes have crossed the interface, and which band the
// association is on. those come from ping, from sysfs and from nmcli, which is
// the only reason this singleton owns processes.
Singleton {
  id: root

  // the panel raises this while the network row is folded open. every cost in
  // here hangs off it -- the scan, the ping and the counter poll -- so a shut
  // panel does no work at all, the same bargain the calendar is meant to make.
  property bool detailed: false

  // ping measures the path to the internet rather than to the router. a gateway
  // three metres away answers in single digits whatever the connection is doing,
  // which is a number that never tells you anything.
  property string pingTarget: "1.1.1.1"

  // -1 for "not measured yet", so the panel can say so rather than show a stale
  // reading from the last time it was open.
  property int pingMs: -1
  property real loss: -1
  property string band: ""

  // NetworkDevice.address is the hardware address, so the reading the design
  // actually wants has to come from nmcli alongside the band.
  property string ip: ""

  property real rxBytes: 0
  property real txBytes: 0

  readonly property var device: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
  readonly property bool enabled: Networking.wifiEnabled
  readonly property bool connected: root.device?.connected ?? false
  readonly property var network: root.device?.networks.values.find(n => n.connected) ?? null
  readonly property string ssid: root.network?.name ?? ""

  // one entry per ssid in range, the connected one first and the rest by signal.
  // sorted here rather than in the view because this only re-runs when the scan
  // finds or loses an access point: signalStrength moves constantly, and sorting
  // on that directly would have the rows swapping places under the pointer.
  readonly property var visible: {
    const seen = new Map()

    for (const net of root.device?.networks.values ?? []) {
      // a hidden ap advertises no ssid at all, and every radio in a mesh
      // advertises the same one. neither deserves a row of its own.
      if (!net.name) continue

      const best = seen.get(net.name)
      if (!best || net.signalStrength > best.signalStrength) seen.set(net.name, net)
    }

    return [...seen.values()].sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength))
  }

  function setEnabled(on: bool): void {
    Networking.wifiEnabled = on
  }

  // an ap we are already on is drawn plain, the way the design does it; a lock is
  // for the ones you would have to get past to use.
  function locked(net: var): bool {
    if (!net || net.connected) return false
    return net.security !== WifiSecurityType.Open
      && net.security !== WifiSecurityType.Owe
      && net.security !== WifiSecurityType.Unknown
  }

  // three significant figures, which is how the design writes both 1.20 GB and
  // 46.1 MB.
  function formatBytes(bytes: real): string {
    const units = ["B", "KB", "MB", "GB", "TB"]

    let value = bytes
    let unit = 0
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024
      unit++
    }

    return `${value.toFixed(value >= 100 ? 0 : value >= 10 ? 1 : 2)} ${units[unit]}`
  }

  // the band and the address describe an association rather than the moment, so
  // they are read when one appears instead of on the poll: two nmcli spawns every
  // tick would be the most expensive thing in the panel, and would nearly always
  // come back with what they said last time.
  function describe(): void {
    if (!root.detailed || !root.connected) return
    if (!band.running) band.running = true
    if (!addr.running) addr.running = true
  }

  onDetailedChanged: {
    if (root.detailed) {
      root.describe()
      return
    }

    // cleared on the way out rather than on the way in, so reopening the row can
    // never show a reading taken before it was last shut.
    root.pingMs = -1
    root.loss = -1
    root.band = ""
    root.ip = ""
  }

  onSsidChanged: root.describe()

  // scanning costs airtime and wakes the radio, so the device only looks around
  // while someone is reading the list.
  Binding {
    target: root.device
    property: "scannerEnabled"
    value: root.detailed
    when: root.device !== null
  }

  Timer {
    interval: 10000
    repeat: true
    triggeredOnStart: true
    running: root.detailed && root.connected

    onTriggered: {
      rx.reload()
      tx.reload()

      // a three packet ping takes about two seconds, so it cannot overrun a ten
      // second tick -- but a link that has just gone away can hold one open.
      if (!ping.running) ping.running = true
    }
  }

  // the kernel's own counters, which are free to read and need no process.
  FileView {
    id: rx

    path: root.device ? `/sys/class/net/${root.device.name}/statistics/rx_bytes` : ""

    // FileView.text() is a function, not a notifying property, so a binding on it
    // would read once and never update. push instead.
    onLoaded: root.rxBytes = parseFloat(rx.text()) || 0
  }

  FileView {
    id: tx

    path: root.device ? `/sys/class/net/${root.device.name}/statistics/tx_bytes` : ""

    onLoaded: root.txBytes = parseFloat(tx.text()) || 0
  }

  Process {
    id: ping

    // -q for the summary only, and -n so a reverse lookup cannot stall the run.
    command: ["ping", "-n", "-q", "-c", "3", "-W", "1", root.pingTarget]

    stdout: StdioCollector {
      id: pingOut

      onStreamFinished: {
        const rtt = pingOut.text.match(/= [\d.]+\/([\d.]+)\//)
        const lost = pingOut.text.match(/([\d.]+)% packet loss/)

        root.pingMs = rtt ? Math.round(parseFloat(rtt[1])) : -1
        root.loss = lost ? parseFloat(lost[1]) : -1
      }
    }
  }

  Process {
    id: band

    // the frequency is the one thing here nmcli knows and the api does not. no
    // rescan: this reads the table NetworkManager already has.
    command: ["nmcli", "-t", "-f", "IN-USE,FREQ", "device", "wifi", "list", "--rescan", "no"]

    stdout: StdioCollector {
      id: bandOut

      onStreamFinished: {
        // nmcli stars the associated ap in the first field.
        const line = bandOut.text.split("\n").find(l => l.startsWith("*:"))
        const mhz = line ? parseInt(line.split(":")[1]) : 0

        if (mhz >= 5900) root.band = "6 GHz"
        else if (mhz >= 4000) root.band = "5 GHz"
        else if (mhz > 0) root.band = "2.4 GHz"
        else root.band = ""
      }
    }
  }

  Process {
    id: addr

    command: ["nmcli", "-t", "-f", "IP4.ADDRESS", "device", "show", root.device?.name ?? ""]

    stdout: StdioCollector {
      id: addrOut

      onStreamFinished: {
        // "IP4.ADDRESS[1]:10.0.0.110/24". the prefix length belongs to the subnet
        // rather than to this machine, and the design shows the address alone.
        const line = addrOut.text.split("\n").find(l => l.startsWith("IP4.ADDRESS"))

        root.ip = line ? line.slice(line.indexOf(":") + 1).split("/")[0] : ""
      }
    }
  }
}
