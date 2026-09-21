pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.theme

// the session's notification daemon, and what it has heard.
//
// Quickshell owns the D-Bus side: the server registers org.freedesktop.Notifications,
// parses the spec's hints and hands QML a live Notification per message. so this
// keeps two lists -- what is on screen and what has arrived -- and decides when a
// toast has been up long enough.
//
// nothing else on this machine answers that bus name, so if this shell is not
// running, notifications are not merely undrawn: they are dropped.
Singleton {
  id: root

  // silences the toasts and nothing else. a muted notification still lands in the
  // history, which is the only place you would ever find out it arrived.
  property bool dnd: false

  // on screen now, newest first: { key, notification, at, expires }
  property var popups: []

  // everything that arrived, newest first: { key, app, text, image, icon, urgency,
  // at }. plain records rather than the live objects, because the design gives the
  // history no buttons -- and an action can only be invoked on a notification that
  // is still alive, which a dismissed one is not.
  property var history: []

  readonly property int maxHistory: 50

  // when the history was last looked at. the bell on the system strip is the only
  // sign that something arrived, so it has to be able to go out again -- and with
  // fifty entries kept, "is the history empty" would never turn it off.
  // one entry, thrown away. the design hovers a history row like something you can
  // click, and this is the only thing clicking one could sensibly mean.
  function forget(key: int): void {
    root.history = root.history.filter(entry => entry.key !== key)
  }

  property int nextKey: 1

  function toggleDnd(): void {
    root.dnd = !root.dnd

    // muting with toasts already up should clear the screen, not leave four cards
    // sitting there under a switch that says they are silenced.
    if (root.dnd) root.dismissAll()
  }

  // clearing means all of it: a toast still on screen is the same notification as
  // the history entry behind it, and leaving it up after the list it belongs to is
  // gone would be answering only half the request.
  function clear(): void {
    root.history = []
    root.dismissAll()
  }

  function dismiss(key: int): void {
    const popup = root.popups.find(p => p.key === key)

    root.popups = root.popups.filter(p => p.key !== key)
    root.schedule()

    // untracking is what tells the client we are done with it; the object is gone
    // immediately afterwards, so nothing may touch it after this line.
    if (popup) popup.notification.dismiss()
  }

  function dismissAll(): void {
    const going = root.popups

    root.popups = []
    root.schedule()

    for (const popup of going) popup.notification.dismiss()
  }

  // invoke, then take the toast down -- unless the notification says it is
  // resident, which is the spec's way of asking to stay up while its action does
  // something.
  function activate(key: int, action: var): void {
    const popup = root.popups.find(p => p.key === key)

    if (!popup) return

    action.invoke()

    if (!popup.notification.resident) root.dismiss(key)
  }

  // the design's second line is one sentence, and a real notification arrives as
  // two fields: "ops@asteroid.fi" and "Build 2411 passed" are the summary and the
  // body of the same message, which is how the mockup writes it.
  function textOf(notification: var): string {
    if (!notification) return ""

    return [notification.summary, notification.body].filter(part => part && part.length > 0).join(" — ")
  }

  // one timer for every toast on screen, set to whichever expires first, rather
  // than a Timer per card: a QML Timer runs on qt's animation driver and keeps the
  // shell ticking at frame rate while it is pending, so the fewer the better.
  function schedule(): void {
    let soonest = 0

    for (const popup of root.popups) {
      if (popup.expires === 0) continue
      if (soonest === 0 || popup.expires < soonest) soonest = popup.expires
    }

    if (soonest === 0) {
      sweeper.stop()
      return
    }

    sweeper.interval = Math.max(50, soonest - Date.now())
    sweeper.restart()
  }

  function sweep(): void {
    const now = Date.now()
    const done = root.popups.filter(p => p.expires !== 0 && p.expires <= now)

    root.popups = root.popups.filter(p => p.expires === 0 || p.expires > now)
    root.schedule()

    // expire(), not dismiss(): the spec has the client hear a different reason for
    // a notification that timed out than for one somebody waved away.
    for (const popup of done) popup.notification.expire()
  }

  Timer {
    id: sweeper

    onTriggered: root.sweep()
  }

  NotificationServer {
    id: server

    // a reload would otherwise drop whatever is on screen, which during
    // development is most of the time.
    keepOnReload: true

    // declared honestly, because clients ask before they send: no action icons and
    // no inline reply, since the design draws neither. markup is claimed because
    // clients send it whether or not it is claimed, and Text.StyledText understands
    // the small subset the spec allows.
    actionsSupported: true
    actionIconsSupported: false
    bodySupported: true
    bodyMarkupSupported: true
    imageSupported: true
    inlineReplySupported: false

    // there is a history behind the panel, so notifications outlive their toast.
    persistenceSupported: true

    onNotification: notification => {
      // a notification is thrown away the moment this handler returns unless it is
      // tracked. everything below depends on the object still being there.
      notification.tracked = true

      const key = root.nextKey++
      const at = Date.now()

      const text = root.textOf(notification)

      // transient is the spec asking not to be kept, which is exactly what a
      // history is. it still gets a toast.
      if (!notification.transient) {
        root.history = [{
          key: key,
          app: notification.appName,
          text: text,
          image: notification.image ?? "",
          icon: notification.appIcon ?? "",
          urgency: notification.urgency,
          at: at
        }].concat(root.history).slice(0, root.maxHistory)
      }

      if (root.dnd) {
        notification.tracked = false
        return
      }

      // 0 means the client wants it up until it is answered, and so does critical
      // urgency by convention. anything else takes the client's timeout, or the
      // design's 5.2 seconds when it did not ask for one.
      const wanted = notification.expireTimeout
      const forever = wanted === 0 || notification.urgency === NotificationUrgency.Critical
      const timeout = wanted > 0 ? wanted : Theme.toastTimeout

      root.popups = [{
        key: key,
        notification: notification,
        at: at,
        expires: forever ? 0 : at + timeout
      }].concat(root.popups).slice(0, Theme.toastMax)

      // a client can withdraw a notification it already sent, and then the object
      // under our toast is gone. only the key is safe to use in here.
      notification.closed.connect(() => {
        root.popups = root.popups.filter(p => p.key !== key)
        root.schedule()
      })

      root.schedule()
    }
  }
}
