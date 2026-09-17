import qs.components
import qs.theme

Pill {
  icon: {
    const bars = parseInt(strength.text);
    if (isNaN(bars))
      return "signal_wifi_off";
    if (bars >= 75)
      return "signal_wifi_4_bar";
    if (bars >= 55)
      return "signal_wifi_3_bar";
    if (bars >= 35)
      return "signal_wifi_2_bar";
    if (bars >= 15)
      return "signal_wifi_1_bar";
    return "signal_wifi_0_bar";
  }
  iconColor: Theme.red
  text: name.text

  Poll {
    id: name
    cmd: "ncmli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2"
    every: 10000
  }

  Poll {
    id: strength
    cmd: "ncmli -t -f active,signal dev wifi | grep '^yes' | cut -d: -f2"
    every: 10000
  }
}
