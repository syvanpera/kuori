import QtQuick
import qs.theme

// the all-caps heading over a block in the system panel -- ENABLED, OUTPUT,
// HISTORY, TEMPERATURE and the rest. one component because the design gives every
// one of them the same face, and there are a dozen of them.
Text {
  id: root

  color: Theme.sysCap
  font.family: Theme.monoFont
  font.pixelSize: Theme.sysCapSize
  font.weight: Font.Medium
  font.letterSpacing: Theme.sysCapSpacing
}
