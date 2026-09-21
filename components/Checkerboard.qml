import QtQuick
import qs.theme

// the squares behind a transparent image, so that transparency reads as
// transparency rather than as a dark colour.
//
// plain rectangles rather than a Canvas or a shader: the design writes this as a
// repeating conic gradient, and the cheapest honest equivalent here is the tiles
// themselves. only half of them are drawn, they never change, and the scene graph
// batches them into one draw call -- where a Canvas would cost a framebuffer of
// its own for a pattern that never moves.
Item {
  id: root

  property int tile: 16

  readonly property int columns: Math.ceil(root.width / root.tile)
  readonly property int rows: Math.ceil(root.height / root.tile)

  clip: true

  Repeater {
    model: root.columns * root.rows

    Rectangle {
      required property int index

      readonly property int column: index % root.columns
      readonly property int row: Math.floor(index / root.columns)

      // every other square, in both directions.
      visible: (column + row) % 2 === 0

      x: column * root.tile
      y: row * root.tile
      width: root.tile
      height: root.tile

      color: Theme.clipPreviewChecker
    }
  }
}
