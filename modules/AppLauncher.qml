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

  // which button the keyboard is on while a confirmation is up: true for the
  // action, false for Cancel. it starts on the action because the card says "ENTER
  // to confirm" and because getting here took a deliberate return already.
  property bool confirmChoice: true

  // the row waiting on a yes or no, or null. the design confirms every POWER row
  // and nothing else, so the category is what decides -- a row does not carry a
  // flag saying it is dangerous.
  property var pending: null

  // hovering selects, but only once the pointer has actually moved. the arrow keys
  // slide the list under a stationary pointer, and the hover that produces is not
  // a choice anyone made.
  property bool mouseArmed: false

  readonly property var categories: LauncherRows.categories

  readonly property var pool: {
    if (Launcher.category !== "all") return LauncherRows.rows.filter(row => row.cat === Launcher.category)

    const shown = root.categories.filter(category => category.inAll !== false).map(category => category.id)

    return LauncherRows.rows.filter(row => shown.indexOf(row.cat) !== -1)
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
  // it: placing it by the current height would glide the whole panel up and down
  // every time a query changed the row count. exactly one of the grid and the
  // empty-state line is ever visible, and the grid tops out at launcherGridMax --
  // its viewport is defined as that less its own padding -- so the tall state can
  // be worked out without ever being rendered.
  readonly property int fullHeight: layout.implicitHeight
    - (resultsBox.visible ? resultsBox.implicitHeight : 0)
    - (emptyLabel.visible ? emptyLabel.implicitHeight : 0)

    // the preview is left out on purpose: counted in, switching to the clipboard
    // would lift the whole panel to make room. left out, the top stays where
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
  // right, which belong to the caret. ctrl+j and ctrl+k are the exception, with
  // ctrl+h and ctrl+l beside them to reach the other column. wrapping at both
  // ends because a box showing five and a half rows of a longer list gives no
  // hint that you have hit the bottom, and a dead arrow key reads as a bug.
  function step(delta: int): void {
    if (root.count === 0) return

    const next = (root.selectedIndex + delta) % root.count

    root.selectedIndex = next < 0 ? next + root.count : next
    root.mouseArmed = false
  }

  function jumpTo(index: int): void {
    root.selectedIndex = Math.max(0, Math.min(index, root.count - 1))
    root.mouseArmed = false
  }

  // a whole row, staying in the same column. it wraps to the far end of that
  // column rather than by the list's length, which with an odd count would land
  // in the other one.
  function stepRow(delta: int): void {
    if (root.count === 0) return

    const column = root.selectedIndex % grid.columns
    let next = root.selectedIndex + delta * grid.columns

    if (next >= root.count) {
      next = column
    } else if (next < 0) {
      next = (Math.ceil(root.count / grid.columns) - 1) * grid.columns + column
      if (next >= root.count) next -= grid.columns
    }

    root.selectedIndex = next
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
      root.confirmChoice = true
      return
    }

    row.run()
    Launcher.close()
  }

  // return, whatever is on screen: the answer to a confirmation, or the selected
  // row. it is a function because the two keys that mean it -- return and the
  // numpad's enter -- each have their own handler.
  function answer(): void {
    if (root.pending) {
      root.resolve(root.confirmChoice)
      return
    }

    root.activate(root.selected)
  }

  function resolve(confirmed: bool): void {
    const row = root.pending

    root.pending = null

    if (!confirmed || !row) return

    row.run()
    Launcher.close()
  }

  // the objects in `values` are LauncherRows' own rows, not wrappers carrying a
  // score. ScriptModel diffs by object identity, so a reshuffle comes out as moves
  // and the delegates under the pointer survive; a fresh wrapper object per
  // keystroke would look like a whole new list, reset the view and reload every
  // icon.
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

      Field {
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

        // every one of these has to answer the confirmation itself when one is up.
        // **the specific Keys handlers fire before Keys.onPressed and default to
        // accepted**, so the branch down there never sees return, escape, up, down
        // or tab -- which is exactly how a confirmation ended up re-activating the
        // row behind it and escape closed the whole launcher.
        Keys.onEscapePressed: root.pending ? root.resolve(false) : Launcher.close()
        Keys.onReturnPressed: root.answer()

        // the numpad's enter is a different key.
        Keys.onEnterPressed: root.answer()
        Keys.onUpPressed: if (!root.pending) root.step(-1)
        Keys.onDownPressed: if (!root.pending) root.step(1)

        // tab walks the chips rather than the results: the arrows and ctrl+hjkl
        // already cover the list, and the chips are otherwise mouse only.
        Keys.onTabPressed: root.pending ? root.confirmChoice = !root.confirmChoice : root.stepCategory(1)
        Keys.onBacktabPressed: root.pending ? root.confirmChoice = !root.confirmChoice : root.stepCategory(-1)

        Keys.onPressed: event => {
          // a confirmation owns the keyboard while it is up: the arrows move between
          // its buttons and everything else is swallowed rather than typed into a
          // field nobody can see behind the card. the keys with handlers of their
          // own never reach here at all -- see above.
          if (root.pending) {
            // the card's two buttons are laid out left to right, so the arrows pick
            // one rather than toggling: pressing left twice should still leave you
            // on Cancel. return and escape are handled above, where they arrive.
            if (event.key === Qt.Key_Left || (event.key === Qt.Key_H && (event.modifiers & Qt.ControlModifier))) root.confirmChoice = false
            else if (event.key === Qt.Key_Right || (event.key === Qt.Key_L && (event.modifiers & Qt.ControlModifier))) root.confirmChoice = true

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
          // ctrl+hjkl is the same idea for vim hands, but spatial: it moves over the
          // grid as drawn, h and l across the two columns and j and k a whole row.
          // the plain arrows keep to reading order, because bare left and right
          // belong to the caret.
          const withCtrl = {
            [Qt.Key_N]: () => root.step(1),
            [Qt.Key_P]: () => root.step(-1),
            [Qt.Key_J]: () => root.stepRow(1),
            [Qt.Key_K]: () => root.stepRow(-1),
            [Qt.Key_H]: () => root.step(-1),
            [Qt.Key_L]: () => root.step(1),
            [Qt.Key_Home]: () => root.jumpTo(0),
            [Qt.Key_End]: () => root.jumpTo(root.count - 1)
          }

          // with or without a modifier: nothing else wants them.
          const either = {
            [Qt.Key_PageDown]: () => root.step(grid.pageStep),
            [Qt.Key_PageUp]: () => root.step(-grid.pageStep)
          }

          const move = (jump ? withCtrl[event.key] : undefined) ?? either[event.key]

          if (move) {
            move()
            event.accepted = true
          }
        }

        placeholder: "Search apps and commands"
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

        readonly property int columns: 2

        // how far a page key moves: whole rows, at least one.
        readonly property int pageStep: Math.max(1, Math.floor(grid.height / grid.cellHeight)) * grid.columns

        // each cell carries half the design's 4px gutter on every side, so the view
        // starts half a gutter outside the 10px padding and the gap between two
        // cells adds back up to 4.
        x: Theme.launcherGridPadding - Theme.launcherGridGap / 2
        y: Theme.launcherGridTop - Theme.launcherGridGap / 2
        width: parent.width - grid.x * 2
        height: Math.min(grid.contentHeight, resultsBox.viewport)

        cellWidth: grid.width / grid.columns
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

        KeyHint {
          anchors.verticalCenter: parent.verticalCenter

          key: "↑↓"
          label: "navigate"
        }

        KeyHint {
          anchors.verticalCenter: parent.verticalCenter

          key: "ENTER"
          label: "launch"
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
