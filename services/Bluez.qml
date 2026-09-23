pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import qs.services
import qs.theme

// the bluetooth adapter, what it can see, and the pairing agent that answers bluez.
//
// named for the daemon rather than the radio because Quickshell.Bluetooth already
// exports a singleton called Bluetooth, and a file in qs.services with that name
// could not say which one it meant. this is the only place that imports it.
Singleton {
  id: root

  // the panel raises this while the bluetooth row is folded open. discovery wakes
  // the radio and keeps it scanning, so it stops the moment the row folds away --
  // the same bargain the wifi scan makes.
  property bool detailed: false

  // the address of a device we have asked to connect and not heard back about,
  // and the one whose last attempt came to nothing. a bluetooth device that has
  // stopped advertising cannot be connected to by the host, and bluez reports
  // that by simply never arriving -- so without these a refused click and a dead
  // click look exactly the same.
  property string pending: ""
  property string failed: ""

  // whether that last attempt died pairing rather than connecting, so the row can
  // say which.
  property bool failedPairing: false

  // what bluez is asking right now, or null:
  //
  //   { kind, path, address, code, entered, cancelled }
  //
  // kind is one of the design's five cards -- confirm, compare, type, pin,
  // incoming. `code` is what compare and type show, `entered` how many digits of
  // it a keyboard has had typed on it, or -1 for a legacy pin that nobody counts.
  property var request: null

  // the last request, kept while its card folds away so the card does not empty
  // itself on screen -- the confirmation dialog's lastPending.
  property var lastRequest: null

  // which of the card's two buttons the keyboard is on: 0 the primary, 1 the other.
  // it starts on the primary, as the confirmation dialog's does, because getting
  // here took a deliberate click already.
  property int selected: 0

  // the pin card's field, pushed from the card so enter can submit what it holds.
  property string pin: ""

  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property bool enabled: root.adapter?.enabled ?? false

  readonly property var devices: root.enabled ? Bluetooth.devices.values : []

  // the device `pending` names, for whatever is drawing the attempt.
  readonly property var pendingDevice: root.devices.find(d => d.address === root.pending) ?? null

  readonly property var requestDevice: root.request
    ? root.devices.find(d => d.dbusPath === root.request.path) ?? null
    : null

  // a request the user can still answer. a cancelled one is only being shown.
  readonly property bool asking: root.request !== null && !root.request.cancelled

  // pairing opens a link of its own, so a device reads connected while it is
  // still pairing, with none of its profiles up -- and would jump into CONNECTED
  // with its card, mid-question. only a device that is done pairing is connected.
  readonly property var connected: root.devices.filter(d => root.isConnected(d))

  // everything the adapter knows about that is not currently on: devices paired
  // before, and whatever discovery turns up while the row is open.
  //
  // sorted, and paired first. bluez hands them over in whatever order it learned
  // them, so an unsorted list rearranges itself under the pointer every time
  // discovery finds something -- and the row you meant to click is a device you
  // own, not a stranger's fridge.
  readonly property var available: root.devices
    .filter(d => !root.isConnected(d))
    .sort((a, b) => (b.paired - a.paired) || a.name.localeCompare(b.name))

  // the one glyph for the radio as a whole, which the strip and the panel row both
  // show -- glyph() below is for a device. the design draws a plain `bluetooth`
  // everywhere; the strip had grown a ladder of its own, and two ladders for one
  // radio is the problem Network.linkGlyph was written to end.
  readonly property string radioGlyph: {
    if (!root.enabled) return "bluetooth_disabled"
    if (root.connected.length > 0) return "bluetooth_connected"
    return "bluetooth"
  }

  // what the collapsed row says on the right. the first connected device, because
  // the row has space for one name and that is the one worth having.
  readonly property string summary: {
    if (!root.enabled) return "Off"
    if (root.connected.length === 0) return "Not connected"
    if (root.connected.length === 1) return root.connected[0].name
    return `${root.connected[0].name} +${root.connected.length - 1}`
  }

  // the name the card and the toast call the device by.
  readonly property string requestName: {
    const shown = root.request ?? root.lastRequest
    if (!shown) return ""

    return root.devices.find(d => d.dbusPath === shown.path)?.name ?? shown.address
  }

  // "482 913". the design splits a six-digit code in the middle, which is how a
  // phone shows the same number; anything else is a legacy pin, shown whole. the
  // card and the toast both write the code this way.
  function spacedCode(code: string): string {
    return code.length === 6 ? `${code.slice(0, 3)} ${code.slice(3)}` : code
  }

  function isConnected(device: var): bool {
    return device.connected && device.paired && !device.pairing
      && device.address !== root.pending
      && device.address !== (root.request?.address ?? "")
  }

  function setEnabled(on: bool): void {
    if (root.adapter) root.adapter.enabled = on
  }

  // a click on a device is a request to change its mind about being connected.
  // one that was never paired is paired first, and trusted once it is, which is
  // what lets a mouse or a keyboard reconnect by itself after that. whatever bluez
  // wants to ask on the way arrives through the agent below.
  function toggle(device: var): void {
    if (!device || root.request) return

    root.failed = ""

    if (device.connected && device.paired) {
      device.disconnect()
      return
    }

    root.pending = device.address

    if (device.paired) device.connect()
    else device.pair()
  }

  // whether this device is in the middle of changing its mind.
  function busy(device: var): bool {
    if (!device) return false
    return device.address === root.pending
      || device.pairing
      || device.state === BluetoothDeviceState.Connecting
      || device.state === BluetoothDeviceState.Disconnecting
  }

  // bluez reports a freedesktop icon name, which the design draws as material
  // symbols. anything unrecognised keeps the bluetooth mark rather than guessing.
  function glyph(device: var): string {
    switch (device?.icon) {
      case "audio-headset":
      case "audio-headphones": return "headphones"
      case "audio-card":
      case "audio-speakers": return "speaker"
      case "input-mouse": return "mouse"
      case "input-keyboard": return "keyboard"
      case "input-gaming": return "sports_esports"
      case "input-tablet": return "stylus"
      case "phone": return "mobile"
      case "computer": return "computer"
      case "multimedia-player": return "music_note"
      case "printer": return "print"
      case "camera-photo": return "photo_camera"
      case "camera-video": return "videocam"
      case "video-display": return "tv"
      case "watch": return "watch"
      default: return "bluetooth"
    }
  }

  // the design writes a device's charge under its name. most bluetooth devices
  // never report one, so the line is simply absent rather than showing a zero.
  function charge(device: var): string {
    if (!device?.batteryAvailable) return ""
    return `${Math.round(device.battery * 100)}%`
  }

  // the card's primary button: pair, or allow.
  function accept(): void {
    const request = root.request
    if (!root.asking || request.kind === "type") return

    if (request.kind === "pin") {
      if (root.pin === "") return
      agent.write(`answer ${root.pin}\n`)
    } else {
      agent.write("yes\n")
    }

    // a pairing the other side started is ours to finish too: once it lands it is
    // trusted and connected like one this shell asked for.
    root.pending = request.address
    root.fold()
  }

  // cancel, or deny. a keyboard showing a code has no question waiting -- bluez
  // was told the code at once -- so the pairing itself is what gets called off.
  function reject(): void {
    const request = root.request
    if (!root.asking) return

    if (request.kind === "type") root.requestDevice?.cancelPair()
    else agent.write("no\n")

    // said no on purpose, so the row goes quiet rather than reporting a failure.
    root.pending = ""
    root.fold()
  }

  function fold(): void {
    root.request = null
    root.pin = ""
  }

  function giveUp(): void {
    if (root.pending === "") return

    root.failed = root.pending
    root.failedPairing = !(root.pendingDevice?.paired ?? true)
    root.pending = ""
    root.fold()
    linger.restart()
  }

  // bluez names a device by its object path, which ends in its address.
  function addressOf(path: string): string {
    return path.slice(path.lastIndexOf("/dev_") + 5).replace(/_/g, ":")
  }

  function ask(kind: string, event: var): void {
    const address = root.addressOf(event.device)

    // a keyboard reporting another key typed is the same card moving on, not a new
    // question: keep the selection where it is.
    const again = root.request?.kind === kind && root.request?.path === event.device
    if (!again) {
      root.selected = 0
      root.pin = ""
    }

    root.request = {
      kind: kind,
      path: event.device,
      address: address,
      code: event.code ?? "",
      entered: event.entered ?? -1,
      cancelled: false
    }
    root.lastRequest = root.request

    // the toasts stand aside for the system panel, so a question arriving while
    // the panel is out on another row would be seen by nobody. show it instead.
    if (Notches.open === "system") Notches.row = "bluetooth"
  }

  function heard(line: string): void {
    let event
    try {
      event = JSON.parse(line)
    } catch (e) {
      console.warn(`bluetooth agent: unreadable line: ${line}`)
      return
    }

    switch (event.type) {
      case "ready":
        console.info("bluetooth: this shell is the pairing agent")
        return
      // a yes-or-no with no code, which is how bluez asks about a mouse or a
      // headset. the same call is how a device that started the pairing itself
      // asks to be let in, and the only way to tell them apart is whether this
      // shell asked for the pairing.
      case "authorize":
        root.ask(root.addressOf(event.device) === root.pending ? "confirm" : "incoming", event)
        return
      case "confirm":
        root.ask("compare", event)
        return
      case "display":
        root.ask("type", event)
        return
      case "passkey":
      case "pincode":
        root.ask("pin", event)
        return
      // a service on a device that is not trusted. every device this shell pairs is
      // trusted as it lands, so this is a stranger, or one paired elsewhere and
      // never trusted here -- let a paired one in and nobody else.
      case "service": {
        const device = root.devices.find(d => d.dbusPath === event.device)
        agent.write(device?.paired ? "yes\n" : "no\n")
        return
      }
      case "cancel":
        if (!root.request) return

        root.request = Object.assign({}, root.request, { cancelled: true })
        root.lastRequest = root.request
        root.pending = ""
        cancelLinger.restart()
        return
    }
  }

  // bluez asks an agent to confirm every pairing, even one with no code, and
  // refuses outright when there is none -- and quickshell cannot export the d-bus
  // object an agent is. so a helper registers it and relays the questions here.
  //
  // it runs for as long as the shell does, panel open or not, because a device
  // can ask to pair at any time. restarted when it dies, but not in a tight loop.
  Process {
    id: agent

    command: ["python3", Quickshell.shellPath("scripts/kuori-btagent")]
    running: true
    stdinEnabled: true

    stdout: SplitParser {
      onRead: line => root.heard(line)
    }

    stderr: SplitParser {
      onRead: line => console.warn(`bluetooth agent: ${line}`)
    }

    onExited: (code, status) => {
      console.warn(`bluetooth agent: exited ${code}; restarting`)
      root.fold()
      respawn.restart()
    }
  }

  Timer {
    id: respawn

    interval: 5000

    onTriggered: agent.running = true
  }

  Connections {
    target: root.pendingDevice

    // only a paired device has actually arrived, and only one that has stopped
    // pairing has failed.
    function onStateChanged(): void {
      const device = root.pendingDevice
      if (!device || !device.paired || device.pairing) return

      if (device.state === BluetoothDeviceState.Connected) {
        root.pending = ""
        return
      }

      // back to where it started without ever arriving. bluez refuses a device
      // that is not advertising, which is most of them a moment after the host
      // dropped them -- hence the mouse you have to switch off and on again.
      if (device.state === BluetoothDeviceState.Disconnected) root.giveUp()
    }

    function onPairedChanged(): void {
      const device = root.pendingDevice
      if (!device?.paired) return

      device.trusted = true

      if (device.connected) root.pending = ""
      else device.connect()
    }

    function onPairingChanged(): void {
      if (!root.pendingDevice?.pairing) pairSettle.restart()
    }
  }

  // a keyboard's card has no button that ends it: the pairing finishing does.
  Connections {
    target: root.requestDevice

    function onPairedChanged(): void {
      if (root.requestDevice?.paired && root.request?.kind === "type") root.fold()
    }
  }

  // over without having paired: refused, or it wanted a passkey. asked a moment
  // later, because pairing and paired can arrive from bluez in either order, and
  // a pairing that ended one property ahead of succeeding is not a failure.
  Timer {
    id: pairSettle

    interval: 500

    onTriggered: {
      const device = root.pendingDevice
      if (device && !device.pairing && !device.paired) root.giveUp()
    }
  }

  // and in case it never moves at all. not while bluez is waiting on the user,
  // who may take their time finding the code on a phone.
  Timer {
    interval: 20000
    running: root.pending !== "" && root.request === null

    onTriggered: root.giveUp()
  }

  Timer {
    id: linger

    interval: Theme.btFailLinger

    onTriggered: root.failed = ""
  }

  Timer {
    id: cancelLinger

    interval: Theme.btCancelLinger

    onTriggered: if (root.request?.cancelled) root.fold()
  }

  // every card and state without a device that wants pairing: each call fakes the
  // line the agent would have printed, against the first device in AVAILABLE. an
  // answer goes to the real agent, which has no question waiting and ignores it.
  IpcHandler {
    target: "bluetooth"

    function mock(kind: string): void {
      const device = root.available[0]
      if (!device) return

      const types = { confirm: "authorize", incoming: "authorize", compare: "confirm", type: "display", pin: "passkey" }
      if (!types[kind]) return

      root.fold()
      root.pending = kind === "confirm" ? device.address : ""

      const event = { type: types[kind], device: device.dbusPath }
      if (kind === "compare") event.code = "482913"
      if (kind === "type") Object.assign(event, { code: "731045", entered: 0 })

      root.heard(JSON.stringify(event))
    }

    function typed(count: int): void {
      if (root.request?.kind !== "type") return
      root.heard(JSON.stringify({ type: "display", device: root.request.path, code: root.request.code, entered: count }))
    }

    function cancel(): void {
      root.heard(JSON.stringify({ type: "cancel" }))
    }

    function fail(): void {
      root.pending = root.request?.address ?? root.available[0]?.address ?? ""
      root.giveUp()
    }
  }

  // discovery is what fills the available list with things that were never paired.
  Binding {
    target: root.adapter
    property: "discovering"
    value: root.detailed && root.enabled
    when: root.adapter !== null
  }
}
