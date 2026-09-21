import QtQuick
import Quickshell
import qs.components
import qs.services
import qs.theme

// the launcher panel. owns the query, the selection and the model; the window
// around it owns when it exists and where it sits.
Rectangle {
  id: root

  readonly property alias query: input.text

  property int selectedIndex: 0

  // the row waiting on a yes or no, or null. the design confirms every POWER row
  // and nothing else, so the category is what decides -- a row does not carry a
  // flag saying it is dangerous.
  property var pending: null

  // hovering selects, but only once the pointer has actually moved. the arrow keys
  // slide the list under a stationary pointer, and the hover that produces is not
  // a choice anyone made.
  property bool mouseArmed: false

  // adding a category is adding a line here and a source below. the design has
  // seven; these are the ones with something to show.
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

  readonly property var pool: {
    if (Launcher.category !== "all") return root.rows.filter(row => row.cat === Launcher.category)

    const shown = root.categories.filter(category => category.inAll !== false).map(category => category.id)

    return root.rows.filter(row => shown.indexOf(row.cat) !== -1)
  }

  readonly property var matches: AppSearch.rank(root.pool, root.query)
  readonly property int count: root.matches.length
  readonly property var selected: root.matches[root.selectedIndex] ?? null

  // the preview pane only has anything to say about a clipboard entry. decoding
  // is asked for here rather than in the pane, because the pane does not exist
  // until there is something for it to show.
  readonly property var selectedClip: root.selected?.cat === "clipboard" ? root.selected : null

  onSelectedClipChanged: Clipboard.preview(root.selectedClip?.id ?? "")

  implicitWidth: Theme.launcherWidth
  implicitHeight: layout.implicitHeight

  // the height this panel would have with the grid full, which is what positions
  // it: centring on the current height would glide the whole panel up and down
  // every time a query changed the row count. exactly one of the grid and the
  // empty-state line is ever visible, and the grid tops out at launcherGridMax --
  // its viewport is defined as that less its own padding -- so the tall state can
  // be worked out without ever being rendered.
  readonly property int fullHeight: layout.implicitHeight
    - (resultsBox.visible ? resultsBox.implicitHeight : 0)
    - (emptyLabel.visible ? emptyLabel.implicitHeight : 0)

    // the preview is left out on purpose: counted in, switching to the clipboard
    // would lift the whole panel to re-centre it. left out, the top stays where
    // it is and the pane extends the panel downwards, which is what the grid
    // shrinking already does.
    - (previewBox.visible ? previewBox.implicitHeight : 0)
    + Theme.launcherGridMax

  color: Theme.notch
  radius: Theme.notchRadius

  // the design's overflow:hidden.
  clip: true

  // every keystroke reshuffles the list, and index 3 of the old ranking means
  // nothing in the new one. the best match is always index 0.
  onQueryChanged: root.selectedIndex = 0

  // and a list that shrinks under a selection has to pull it back in range.
  onCountChanged: root.selectedIndex = Math.min(root.selectedIndex, Math.max(0, root.count - 1))

  // the grid never takes focus, so the field can keep it for the whole session and
  // still let the arrow keys drive the list.
  onSelectedIndexChanged: grid.positionViewAtIndex(root.selectedIndex, GridView.Contain)

  Component.onCompleted: input.forceActiveFocus()

  // switching category replaces the list wholesale, and index 3 of the old one
  // means nothing in the new.
  Connections {
    target: Launcher

    function onCategoryChanged(): void {
      root.selectedIndex = 0
    }
  }

  // one item per press, not one visual row. the grid is a ranked list folded into
  // two columns, so "down" means the next best match; moving by a row would skip
  // every second result and leave the other column reachable only with left and
  // right, which belong to the caret. wrapping at both ends because a box showing
  // five and a half rows of a longer list gives no hint that you have hit the
  // bottom, and a dead arrow key reads as a bug.
  function step(delta: int): void {
    if (root.count === 0) return

    const next = (root.selectedIndex + delta) % root.count

    root.selectedIndex = next < 0 ? next + root.count : next
    root.mouseArmed = false
  }

  // the chips, in the order they are drawn. it wraps for the same reason the list
  // does: three chips and a key that dies at each end reads as a bug.
  function stepCategory(delta: int): void {
    const at = root.categories.findIndex(category => category.id === Launcher.category)
    const next = (at + delta + root.categories.length) % root.categories.length

    Launcher.category = root.categories[next].id
  }

  // every row carries what it does, so this stays the same whatever the list is
  // showing. closing afterwards is the design's behaviour for every row, wallpaper
  // rows included -- picking one is an answer, not a browse.
  function activate(row: var): void {
    if (!row) return

    if (row.cat === "power") {
      root.pending = row
      return
    }

    row.run()
    Launcher.close()
  }

  function resolve(confirmed: bool): void {
    const row = root.pending

    root.pending = null

    if (!confirmed || !row) return

    row.run()
    Launcher.close()
  }

  function launchEntry(entry: var): void {
    // uwsm puts the app in its own systemd scope, so it survives this shell being
    // reloaded and lands in the right slice. it takes a desktop entry id and
    // expands the Exec field codes and Terminal=true itself, which is why nothing
    // here has to know that ghostty exists.
    const id = entry.id.endsWith(".desktop") ? entry.id : `${entry.id}.desktop`

    // execDetached double-forks, so nothing is left parented to quickshell.
    Quickshell.execDetached(["uwsm", "app", "--", id])
  }

  // the objects in `values` are the DesktopEntry objects themselves, not wrappers
  // carrying a score. ScriptModel diffs by object identity, so a reshuffle comes
  // out as moves and the delegates under the pointer survive; a fresh wrapper
  // object per keystroke would look like a whole new list, reset the view and
  // reload every icon.
  ScriptModel {
    id: results

    values: root.matches
  }

  // stops a click on the panel's background from reaching the window's scrim and
  // closing the launcher. declared first, so every interactive child is above it.
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.AllButtons
  }

  Column {
    id: layout

    width: parent.width

    Item {
      width: parent.width
      implicitHeight: Math.max(searchIcon.height, input.implicitHeight, escCap.height) + Theme.launcherSearchPadding * 2

      Glyph {
        id: searchIcon

        x: Theme.launcherPadding
        anchors.verticalCenter: parent.verticalCenter

        icon: "search"
        iconColor: Theme.accent
        size: Theme.launcherSearchIcon
      }

      TextInput {
        id: input

        anchors.left: searchIcon.right
        anchors.leftMargin: Theme.launcherRowGap
        anchors.right: escCap.left
        anchors.rightMargin: Theme.launcherRowGap
        anchors.verticalCenter: parent.verticalCenter

        // a QQC2 TextField would arrive with its own background, padding and
        // placeholder to override; a TextInput is the field itself.
        focus: true
        color: Theme.tintBright
        font.family: Theme.monoFont
        font.pixelSize: Theme.launcherInputSize
        font.weight: Font.Medium
        selectByMouse: true

        Keys.onEscapePressed: Launcher.close()
        Keys.onReturnPressed: root.activate(root.selected)

        // the numpad's enter is a different key.
        Keys.onEnterPressed: root.activate(root.selected)
        Keys.onUpPressed: root.step(-1)
        Keys.onDownPressed: root.step(1)
        Keys.onTabPressed: root.step(1)
        Keys.onBacktabPressed: root.step(-1)

        Keys.onPressed: event => {
          // a confirmation owns the keyboard while it is up: return answers it,
          // escape takes it back, and everything else is swallowed rather than
          // typed into a field nobody can see behind the card. this is the first
          // handler to see a key, so accepting here is what stops the specific
          // Keys.onReturnPressed and Keys.onEscapePressed below from firing too.
          if (root.pending) {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.resolve(true)
            else if (event.key === Qt.Key_Escape) root.resolve(false)

            event.accepted = true
            return
          }

          // bare home and end belong to the caret: the field always has focus, and
          // a text box that ignores them is more surprising than a launcher that
          // needs a modifier to jump to the ends.
          const jump = event.modifiers & Qt.ControlModifier

          // ctrl+n and ctrl+p as well as the arrows, the readline pair every shell
          // and editor here already answers to. they keep the hands on the home row
          // while typing a query, which is the whole point of a launcher.
          //
          // ctrl+hjkl is the same idea for vim hands, with one difference: j and k
          // step the results like everything else, but h and l move between the
          // category chips. left and right have no meaning in a ranked list folded
          // into two columns -- the chips are the only thing on this panel actually
          // laid out that way.
          if ((event.key === Qt.Key_N || event.key === Qt.Key_J) && jump) {
            root.step(1)
            event.accepted = true
          } else if ((event.key === Qt.Key_P || event.key === Qt.Key_K) && jump) {
            root.step(-1)
            event.accepted = true
          } else if (event.key === Qt.Key_H && jump) {
            root.stepCategory(-1)
            event.accepted = true
          } else if (event.key === Qt.Key_L && jump) {
            root.stepCategory(1)
            event.accepted = true
          } else if (event.key === Qt.Key_Home && jump) {
            root.selectedIndex = 0
            root.mouseArmed = false
            event.accepted = true
          } else if (event.key === Qt.Key_End && jump) {
            root.selectedIndex = Math.max(0, root.count - 1)
            root.mouseArmed = false
            event.accepted = true
          } else if (event.key === Qt.Key_PageDown) {
            root.step(grid.pageStep)
            event.accepted = true
          } else if (event.key === Qt.Key_PageUp) {
            root.step(-grid.pageStep)
            event.accepted = true
          }
        }

        // TextInput paints its caret in the text colour, and a delegate is the only
        // way to get the design's accent caret.
        cursorDelegate: Rectangle {
          width: 1
          color: Theme.accent
        }

        Text {
          anchors.fill: parent
          visible: input.text.length === 0

          text: "Search apps and commands"
          color: Theme.launcherDimText
          font: input.font
          verticalAlignment: Text.AlignVCenter
        }
      }

      KeyCap {
        id: escCap

        anchors.right: parent.right
        anchors.rightMargin: Theme.launcherPadding
        anchors.verticalCenter: parent.verticalCenter

        label: "ESC"
      }
    }

    Rectangle {
      width: parent.width
      height: 1
      color: Theme.launcherLine
    }

    Item {
      width: parent.width
      implicitHeight: chips.implicitHeight + Theme.launcherChipRowPadding + Theme.launcherChipRowBottom

      Row {
        id: chips

        x: Theme.launcherChipRowPadding
        y: Theme.launcherChipRowPadding
        spacing: Theme.launcherChipSpacing

        Repeater {
          model: root.categories

          CategoryChip {
            required property int index
            required property var modelData

            label: modelData.label
            selected: modelData.id === Launcher.category

            // the singleton, not a local index: a keybind can open the launcher
            // straight into a category, and the chips have to agree with it.
            onClicked: Launcher.category = modelData.id
          }
        }
      }
    }

    Item {
      id: resultsBox

      // the design caps the whole scrolling box, its padding included, at 326.
      readonly property int viewport: Theme.launcherGridMax - Theme.launcherGridTop - Theme.launcherGridBottom + Theme.launcherGridGap

      width: parent.width
      visible: root.count > 0

      // the cells carry half a gutter each at the top and bottom too, so the
      // content block is one whole gutter taller than the rows you can see.
      implicitHeight: grid.height + Theme.launcherGridTop + Theme.launcherGridBottom - Theme.launcherGridGap

      // a GridView, not a Flow in a ScrollView: it is already a Flickable, so a
      // ScrollView around it would nest two, and it only builds the delegates it
      // can show. a Flow would instantiate every row and resolve every icon on
      // every open, to show six.
      GridView {
        id: grid

        // how far a page key moves: whole rows of two, at least one row.
        readonly property int pageStep: Math.max(2, Math.floor(grid.height / grid.cellHeight) * 2)

        // each cell carries half the design's 4px gutter on every side, so the view
        // starts half a gutter outside the 10px padding and the gap between two
        // cells adds back up to 4.
        x: Theme.launcherGridPadding - Theme.launcherGridGap / 2
        y: Theme.launcherGridTop - Theme.launcherGridGap / 2
        width: parent.width - grid.x * 2
        height: Math.min(grid.contentHeight, resultsBox.viewport)

        cellWidth: grid.width / 2
        cellHeight: Theme.launcherRowHeight + Theme.launcherGridGap

        clip: true
        boundsBehavior: Flickable.StopAtBounds

        // the field keeps focus and handles the arrow keys; a grid that took them
        // would move the selection twice.
        keyNavigationEnabled: false

        model: results

        // deliberately no currentIndex binding: the view writes currentIndex itself
        // when the model changes under it, which would break the binding for good.
        // selectedIndex is the single source of truth and the root scrolls the view
        // to it.
        delegate: Item {
          id: cell

          required property int index
          required property var modelData

          width: grid.cellWidth
          height: grid.cellHeight

          LauncherRow {
            anchors.fill: parent
            anchors.margins: Theme.launcherGridGap / 2

            row: cell.modelData
            selected: cell.index === root.selectedIndex
            // a row either knows it is the current one when it is built, or is a
            // wallpaper, whose current-ness changes under a list already on screen.
            marked: cell.modelData.marked === true
              || (cell.modelData.path !== undefined && cell.modelData.path === Wallpapers.current)
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            // a real pointer movement, which is also what arms hover again after
            // the keyboard disarmed it.
            onPositionChanged: {
              root.mouseArmed = true
              root.selectedIndex = cell.index
            }

            onEntered: if (root.mouseArmed) root.selectedIndex = cell.index
            onClicked: root.activate(cell.modelData)
          }
        }
      }
    }

    Item {
      id: previewBox

      width: parent.width

      visible: root.selectedClip !== null
      implicitHeight: preview.implicitHeight + Theme.clipPreviewBottom

      ClipboardPreview {
        id: preview

        x: Theme.clipPreviewMargin
        width: parent.width - Theme.clipPreviewMargin * 2

        row: root.selectedClip
      }
    }

    Text {
      id: emptyLabel

      width: parent.width
      visible: root.count === 0

      leftPadding: Theme.launcherPadding
      rightPadding: Theme.launcherPadding
      topPadding: Theme.launcherGridTop
      bottomPadding: Theme.launcherEmptyBottom

      // with no query there is nothing to have failed to match: the category is
      // simply empty, which is what a clipboard history looks like before
      // anything has been copied.
      text: root.query.length > 0 ? `No matches for “${root.query}”` : "Nothing here yet"
      elide: Text.ElideRight
      color: Theme.launcherDimText
      font.family: Theme.monoFont
      font.pixelSize: Theme.launcherEmptySize
    }

    Rectangle {
      width: parent.width
      height: 1
      color: Theme.launcherLine
    }

    Item {
      width: parent.width
      implicitHeight: hints.implicitHeight + Theme.launcherFooterPaddingV * 2

      Row {
        id: hints

        x: Theme.launcherFooterPaddingH
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.launcherFooterSpacing

        KeyCap {
          anchors.verticalCenter: parent.verticalCenter
          label: "↑↓"
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "navigate"
          color: Theme.launcherDimText
          font.family: Theme.monoFont
          font.pixelSize: Theme.launcherFooterSize
        }

        KeyCap {
          anchors.verticalCenter: parent.verticalCenter
          label: "ENTER"
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "launch"
          color: Theme.launcherDimText
          font.family: Theme.monoFont
          font.pixelSize: Theme.launcherFooterSize
        }
      }

      Text {
        anchors.right: parent.right
        anchors.rightMargin: Theme.launcherFooterPaddingH
        anchors.verticalCenter: parent.verticalCenter

        text: root.count === 1 ? "1 result" : `${root.count} results`
        color: Theme.launcherDimText
        font.family: Theme.monoFont
        font.pixelSize: Theme.launcherFooterSize
      }
    }
  }
}
