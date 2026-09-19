pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

// everything the system tab knows about the wireless link.
//
// Quickshell.Networking answers most of it from NetworkManager directly. four of
// the things the design's panel shows are not in that api at all: the round trip
// time, how many bytes have crossed the interface, the address, and the frequency
// an access point is on. those come from ping, from sysfs and from nmcli, which
// is the only reason this singleton owns processes.
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

  // NetworkDevice.address is the hardware address, so the one the design shows
  // has to come from nmcli.
  property string ip: ""

  // ssid -> "5 GHz". a WifiNetwork carries its signal and its security but not
  // its frequency, and the design puts the band under every available network, so
  // the whole table is read at once rather than per row.
  property var bands: ({})

  property real rxBytes: 0
  property real txBytes: 0

  readonly property var device: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
  readonly property bool enabled: Networking.wifiEnabled
  readonly property bool connected: root.device?.connected ?? false
  readonly property var network: root.device?.networks.values.find(n => n.connected) ?? null
  readonly property string ssid: root.network?.name ?? ""
  readonly property string band: root.bandFor(root.ssid)

  // one entry per ssid in range, the connected one first and the rest by signal.
  // sorted here rather than in the view because this only re-runs when the scan
  // finds or loses an access point: signalStrength moves constantly, and sorting
  // on that directly would have the rows swapping places under the pointer.
  readonly property var scanned: {
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

  // the design splits the list in two: what NetworkManager has a saved profile
  // for, and what is merely in the air.
  readonly property var known: root.scanned.filter(n => n.known)
  readonly property var available: root.scanned.filter(n => !n.known)

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

  // the short names the design writes under an available network. the enum splits
  // psk from eap and this does not: what the line is for is how hard it would be
  // to join, and both answers to that are "you need a password".
  function securityName(net: var): string {
    switch (net?.security) {
      case WifiSecurityType.Wpa3SuiteB192:
      case WifiSecurityType.Sae: return "WPA3"
      case WifiSecurityType.Wpa2Eap:
      case WifiSecurityType.Wpa2Psk: return "WPA2"
      case WifiSecurityType.WpaEap:
      case WifiSecurityType.WpaPsk: return "WPA"
      case WifiSecurityType.StaticWep:
      case WifiSecurityType.DynamicWep: return "WEP"
      case WifiSecurityType.Leap: return "LEAP"
      // owe encrypts without a secret, so it is open in the sense the line means.
      case WifiSecurityType.Owe:
      case WifiSecurityType.Open: return "Open"
      default: return ""
    }
  }

  function bandFor(ssid: string): string {
    return root.bands[ssid] ?? ""
  }

  // "WPA2 · 5 GHz", or whichever half of it we actually know.
  function detail(net: var): string {
    return [root.securityName(net), root.bandFor(net?.name ?? "")].filter(part => part).join(" · ")
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

  // nmcli -t separates fields with a colon and backslash-escapes the colons
  // inside one, which an ssid and a mac address are both full of.
  function fields(line: string): var {
    const out = []
    let cur = ""

    for (let i = 0; i < line.length; i++) {
      if (line[i] === "\\") {
        cur += line[++i] ?? ""
      } else if (line[i] === ":") {
        out.push(cur)
        cur = ""
      } else {
        cur += line[i]
      }
    }

    out.push(cur)
    return out
  }

  onDetailedChanged: {
    if (root.detailed) {
      addr.running = true
      return
    }

    // cleared on the way out rather than on the way in, so reopening the row can
    // never show a reading taken before it was last shut.
    root.pingMs = -1
    root.loss = -1
    root.ip = ""
    root.bands = ({})
  }

  // the address belongs to an association rather than to the moment, so it is
  // read when one appears instead of on every tick.
  onSsidChanged: if (root.detailed) addr.running = true

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
    running: root.detailed && root.enabled

    onTriggered: {
      // the band table is polled rather than read once: the list grows as the
      // scan finds things, and a row without its band looks broken.
      if (!scan.running) scan.running = true

      if (!root.connected) return

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
    id: scan

    // no rescan: this reads the table NetworkManager already has, which the
    // device's own scanner is keeping fresh while the row is open.
    command: ["nmcli", "-t", "-f", "IN-USE,SSID,FREQ", "device", "wifi", "list", "--rescan", "no"]

    stdout: StdioCollector {
      id: scanOut

      onStreamFinished: {
        const bands = {}

        for (const line of scanOut.text.split("\n")) {
          if (!line) continue

          const [inUse, ssid, freq] = root.fields(line)
          const mhz = parseInt(freq)
          if (!ssid || !mhz) continue

          // nmcli sorts by signal, so the first row for a name is its strongest
          // radio -- except for the one we are associated with, whose own band is
          // the only true answer for the reading above. a mesh routinely answers
          // to one ssid on both bands at once, which is exactly this case.
          if (bands[ssid] && inUse !== "*") continue

          bands[ssid] = mhz >= 5900 ? "6 GHz" : mhz >= 4000 ? "5 GHz" : "2.4 GHz"
        }

        root.bands = bands
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
