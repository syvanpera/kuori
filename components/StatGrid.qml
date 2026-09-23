import QtQuick
import qs.theme

// readings in two equal columns of whatever the gutter leaves, the way the
// network and battery rows lay out their numbers. each child is `cell` wide.
Grid {
  id: root

  readonly property real cell: (root.width - Theme.sysStatGapH) / 2

  columns: 2
  columnSpacing: Theme.sysStatGapH
  rowSpacing: Theme.sysStatGapV
}
