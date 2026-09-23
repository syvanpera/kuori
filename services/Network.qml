pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

// everything the system tab knows about the network: the wire, the radio, and
// whichever of the two is carrying traffic.
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

  // the ssid whose row is open for a passphrase, "" for none. only one at a time,
  // and clearing it is what folds the field away again.
  property string selected: ""

  // what the last refused join said, shown under the row that asked. it clears
  // itself after a while so the row goes back to offering another try.
  property string error: ""

  readonly property var device: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null

  // every ethernet interface, which on a laptop is usually none and sometimes a
  // dock. the panel hides its section when there are none, rather than offering a
  // switch for a port the machine does not have.
  readonly property var wiredDevices: Networking.devices.values.filter(d => d.type === DeviceType.Wired)

  // the wire wins when both are up, which is also what NetworkManager's default
  // route metrics say: ethernet is 100, wifi 600. so the readings follow the
  // interface the packets actually leave by.
  readonly property var wired: root.wiredDevices.find(d => d.connected) ?? null
  readonly property bool onWire: root.wired !== null
  readonly property var linkDevice: root.onWire ? root.wired : (root.connected ? root.device : null)
  readonly property bool online: root.linkDevice !== null

  readonly property bool enabled: Networking.wifiEnabled
  readonly property bool connected: root.device?.connected ?? false
  readonly property var network: root.device?.networks.values.find(n => n.connected) ?? null
  readonly property string ssid: root.network?.name ?? ""
  readonly property string band: root.bandFor(root.ssid)

  // whether there is a link to draw bars for at all, and how strong it is. the tab's
  // strip reads both, rather than finding the device and the association itself:
  // two walks of the same list can disagree with each other mid-scan.
  readonly property bool linked: root.enabled && root.network !== null
  readonly property real strength: root.network?.signalStrength ?? 0

  // what a radio with no link looks like, kept beside those two so the whole glyph
  // family lives in one place -- glyph() below is the rest of it.
  readonly property string offGlyph: "wifi_off"

  // the one glyph for the network as a whole, which the strip and the row header
  // both show. the design's own ladder: the wire, then the radio, then nothing.
  readonly property string linkGlyph: {
    if (root.onWire) return "lan"
    return root.linked ? root.glyph(root.strength) : root.offGlyph
  }

  // what the row header says beside it.
  readonly property string linkName: {
    if (root.onWire) return "Ethernet"
    if (root.linked) return root.ssid
    return root.enabled ? "Not connected" : "Offline"
  }

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

  // NetworkManager answers a device disconnect by blocking autoconnect on it, so
  // switched off stays off until switched on again, cable or no cable. coming back
  // means activating the profile the device would have chosen for itself.
  function setWired(dev: var, on: bool): void {
    if (!dev || !dev.hasLink) return

    if (!on) {
      dev.disconnect()
      return
    }

    if (dev.network) {
      dev.network.connect()
      return
    }

    // a wire with no saved profile to hand yet: nmcli lets NetworkManager pick or
    // make one, which is what plugging in would have done.
    wiredUp.command = ["nmcli", "device", "connect", dev.name]
    wiredUp.running = true
  }

  // "1 Gbps", "100 Mbps". NetworkManager reports the negotiated speed in Mb/s,
  // and 0 when it does not know.
  function speedName(mbps: int): string {
    if (mbps <= 0) return ""
    if (mbps >= 1000) return `${+(mbps / 1000).toFixed(1)} Gbps`
    return `${mbps} Mbps`
  }

  function wiredConnecting(dev: var): bool {
    return dev?.state === ConnectionState.Connecting
  }

  // the line under an ethernet row, in the design's three states plus the one
  // between them: dhcp can take a few seconds, and a switch that moved with
  // nothing to say for itself looks like it did nothing.
  function wiredDetail(dev: var): string {
    if (!dev?.hasLink) return "Cable unplugged"
    if (dev.connected) return ["Connected", root.speedName(dev.linkSpeed)].filter(part => part).join(" · ")
    if (root.wiredConnecting(dev)) return "Connecting…"
    return "Disconnected"
  }

  // what a click on a network does. one we have credentials for -- saved, or not
  // locked at all -- we simply join. anything else needs a passphrase first, so
  // the click opens the field rather than doing something that cannot work.
  function select(net: var): void {
    if (!net || net.connected) return

    root.error = ""

    if (net.known || !root.locked(net)) {
      root.selected = ""
      net.connect()
      return
    }

    root.selected = root.selected === net.name ? "" : net.name
  }

  function join(psk: string): void {
    const net = root.scanned.find(n => n.name === root.selected)
    if (!net || !psk) return

    root.error = ""
    net.connectWithPsk(psk)
  }

  // NetworkManager answers a bad passphrase by asking for secrets again, or by
  // giving up on the handshake. both mean the same thing to whoever typed it.
  function reasonText(reason: var): string {
    switch (reason) {
      case ConnectionFailReason.NoSecrets:
      case ConnectionFailReason.WifiAuthTimeout: return "Incorrect passphrase"
      case ConnectionFailReason.WifiNetworkLost: return "Network went away"
      case ConnectionFailReason.WifiClientDisconnected:
      case ConnectionFailReason.WifiClientFailed: return "Could not connect"
      default: return "Could not connect"
    }
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

  // the one ladder for how many bars a network has, asked by both the tab's strip
  // and the rows in the panel -- which used different tables and different glyph
  // families until this existed, so the same access point could be three bars in
  // one place and two in the other.
  //
  // the steps are this shell's own: the design draws every wifi glyph as a plain
  // `wifi` and only its mock data carries a weaker one. the family is the design's
  // though, which is why there is no three-bar step -- material symbols has none.
  function glyph(strength: real): string {
    if (strength >= 0.66) return "wifi"
    if (strength >= 0.33) return "wifi_2_bar"

    return "wifi_1_bar"
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
      root.readAddress()
      return
    }

    // cleared on the way out rather than on the way in, so reopening the row can
    // never show a reading taken before it was last shut.
    root.pingMs = -1
    root.loss = -1
    root.ip = ""
    root.bands = ({})
    root.selected = ""
    root.error = ""
  }

  // the address belongs to an association rather than to the moment, so it is
  // read when one appears instead of on every tick -- and again when the traffic
  // moves between the wire and the radio.
  onSsidChanged: root.readAddress()
  onLinkDeviceChanged: root.readAddress()

  function readAddress(): void {
    if (!root.detailed) return

    root.ip = ""
    if (root.linkDevice) addr.running = true
  }

  // a refusal is reported by the network that refused, so this follows whichever
  // one the field is open for.
  Connections {
    target: root.scanned.find(n => n.name === root.selected) ?? null

    function onConnectionFailed(reason: var): void {
      root.error = root.reasonText(reason)
      linger.restart()
    }
  }

  Timer {
    id: linger

    interval: 1800

    onTriggered: root.error = ""
  }

  // a network that comes up is one that took the passphrase, so the field it was
  // typed into has nothing left to ask.
  onConnectedChanged: if (root.connected) root.selected = ""

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
    running: root.detailed

    onTriggered: {
      // the band table is polled rather than read once: the list grows as the
      // scan finds things, and a row without its band looks broken.
      if (root.enabled && !scan.running) scan.running = true

      if (!root.online) return

      rx.reload()
      tx.reload()

      // a three packet ping takes about two seconds, so it cannot overrun a ten
      // second tick -- but a link that has just gone away can hold one open.
      if (!ping.running) ping.running = true
    }
  }

  // the kernel's own counters, which are free to read and need no process. they
  // follow the link rather than the radio, so on a cable they count the cable.
  FileView {
    id: rx

    path: root.linkDevice ? `/sys/class/net/${root.linkDevice.name}/statistics/rx_bytes` : ""

    // FileView.text() is a function, not a notifying property, so a binding on it
    // would read once and never update. push instead.
    onLoaded: root.rxBytes = parseFloat(rx.text()) || 0
  }

  FileView {
    id: tx

    path: root.linkDevice ? `/sys/class/net/${root.linkDevice.name}/statistics/tx_bytes` : ""

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

    command: ["nmcli", "-t", "-f", "IP4.ADDRESS", "device", "show", root.linkDevice?.name ?? ""]

    stdout: StdioCollector {
      id: addrOut

      onStreamFinished: {
        // "IP4.ADDRESS[1]:192.0.2.10/24". the prefix length belongs to the subnet
        // rather than to this machine, and the design shows the address alone.
        const line = addrOut.text.split("\n").find(l => l.startsWith("IP4.ADDRESS"))

        root.ip = line ? line.slice(line.indexOf(":") + 1).split("/")[0] : ""
      }
    }
  }

  Process {
    id: wiredUp
  }
}
