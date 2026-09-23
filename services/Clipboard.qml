pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.theme

// the clipboard history, as cliphist keeps it.
//
// cliphist is a store rather than a daemon: two wl-paste watchers declared in
// their flake feed it, and one of those filters out anything a password manager
// offered. so this only reads the list, puts an entry back on the clipboard, and
// throws the lot away.
Singleton {
  id: root

  // newest first, which is the order cliphist lists them in and the only order a
  // clipboard history makes sense in. one record per entry:
  // { id, text, kind, detail, swatch }
  property var entries: []

  // what a binary entry looks like in the listing:
  // "[[ binary data 26 KiB png 400x229 ]]". there is no filename anywhere in the
  // store, so the type and the size are all there is to say about a picture.
  readonly property var binaryPattern: /^\[\[\s*binary data\s+(.+?)\s+(\w+)\s+(\d+)x(\d+)\s*\]\]$/

  readonly property var colorPattern: /^#(?:[0-9a-f]{3}|[0-9a-f]{4}|[0-9a-f]{6}|[0-9a-f]{8})$/i
  readonly property var linkPattern: /^[a-z][a-z0-9+.-]*:\/\//i

  // the entry the preview pane is showing, decoded in full -- the list only ever
  // carries cliphist's own 100-character preview, and the pane's whole point is
  // what the entry actually is.
  property string previewId: ""
  property string previewText: ""
  property int previewBytes: 0
  property string previewImage: ""

  function refresh(): void {
    list.running = true
  }

  // arrowing through the list would decode once per keystroke, so the work waits
  // until the selection settles. asking for the same entry twice is free.
  function preview(id: string): void {
    if (id === root.previewId) return

    root.previewId = id
    root.previewText = ""
    root.previewBytes = 0
    root.previewImage = ""

    if (id.length === 0) return

    settle.restart()
  }

  function decode(): void {
    // one decode at a time. a process that is still running cannot be handed a
    // new command -- the assignment would be dropped and its answer shown for the
    // wrong entry -- so the one in flight finishes and its onExited asks again.
    if (toFile.running || toText.running) return

    const entry = root.entries.find(e => e.id === root.previewId)

    if (!entry) return

    // an image is bytes, and bytes must not pass through a QML string: it goes to
    // a file the Image element can load, named for the entry so the same one is
    // never decoded twice.
    if (entry.kind === "image") {
      const path = Quickshell.cachePath(`clip-${entry.id}`)

      // the id and the path go in as arguments rather than as text spliced into
      // the script. cliphist's own listing cannot produce an id with a quote in
      // it today, and that is exactly the kind of thing that stops being true
      // without anyone here hearing about it.
      toFile.command = ["sh", "-c", `cliphist decode "$1" > "$2"`, "sh", entry.id, path]
      toFile.target = path
      toFile.entry = entry.id
      toFile.running = true
      return
    }

    toText.command = ["cliphist", "decode", entry.id]
    toText.entry = entry.id
    toText.running = true
  }

  // what the design's meta line counts. JS strings are UTF-16, and a byte count
  // that calls "ä" one byte would be wrong about most of what gets copied.
  function utf8Bytes(text: string): int {
    let n = 0

    for (const character of text) {
      const point = character.codePointAt(0)

      n += point < 0x80 ? 1 : point < 0x800 ? 2 : point < 0x10000 ? 3 : 4
    }

    return n
  }

  // back onto the clipboard, not into the focused window: pasting for someone is
  // a keystroke this shell has no business synthesising, and the entry may be an
  // image anyway. a shell because the whole point is the pipe -- decode writes
  // bytes, including binary ones, that must not pass through a string.
  function copy(id: string): void {
    Quickshell.execDetached(["sh", "-c", `cliphist decode "$1" | wl-copy`, "sh", id])
  }

  function wipe(): void {
    clear.running = true
  }

  // one line per entry, "<id>\t<preview>". the preview is cliphist's own, capped
  // at 100 characters, so the length of what is actually stored is not knowable
  // from here.
  function parse(listing: string): void {
    const next = []

    for (const line of listing.split("\n")) {
      const tab = line.indexOf("\t")

      if (tab < 1) continue

      const id = line.slice(0, tab)
      const text = line.slice(tab + 1)
      const binary = root.binaryPattern.exec(text)

      if (binary) {
        next.push({
          id: id,
          text: `${binary[2].toUpperCase()} image`,
          kind: "image",
          detail: `${binary[3]}×${binary[4]} · ${binary[1]}`,
          swatch: ""
        })

        continue
      }

      if (root.colorPattern.test(text)) {
        next.push({ id: id, text: text, kind: "color", detail: "Colour", swatch: text })
        continue
      }

      if (root.linkPattern.test(text)) {
        next.push({ id: id, text: text, kind: "link", detail: "Link", swatch: "" })
        continue
      }

      next.push({ id: id, text: text, kind: "text", detail: "Text", swatch: "" })
    }

    root.entries = next
  }

  Process {
    id: list

    command: ["cliphist", "list"]

    // a singleton is not built until something reads it, which here is the panel
    // asking for rows -- by which time Launcher.opened has already changed and
    // the connection below has missed it. so the first listing happens on
    // creation, and the connection covers every open after that.
    running: true

    stdout: StdioCollector {
      id: listing

      onStreamFinished: root.parse(listing.text)
    }
  }

  // every previewed image is decoded to a file of its own, so that switching back
  // to one costs nothing and QML never has to notice a file changing under a URL
  // it has already cached. they are droppings, but they are in the cache
  // directory, and the session starts with none of them.
  Process {
    id: sweepCache

    // the prefix is an argument and the glob is not, which is the whole trick: a
    // quoted "$1" cannot be re-read as script, and the star outside the quotes is
    // still the shell's to expand.
    command: ["sh", "-c", `rm -f "$1"*`, "sh", Quickshell.cachePath("clip-")]
    running: true
  }

  Timer {
    id: settle

    interval: Theme.clipSettle

    onTriggered: root.decode()
  }

  Process {
    id: toText

    // the entry this run is decoding, which by the time it exits may no longer be
    // the one on screen.
    property string entry: ""

    stdout: StdioCollector { id: decoded }

    onExited: exitCode => {
      if (toText.entry !== root.previewId) {
        root.decode()
        return
      }

      if (exitCode !== 0) return

      root.previewText = decoded.text
      root.previewBytes = root.utf8Bytes(decoded.text)
    }
  }

  Process {
    id: toFile

    property string target: ""
    property string entry: ""

    onExited: exitCode => {
      if (toFile.entry !== root.previewId) {
        root.decode()
        return
      }

      if (exitCode !== 0) return

      root.previewImage = `file://${toFile.target}`
    }
  }

  Process {
    id: clear

    command: ["cliphist", "wipe"]

    onExited: root.entries = []
  }

  // the history is only ever shown in the launcher, so that is the one moment it
  // has to be true. copying anything reorders it, and the copy that reordered it
  // usually happened in another window.
  Connections {
    target: Launcher

    function onOpenedChanged(): void {
      if (Launcher.opened) root.refresh()
    }
  }
}
