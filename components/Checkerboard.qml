import QtQuick
import qs.theme

// the squares behind a transparent image, so that transparency reads as
// transparency rather than as a dark colour.
//
// plain rectangles rather than a Canvas or a shader: the design writes this as a
// repeating conic gradient, and the cheapest honest equivalent here is the tiles
// themselves. only half of them exist, they never change, and the scene graph
// batches them into one draw call -- where a Canvas would cost a framebuffer of
// its own for a pattern that never moves.
Item {
  id: root

  property int tile: Theme.clipCheckerTile

  readonly property int columns: Math.ceil(root.width / root.tile)
  readonly property int rows: Math.ceil(root.height / root.tile)

  // the lit squares in a row: every other one, starting on the first square in an
  // even row and on the second in an odd one. with an odd number of columns an odd
  // row has one fewer, and that last square lands past the edge, where the clip
  // takes it -- simpler than counting rows two ways.
  readonly property int perRow: Math.ceil(root.columns / 2)

  clip: true

  // only the squares that are drawn. a model of every square with half of them
  // hidden builds twice the items and rebuilds all of them on every resize.
  Repeater {
    model: root.perRow * root.rows

    Rectangle {
      required property int index

      readonly property int row: Math.floor(index / root.perRow)
      readonly property int column: (index % root.perRow) * 2 + row % 2

      x: column * root.tile
      y: row * root.tile
      width: root.tile
      height: root.tile

      color: Theme.clipPreviewChecker
    }
  }
}
