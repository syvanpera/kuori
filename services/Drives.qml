pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.theme

// external drives: what is plugged in, and what the panel's buttons do to it.
// udisks does the work, through scripts/kuori-drives, which also posts the
// toasts -- they carry buttons, and notify-send with an action blocks until it is
// answered.
Singleton {
  id: root

  // the panel raises this while the drives row is folded open: how full a
  // mounted drive is only means something while somebody is looking at it.
  property bool detailed: false

  // what the helper last said is plugged in:
  //
  //   { id, name, label, glyph, fs, size, used, mount, encrypted, locked, crypto }
  property var drives: []

  // the ipc's fakes, beside the real ones and out of the helper's way: its next
  // listing replaces `drives` and would take them with it.
  property var mocks: []

  // what this shell is in the middle of doing to a drive, which udisks has no word
  // for: { id: { st, err, errN } }, st one of unmounting, busy, unlocking.
  property var doing: ({})

  // drives ejected and gone, kept for a moment saying they are safe to remove, the
  // way the design has them linger: { id: { drive, until } }.
  property var ghosts: ({})

  // a drive whose folder button asked for a mount, to be opened once it has one.
  property string opening: ""

  // every card in the row, in the order the helper lists them, then the ghosts.
  //
  //   drive + { st, err, errN }
  //
  // st is the design's: mounted, locked, unlocking, unmounting, busy, safe -- and
  // unmounted, which it has no word for, for a drive that was already plugged in
  // when the shell started, or one ejected and still plugged in.
  readonly property var rows: {
    const listed = root.drives.concat(root.mocks).map(drive => {
      const doing = root.doing[drive.id] ?? {}
      // what this shell is doing first, then a udisks job somebody else started,
      // then what the drive simply is.
      const running = { mounting: "mounting", unlocking: "unlocking" }[drive.job ?? ""]
      const st = doing.st ?? running ?? (drive.locked ? "locked" : drive.mount ? "mounted" : "unmounted")

      return Object.assign({}, drive, {
        st: st, err: doing.err ?? "", errN: doing.errN ?? 0,
        flushing: doing.flushing ?? false, holders: doing.holders ?? []
      })
    })

    const gone = Object.values(root.ghosts)
      .filter(ghost => !root.drives.concat(root.mocks).some(drive => drive.id === ghost.drive.id))
      .map(ghost => Object.assign({}, ghost.drive, { st: "safe", err: "", errN: 0, flushing: false, holders: [] }))

    return listed.concat(gone)
  }

  // the design counts what is still attached, and says the rest is safe.
  readonly property int attached: root.rows.filter(row => row.st !== "safe").length

  readonly property string summary: {
    if (root.attached === 0) return "Safe to remove"
    return root.attached === 1 ? "1 drive" : `${root.attached} drives`
  }

  // the strip's tip: the one drive by name, or how many.
  readonly property string title: root.rows.length === 1 ? root.rows[0].name : `${root.rows.length} drives`

  function tell(request: var): void {
    helper.tell(JSON.stringify(request))
  }

  function patch(id: string, change: var): void {
    const next = Object.assign({}, root.doing)

    if (change === null) delete next[id]
    else next[id] = Object.assign({}, next[id] ?? {}, change)

    root.doing = next
  }

  function row(id: string): var {
    return root.rows.find(row => row.id === id) ?? null
  }

  // the folder button. a drive that is not mounted yet is mounted first, and
  // opened when the helper reports where.
  function open(id: string): void {
    const drive = root.row(id)
    if (!drive) return

    if (drive.mount === "") {
      root.opening = id
      root.mount(id)
      return
    }

    // through the file manager's d-bus name rather than xdg-open, which falls back
    // to a browser whenever the file manager exits unhappy.
    root.tell({ cmd: "show", path: drive.mount })
    Notches.close()
  }

  // not in the design, whose drives are all mounted by it: an unmounted one gets a
  // Mount button, as a locked one gets Unlock.
  function mount(id: string): void {
    const drive = root.row(id)
    if (!drive || drive.st !== "unmounted") return

    root.patch(id, { st: "mounting" })
    root.tell({ cmd: "mount", id: id })
  }

  function eject(id: string, force: bool): void {
    const drive = root.row(id)
    if (!drive || ["mounting", "unmounting", "unlocking", "safe"].includes(drive.st)) return

    root.patch(id, { st: "unmounting", since: Date.now(), flushing: false, holders: [] })
    root.tell({ cmd: "eject", id: id, force: force, power: Theme.drvPowerOff })
  }

  // typing again takes the last refusal away, as the design's field does.
  function retyping(id: string): void {
    if (root.doing[id]?.err) root.patch(id, { err: "" })
  }

  // "keep mounted": the busy card goes back to being a mounted drive.
  function keep(id: string): void {
    root.patch(id, null)
  }

  function unlock(id: string, passphrase: string): void {
    const drive = root.row(id)
    if (!drive || drive.st !== "locked" || passphrase === "") return

    root.patch(id, { st: "unlocking", err: "" })
    root.tell({ cmd: "unlock", id: id, passphrase: passphrase })
  }

  // udisks passes on libblockdev's words for a wrong passphrase, which are
  // "Operation not permitted" under the device's path. the design uses
  // cryptsetup's own, which say what actually went wrong.
  function refusal(message: string): string {
    if (/not permitted|no key|incorrect passphrase/i.test(message)) return "No key available with this passphrase."
    return message.replace(/^Error unlocking [^:]*:\s*/, "")
  }

  // `extra` carries what only some toasts need: `replaces`, the key of one still up
  // that this takes the place of, and `sticky`, to stay up until replaced.
  function toast(key: string, summary: string, glyph: string, tone: string, actions: var, extra: var): void {
    root.tell(Object.assign({ cmd: "notify", key: key, summary: summary, glyph: glyph, tone: tone, actions: actions }, extra ?? {}))
  }

  // an unmount that is still going after a moment is the kernel writing out what
  // was copied, and pulling the drive then loses it. the card says so, and a toast
  // does too, which the one saying it is safe then takes the place of -- gnome's
  // "writing data" does the same.
  function flushing(id: string): void {
    const drive = root.row(id)
    root.patch(id, { flushing: true })
    root.toast(`flush ${id}`, `Writing data to ${drive?.name ?? "the drive"}. Don't unplug it until it is finished.`,
      "hourglass_top", "", [], { sticky: true })
  }

  // the key of the writing toast for this drive, if it is up.
  function flushKey(id: string): string {
    return root.doing[id]?.flushing ? `flush ${id}` : ""
  }

  function heard(event: var): void {
    const name = event.name ?? root.row(event.id ?? "")?.name ?? "Drive"

    switch (event.type) {
      case "ready":
        root.tell({ cmd: "automount", on: Theme.drvAutomount })
        return
      case "drives":
        root.drives = event.list
        root.settle()
        return
      case "mounted":
        root.toast(`mounted ${event.id}`, `${name} mounted at ${event.mount}`, event.glyph, "",
          [["open", "Open"], ["eject", "Eject"]])
        return
      case "encrypted":
        root.toast(`unlock ${event.id}`, `${name} is encrypted. Enter its passphrase to mount it.`, "lock", "",
          [["unlock", "Unlock"]])
        return
      case "unlocked":
        root.patch(event.id, null)
        root.toast(`opened ${event.id}`, `${name} unlocked and mounted at ${event.mount}`, "lock_open", "",
          [["open", "Open"]])
        return
      case "wrong": {
        const errN = (root.doing[event.id]?.errN ?? 0) + 1
        root.patch(event.id, { st: "locked", err: root.refusal(event.message), errN: errN })
        return
      }
      case "busy":
        if (root.flushKey(event.id)) root.tell({ cmd: "withdraw", key: root.flushKey(event.id) })
        root.patch(event.id, { st: "busy", flushing: false, holders: event.holders ?? [] })
        return
      // a drive that was only unmounted stays listed, and reads "Safe to remove"
      // for as long as a powered-off one lingers before it settles back to not
      // mounted, or locked. the ghost covers the other case, a drive that has gone.
      case "safe": {
        const drive = root.row(event.id)
        const replaces = root.flushKey(event.id)
        root.patch(event.id, { st: "safe", err: "", flushing: false })

        if (drive) {
          const next = Object.assign({}, root.ghosts)
          next[event.id] = { drive: drive, until: Date.now() + Theme.drvSafeLinger }
          root.ghosts = next
          linger.restart()
        }

        root.toast(`safe ${event.id}`, `${name} can be safely removed`, "eject", "dim", [], { replaces: replaces })
        return
      }
      case "failed": {
        const replaces = root.flushKey(event.id)
        root.patch(event.id, null)
        root.toast(`failed ${event.id}`, `${name}: ${event.message}`, "error", "warning", [], { replaces: replaces })
        return
      }
      case "yanked":
        root.patch(event.id, null)
        root.toast(`yanked ${event.id}`, `${name} was removed without ejecting. Unsaved data may be lost.`,
          "warning", "warning", [])
        return
      case "action":
        root.acted(event.key, event.action)
        return
      // nothing owns org.freedesktop.FileManager1: a file manager that does not
      // implement it, or none at all. xdg-open is the last resort.
      case "unshown":
        Quickshell.execDetached(["xdg-open", event.path])
        return
    }
  }

  // a toast's button. the key says which toast, and so which drive.
  function acted(key: string, action: string): void {
    const id = key.slice(key.indexOf(" ") + 1)

    if (action === "open") root.open(id)
    else if (action === "eject") root.eject(id, false)
    else if (action === "unlock") Notches.showRow("drives", "")
  }

  // after each listing: forget what was being done to a drive that has gone, open
  // one that has just been mounted for the folder button, and fold the row away
  // when there is nothing left in it.
  function settle(): void {
    const present = new Set(root.drives.concat(root.mocks).map(drive => drive.id))
    const stale = Object.keys(root.doing).filter(id => !present.has(id))
    if (stale.length > 0) {
      const next = Object.assign({}, root.doing)
      for (const id of stale) delete next[id]
      root.doing = next
    }

    for (const drive of root.drives) {
      const doing = root.doing[drive.id]

      // an unmount somebody else started -- nautilus, a terminal, this shell before
      // a restart -- is shown as one of ours, writing data and all.
      if (drive.job === "unmounting" && !doing) {
        root.patch(drive.id, { st: "unmounting", since: drive.since, flushing: false, holders: [], external: true })
      } else if (doing?.external && doing.st === "unmounting" && drive.job !== "unmounting") {
        // and over, with nobody to hear the helper say so.
        const replaces = root.flushKey(drive.id)
        root.patch(drive.id, null)
        if (drive.mount === "") {
          root.toast(`safe ${drive.id}`, `${drive.name} can be safely removed`, "eject", "dim", [], { replaces: replaces })
        } else if (replaces) {
          root.tell({ cmd: "withdraw", key: replaces })
        }
      } else if (doing?.st === "mounting" && drive.mount !== "") {
        root.patch(drive.id, null)
      }
    }

    if (root.opening !== "") {
      const drive = root.drives.find(drive => drive.id === root.opening)
      if (!drive) root.opening = ""
      else if (drive.mount !== "") {
        root.opening = ""
        root.open(drive.id)
      }
    }
  }

  onRowsChanged: if (root.rows.length === 0 && Notches.row === "drives") Notches.row = ""

  onDetailedChanged: if (root.detailed) root.tell({ cmd: "refresh" })

  Helper {
    id: helper

    script: "kuori-drives"
    name: "drives"

    onEvent: message => root.heard(message)

    // whatever was in flight died with it. what is plugged in is asked again when
    // it says it is ready.
    onExited: root.doing = ({})
  }

  // watches the unmounts in flight for one that has taken long enough to be a
  // flush. it only runs while one is unmounting and not yet said to be writing.
  Timer {
    interval: Theme.drvFlushNotice
    repeat: true
    running: Object.values(root.doing).some(doing => doing.st === "unmounting" && !doing.flushing)

    onTriggered: {
      const now = Date.now()

      for (const [id, doing] of Object.entries(root.doing)) {
        if (doing.st === "unmounting" && !doing.flushing && now - (doing.since ?? now) >= Theme.drvFlushNotice) {
          root.flushing(id)
        }
      }
    }
  }

  Timer {
    id: linger

    interval: Theme.drvSafeLinger

    onTriggered: {
      const now = Date.now()
      const next = {}

      for (const [id, ghost] of Object.entries(root.ghosts)) {
        if (ghost.until > now) next[id] = ghost
        else if (root.doing[id]?.st === "safe") root.patch(id, null)
      }

      root.ghosts = next
      if (Object.keys(next).length > 0) linger.restart()
    }
  }

  // how full a mounted drive is changes as it is written to, and nothing announces
  // that. asked again while the row is open, the way the network row polls.
  Timer {
    interval: Theme.sysNetPoll
    repeat: true
    running: root.detailed && root.drives.some(drive => drive.mount !== "")

    onTriggered: root.tell({ cmd: "refresh" })
  }

  // every card without a drive to plug in, for looking at them: each fakes the
  // listing the helper would have sent, beside whatever is really attached.
  IpcHandler {
    target: "drives"

    function mock(state: string): void {
      const fake = {
        id: "/mock/sandisk", name: "SanDisk Ultra", label: "SANDISK", glyph: "usb", fs: "exFAT",
        size: 29.4e9, used: 12.1e9, mount: "/run/media/mock/SANDISK", encrypted: false, locked: false, crypto: ""
      }

      if (["locked", "wrong", "unlocking"].includes(state)) Object.assign(fake, { id: "/mock/t7", name: "Samsung T7", glyph: "hard_drive",
        fs: "LUKS2", size: 465.8e9, used: 0, mount: "", encrypted: true, locked: true, crypto: "LUKS2" })

      // the same drive once unlocked, so the card can be watched going from one to
      // the other.
      if (state === "unlocked") Object.assign(fake, { id: "/mock/t7", name: "Samsung T7", glyph: "hard_drive",
        fs: "ext4", size: 465.8e9, used: 212.4e9, mount: "/run/media/mock/T7", encrypted: true, locked: false, crypto: "LUKS2" })

      root.mocks = root.mocks.filter(drive => drive.id !== fake.id).concat([fake])

      if (state === "busy") root.patch(fake.id, { st: "busy", holders: ["nautilus", "cp"] })
      else if (state === "unmounting" || state === "unlocking") root.patch(fake.id, { st: state })
      // an unmount that has been going long enough to be writing data out.
      else if (state === "flushing") root.patch(fake.id, { st: "unmounting", since: 0, flushing: false })
      else if (state === "wrong") root.patch(fake.id, { st: "locked", err: root.refusal("Operation not permitted"), errN: 1 })
      else if (state === "yanked") root.heard({ type: "yanked", id: fake.id, name: fake.name })
      // what the helper says once an eject has unmounted it: safe for a moment,
      // then not mounted.
      else if (state === "ejected") {
        root.mocks = root.mocks.map(drive => drive.id === fake.id ? Object.assign({}, drive, { mount: "", used: 0 }) : drive)
        root.heard({ type: "safe", id: fake.id, name: fake.name })
      }
      else if (state === "mounted") root.heard({ type: "mounted", id: fake.id, name: fake.name, glyph: fake.glyph, mount: fake.mount })
    }

    function clear(): void {
      root.mocks = []
    }
  }
}
