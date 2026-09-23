pragma Singleton
import QtQuick
import Quickshell
import qs.services

// everything the launcher can list, as rows. it lives here rather than in the
// panel because the panel's window is destroyed on close: rows built there were
// built again on every open, window lookups and all, and a row object that does
// not survive the close cannot be the stable identity ScriptModel wants.
Singleton {
  id: root

  // adding a category is adding a line here and a source below. these are all six
  // the design has, in its order -- it dropped ACTIONS before that one was built.
  readonly property var categories: [
    { id: "all", label: "ALL" },
    { id: "apps", label: "APPS" },

    // the one category kept out of ALL. it is a log of what you copied, and a log
    // interleaved with applications by name is noise in both directions.
    { id: "clipboard", label: "CLIPBOARD", inAll: false },

    { id: "wallpapers", label: "WALLPAPERS" },
    { id: "windows", label: "WINDOWS" },
    { id: "power", label: "POWER" }
  ]

  // every result is one of these, whatever produced it:
  //
  //   { cat, name, detail, icon, image, glyph, path, run }
  //
  // plus the fields AppSearch scores -- genericName, keywords, comment, command --
  // named after the desktop entry ones on purpose, so a wallpaper can be ranked
  // without the ranking knowing it is not an app.
  //
  // the rows themselves have to be stable objects: ScriptModel diffs by identity,
  // so building them per keystroke would read as a whole new list, reset the view
  // and reload every icon. these are rebuilt only when a source changes.

  // NoDisplay entries are still in `applications`: they are .desktop files that
  // exist to claim a mime type or a startup class, not to be launched.
  readonly property var entries: DesktopEntries.applications.values.filter(entry => !entry.noDisplay)

  readonly property var appRows: root.entries.map(entry => ({
    cat: "apps",
    name: entry.name,

    // the design's second line. genericName is the field meant for it; a comment
    // is prose but better than nothing, and the id at least says what will launch.
    detail: entry.genericName || entry.comment || entry.id || "",
    icon: entry.icon ?? "",
    image: "",
    glyph: "",
    genericName: entry.genericName,
    keywords: entry.keywords,
    comment: entry.comment,
    command: entry.command,
    run: () => root.launchEntry(entry)
  }))

  readonly property var wallpaperRows: {
    const rows = Wallpapers.files.map(file => ({
      cat: "wallpapers",
      name: file.name,
      detail: file.file,
      icon: "",
      image: file.url,
      glyph: "",
      path: file.path,

      // not shown anywhere -- it is here so that typing "wallpaper" in ALL finds
      // the pictures, the way typing an app's category would.
      genericName: "Wallpaper",
      keywords: [file.file],
      comment: "",
      command: [file.path],
      run: () => Wallpapers.set(file.path)
    }))

    // the design's own last row. it is a verb rather than a picture, so it gets a
    // glyph where the others get a thumbnail.
    rows.push({
      cat: "wallpapers",
      name: "Random wallpaper",
      detail: "Pick one at random",
      icon: "",
      image: "",
      glyph: "shuffle",

      // after the pictures, where the design puts it, rather than wherever an
      // alphabetical sort would drop the word "random".
      last: true,
      genericName: "Wallpaper",
      keywords: ["random", "shuffle"],
      comment: "",
      command: [],
      run: () => Wallpapers.shuffle()
    })

    return rows
  }

  readonly property var clipboardRows: {
    // the design's own icon per kind of entry.
    const glyphs = { text: "terminal", link: "link", image: "image", color: "palette" }

    const rows = Clipboard.entries.map((entry, index) => ({
      cat: "clipboard",
      id: entry.id,
      kind: entry.kind,
      name: entry.text,
      detail: entry.detail,
      icon: "",
      image: "",
      glyph: entry.swatch === "" ? (glyphs[entry.kind] ?? "terminal") : "",
      swatch: entry.swatch,

      // cliphist hands them over newest first, and there is no timestamp anywhere
      // in its store, so the listing's own order is the only recency there is.
      order: index,

      // not shown: it is what makes typing "clip" in this category find anything
      // at all, since the rows are named after their contents.
      genericName: "Clipboard",
      keywords: [],
      comment: "",
      command: [],
      run: () => Clipboard.copy(entry.id)
    }))

    // nothing to clear when there is nothing there, and an empty category should
    // say it is empty rather than offer one useless row.
    if (rows.length === 0) return rows

    rows.push({
      cat: "clipboard",
      name: "Clear clipboard history",
      detail: "Throws away every entry",
      icon: "",
      image: "",
      glyph: "delete_sweep",
      swatch: "",
      last: true,
      genericName: "Clipboard",
      keywords: ["wipe"],
      comment: "",
      command: [],
      run: () => Clipboard.wipe()
    })

    return rows
  }

  readonly property var windowRows: {
    // read the list, do not just call the lookup. DesktopEntries fills in
    // asynchronously -- it climbs from 0 one entry at a time -- and an imperative
    // heuristicLookup() creates no binding dependency, so rows built during the
    // scan would keep their fallback names and glyphs for the life of the panel.
    // this line is what makes them rebuild as the entries arrive.
    const known = DesktopEntries.applications.values

    return Windows.entries.map(entry => {
      // the class is what hyprland knows; the desktop entry is what has a name
      // fit to read and an icon. heuristicLookup exists for exactly this mapping.
      const app = known.length > 0 ? DesktopEntries.heuristicLookup(entry.cls) : null
      const label = app?.name || entry.cls

      return {
        cat: "windows",

        // the design's "kitty — ~/dotfiles". a window with no title is just its
        // application, rather than a name with a dangling dash.
        name: entry.title.length > 0 ? `${label} — ${entry.title}` : label,
        detail: `workspace ${entry.workspace}`,
        icon: app?.icon ?? "",
        image: "",

        // the design draws every window with the same tab glyph. this reaches for
        // the real application icon first and only falls back to that, because a
        // list of identical glyphs is a list you have to read rather than scan.
        glyph: app ? "" : "tab",
        swatch: "",

        // hyprland's own focus order, so the window you were last in is at the
        // top and the one you are in now is first of all.
        order: entry.history,
        marked: entry.history === 0,

        genericName: "Window",
        keywords: [entry.cls],
        comment: "",
        command: [],
        run: () => Windows.focus(entry)
      }
    })
  }

  // static, and the command is the whole of what each one does, so there is no
  // service behind these: the design's three rows with the design's own commands.
  //
  // they keep the design's order rather than taking the ranking's alphabetical
  // one, and that is not cosmetic: sorted by name "Power off" comes first, so
  // opening this category and pressing return -- the one gesture the launcher
  // teaches -- would shut the machine down. safest first.
  readonly property var powerRows: [
    { name: "Suspend", glyph: "bedtime", command: ["systemctl", "suspend"] },
    { name: "Reboot", glyph: "restart_alt", command: ["systemctl", "reboot"] },
    { name: "Power off", glyph: "power_settings_new", command: ["systemctl", "poweroff"] }
  ].map((action, index) => ({
    cat: "power",
    name: action.name,

    // the command itself, which is the design's second line here. for an app
    // "Web Browser" says more than "chromium", but there is nothing to say about
    // Reboot that `systemctl reboot` does not say better.
    detail: action.command.join(" "),
    icon: "",
    image: "",
    glyph: action.glyph,
    swatch: "",
    order: index,
    genericName: "Power",
    keywords: ["power"],
    comment: "",
    command: action.command,
    run: () => Quickshell.execDetached(action.command)
  }))

  readonly property var rows: root.appRows.concat(root.wallpaperRows, root.clipboardRows, root.windowRows, root.powerRows)

  function launchEntry(entry: var): void {
    // uwsm puts the app in its own systemd scope, so it survives this shell being
    // reloaded and lands in the right slice. it takes a desktop entry id and
    // expands the Exec field codes and Terminal=true itself, which is why nothing
    // here has to know that ghostty exists.
    const id = entry.id.endsWith(".desktop") ? entry.id : `${entry.id}.desktop`

    // execDetached double-forks, so nothing is left parented to quickshell.
    Quickshell.execDetached(["uwsm", "app", "--", id])
  }
}
