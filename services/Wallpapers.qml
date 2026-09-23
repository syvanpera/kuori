pragma Singleton
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs.services

// the wallpaper library, and which of it is on screen.
//
// awww owns the picture itself: it runs as a user unit, keeps its own cache of the
// last image per output, and its ExecStartPost restores that at login. so nothing
// here remembers a choice across a session -- this lists the directory, asks awww
// what it is showing, and tells it to show something else.
Singleton {
  id: root

  readonly property string directory: `${Quickshell.env("HOME")}/Pictures/wallpapers`

  // the absolute path awww reports. empty while it is showing a flat colour, which
  // is what a daemon nobody has told anything displays.
  property string current: ""

  // one record per image: { path, url, file, name }. rebuilt only when the folder
  // changes, never per keystroke -- the launcher's rows are diffed by object
  // identity, so handing out fresh objects between two frames would reset the view
  // and reload every thumbnail.
  property var files: []

  // what qt can draw, not what awww can read. awww takes a wider set, but a
  // wallpaper qt cannot decode would be a row with an empty tile, which is worse
  // than not offering it. jp2, tiff and webp are here because qtimageformats is
  // installed; without it qtbase reads only png, jpeg, gif and ico.
  readonly property var extensions: ["jpg", "jpeg", "png", "webp", "gif", "bmp", "tif", "tiff", "jp2"]

  // awww's own defaults are a step-wise fade at 90 steps. a timed fade is the same
  // idea with a duration this can state, which is the only reason it is spelled
  // out rather than left off.
  readonly property var transition: ["-t", "fade", "--transition-duration", "0.4", "--transition-fps", "60"]

  function set(path: string): void {
    if (path.length === 0) return

    apply.command = ["awww", "img", path].concat(root.transition)
    apply.running = true
  }

  // ask awww again. the lock screen draws the wallpaper too, and is the other
  // thing that wants to know what is showing right now.
  function refresh(): void {
    query.running = true
  }

  // deliberately never the one already showing: a shuffle that can land on what is
  // already there looks like it did nothing.
  function shuffle(): void {
    const others = root.files.filter(file => file.path !== root.current)

    if (others.length === 0) return

    root.set(others[Math.floor(Math.random() * others.length)].path)
  }

  // "0-winding-road" -> "Winding Road". the leading number is a sort key someone
  // typed to order the folder, not part of the name, and the separators are what
  // a filename has instead of spaces.
  function prettify(base: string): string {
    const words = base.replace(/^\d+[-_ ]*/, "").replace(/[-_]+/g, " ").trim()

    if (words.length === 0) return base

    return words.replace(/\b\w/g, first => first.toUpperCase())
  }

  function rebuild(): void {
    const next = []

    for (let i = 0; i < folder.count; i++) {
      const path = folder.get(i, "filePath")

      next.push({
        path: path,
        url: `file://${path}`,
        file: folder.get(i, "fileName"),
        name: root.prettify(folder.get(i, "fileBaseName"))
      })
    }

    root.files = next
  }

  // a live listing, so a wallpaper dropped into the folder shows up without the
  // shell being restarted. nothing in Quickshell.Io lists a directory, and this
  // costs no process at all.
  FolderListModel {
    id: folder

    folder: `file://${root.directory}`
    nameFilters: root.extensions.map(extension => `*.${extension}`)
    caseSensitive: false
    showDirs: false
    sortField: FolderListModel.Name

    onCountChanged: root.rebuild()
    onStatusChanged: if (folder.status === FolderListModel.Ready) root.rebuild()
  }

  // awww prints a line per output ending in "currently displaying: image: <path>",
  // or "color: <hex>" when it has never been given one. there is no other way to
  // ask it, and asking beats remembering: the wallpaper can also be changed from a
  // terminal.
  Process {
    id: query

    command: ["awww", "query"]
    running: true

    stdout: StdioCollector {
      id: reply

      onStreamFinished: {
        const match = /currently displaying: image: (.*)$/m.exec(reply.text)

        root.current = match ? match[1].trim() : ""
      }
    }
  }

  Process {
    id: apply

    // read it back rather than assume the write landed: awww is the truth, and it
    // refuses a path it cannot decode without this shell hearing about it.
    onExited: query.running = true
  }

  // the launcher is the only thing that shows this, so the cheapest moment to
  // re-read is when it opens. a wallpaper set from a terminal in between would
  // otherwise leave the wrong row marked.
  Connections {
    target: Launcher

    function onOpenedChanged(): void {
      if (Launcher.opened) query.running = true
    }
  }
}
