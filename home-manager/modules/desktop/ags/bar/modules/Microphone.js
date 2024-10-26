const audio = await Service.import("audio");

export default function Microphone() {
  const icons = {
    101: "overamplified",
    67: "high",
    34: "medium",
    1: "low",
    0: "muted",
  };

  function getIcon() {
    const icon = audio.microphone.is_muted
      ? 0
      : [101, 67, 34, 1, 0].find(
          (threshold) => threshold <= audio.microphone.volume * 100
        );

    return `audio-input-microphone-${icons[icon]}-symbolic`;
  }

  const icon = Widget.Icon({
    size: 16,
    icon: Utils.watch(getIcon(), audio.microphone, getIcon),
  });

  const label = Widget.Label({
    setup: (self) =>
      self.hook(audio.microphone, () => {
        self.label = `${parseInt(audio.microphone.volume * 100) || 0}%`;
      }),
  });

  const increaseVolume = (audio) => {
    if (audio.microphone.volume >= 1) {
      audio.microphone.volume = 1;
      return;
    }
    audio.microphone.volume += 0.05;
  };

  function trimAudioSourceName(name) {
    return name.replace(/ Analog Stereo$/, "");
  }

  const microphoneMenu = Widget.Menu({
    class_name: "audio-devices-menu",
    setup: (self) =>
      self.hook(audio, (self) => {
        self.children = audio.microphones.map((microphone) => {
          return Widget.MenuItem({
            class_name: `audio-device ${
              audio.microphone.id === microphone.id ? "active" : "inactive"
            }`,
            child: Widget.Label({
              hpack: "start",
              label: `${
                audio.microphone.id === microphone.id ? "󰄴" : "󰄰"
              } ${trimAudioSourceName(microphone.description)}`,
            }),
            onActivate: () => {
              audio.microphone = microphone;
            },
          });
        });
      }),
  });

  return Widget.Button({
    classNames: ["microphone-button"],
    on_scroll_up: () => {
      increaseVolume(audio);
    },
    on_scroll_down: () => (audio.microphone.volume -= 0.05),
    on_primary_click: () => {
      audio.microphone.is_muted = !audio.microphone.is_muted;
    },
    on_secondary_click: (_, event) => {
      microphoneMenu.popup_at_pointer(event);
    },
    child: Widget.Box({ spacing: 8, children: [icon, label] }),
  });
}
