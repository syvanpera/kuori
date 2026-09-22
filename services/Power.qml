pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// the battery and the profile the machine is running on. the only importer of
// Quickshell.Services.UPower, on the same terms as Bluez and Audio.
Singleton {
  id: root

  // the aggregate upower synthesises, which is the right thing to read a level
  // and a time off: it already knows how to add up more than one cell.
  readonly property var battery: UPower.displayDevice

  // and the real one behind it. the display device is synthetic and carries no
  // native path, so anything that has to reach sysfs has to come through here.
  readonly property var cell: UPower.devices.values.find(d => d.isLaptopBattery) ?? null

  readonly property bool present: root.battery?.isPresent ?? false
  readonly property real level: root.battery?.percentage ?? 0
  readonly property int percent: Math.round(root.level * 100)
  readonly property int state: root.battery?.state ?? UPowerDeviceState.Unknown
  readonly property bool charging: root.state === UPowerDeviceState.Charging

  // watt hours the battery holds when full, which is not what it was sold with:
  // this one is down to 57 of its 82.
  readonly property real capacity: root.battery?.energyCapacity ?? 0

  // watts in or out, always positive. which way it is going is the state's job.
  readonly property real rate: Math.abs(root.battery?.changeRate ?? 0)

  // what is left of the cell as a fraction of what it shipped with. upower works
  // this out and calls it capacity, but Quickshell reports healthSupported false
  // here and exposes no design figure to do it from, so the two numbers come
  // straight out of sysfs -- which is where upower reads them itself.
  //
  // a battery reports either energy (uWh) or charge (uAh), never both, so one
  // pair loads and the other never does. only the ratio matters, and the units
  // cancel as long as the pair is not mixed.
  property real energyFull: 0
  property real energyDesign: 0
  property real chargeFull: 0
  property real chargeDesign: 0

  readonly property real health: {
    if (root.energyDesign > 0 && root.energyFull > 0) return root.energyFull / root.energyDesign * 100
    if (root.chargeDesign > 0 && root.chargeFull > 0) return root.chargeFull / root.chargeDesign * 100
    return 0
  }

  readonly property bool healthKnown: root.health > 0

  // "BAT0" on this machine, and not always that elsewhere.
  readonly property string sysPath: {
    const native = root.cell?.nativePath ?? ""
    return native ? `/sys/class/power_supply/${native}` : ""
  }

  readonly property int seconds: {
    if (root.charging) return root.battery?.timeToFull ?? 0
    if (root.state === UPowerDeviceState.Discharging) return root.battery?.timeToEmpty ?? 0
    return 0
  }

  readonly property string stateText: {
    switch (root.state) {
      case UPowerDeviceState.Charging: return "Charging"
      case UPowerDeviceState.Discharging: return "Discharging"
      case UPowerDeviceState.FullyCharged: return "Full"
      case UPowerDeviceState.Empty: return "Empty"
      // plugged in and deliberately not charging, which is what a machine with a
      // charge limit does all day.
      case UPowerDeviceState.PendingCharge:
      case UPowerDeviceState.PendingDischarge: return "Holding"
      default: return "--"
    }
  }

  // "3h 10m", or "45m" under the hour. upower reports nothing at all while the
  // rate is settling, and a blank is better than a confident zero.
  readonly property string remaining: {
    if (root.seconds <= 0) return ""

    const hours = Math.floor(root.seconds / 3600)
    const minutes = Math.round((root.seconds % 3600) / 60)

    return hours > 0 ? `${hours}h ${minutes}m` : `${minutes}m`
  }

  readonly property string summary: {
    if (!root.present) return "No battery"
    return root.remaining ? `${root.percent}% · ${root.remaining}` : `${root.percent}%`
  }

  readonly property int profile: PowerProfiles.profile

  // two questions with one answer, which is the whole reason this is one property
  // and not two: whether this machine offers a performance profile, and whether
  // any daemon is listening at all.
  //
  // PowerProfiles has no flag for the second -- profile reads Balanced whether or
  // not anything answered -- and this shell ran for a while on a machine with no
  // power-profiles-daemon, offering three buttons that quietly did nothing.
  // hasPerformanceProfile comes from the daemon's own list, so it is false when
  // nothing answered, which makes it the closest proxy available. a laptop running
  // the daemon with no performance profile would lose the section wrongly; that is
  // rarer than the case this is here to catch.
  readonly property bool hasPerformance: PowerProfiles.hasPerformanceProfile

  function setProfile(which: int): void {
    PowerProfiles.profile = which
  }

  // a threshold table beats an if-ladder: each floor stays on the same line as the
  // glyph it picks. shared with the tab's own strip so the two never disagree.
  //
  // battery_charging_90_2 does not exist in the installed font and rendered as
  // literal text in the old bar; battery_charging_90 is the real name.
  readonly property var ladder: root.charging
    ? [
      { floor: 95, icon: "battery_charging_full_2" },
      { floor: 80, icon: "battery_charging_90" },
      { floor: 60, icon: "battery_charging_80_2" },
      { floor: 50, icon: "battery_charging_60_2" },
      { floor: 40, icon: "battery_charging_50_2" },
      { floor: 20, icon: "battery_charging_30_2" },
      { floor: 0, icon: "battery_charging_20_2" }
    ]
    : [
      { floor: 95, icon: "battery_android_frame_full" },
      { floor: 80, icon: "battery_android_frame_6" },
      { floor: 60, icon: "battery_android_frame_5" },
      { floor: 50, icon: "battery_android_frame_4" },
      { floor: 40, icon: "battery_android_frame_3" },
      { floor: 10, icon: "battery_android_frame_2" },
      { floor: 0, icon: "battery_android_frame_alert" }
    ]

  readonly property string glyph: root.ladder.find(step => root.percent >= step.floor).icon

  // FileView.text() is a function rather than a notifying property, so each of
  // these pushes from onLoaded. the file that does not exist simply never loads.
  FileView {
    id: energyFull

    path: root.sysPath ? `${root.sysPath}/energy_full` : ""
    printErrors: false

    onLoaded: root.energyFull = parseFloat(energyFull.text()) || 0
  }

  FileView {
    id: energyDesign

    path: root.sysPath ? `${root.sysPath}/energy_full_design` : ""
    printErrors: false

    onLoaded: root.energyDesign = parseFloat(energyDesign.text()) || 0
  }

  FileView {
    id: chargeFull

    path: root.sysPath ? `${root.sysPath}/charge_full` : ""
    printErrors: false

    onLoaded: root.chargeFull = parseFloat(chargeFull.text()) || 0
  }

  FileView {
    id: chargeDesign

    path: root.sysPath ? `${root.sysPath}/charge_full_design` : ""
    printErrors: false

    onLoaded: root.chargeDesign = parseFloat(chargeDesign.text()) || 0
  }
}
