import QtQuick
import qs.theme

// a move on the design's one easing curve, css cubic-bezier(.2,.8,.2,1): what a
// tab growing, a panel sliding or a card rising all do. the caller says how long.
NumberAnimation {
  easing.type: Easing.Bezier
  easing.bezierCurve: Theme.easeStandard
}
