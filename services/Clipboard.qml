pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

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

  function refresh(): void {
    list.running = true
  }

  // back onto the clipboard, not into the focused window: pasting for someone is
  // a keystroke this shell has no business synthesising, and the entry may be an
  // image anyway. a shell because the whole point is the pipe -- decode writes
  // bytes, including binary ones, that must not pass through a string.
  function copy(id: string): void {
    restore.command = ["sh", "-c", `cliphist decode ${id} | wl-copy`]
    restore.running = true
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

  Process {
    id: restore
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
