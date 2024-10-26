const audio = await Service.import("audio");

export default function Speaker() {
  const icons = {
    101: "overamplified",
    67: "high",
    34: "medium",
    1: "low",
    0: "muted",
  };

  function getIcon() {
    const icon = audio.speaker.is_muted
      ? 0
      : [101, 67, 34, 1, 0].find(
          (threshold) => threshold <= audio.speaker.volume * 100
        );

    return `audio-volume-${icons[icon]}-symbolic`;
  }

  const icon = Widget.Icon({
    size: 16,
    icon: Utils.watch(getIcon(), audio.speaker, getIcon),
  });

  function trimAudioSourceName(name) {
    if (name.includes("Analog Stereo")) {
      return name.replace(" Analog Stereo", "");
    }

    if (name.includes("Digital Stereo (IEC958)")) {
      return name.replace(" Digital Stereo (IEC958)", "");
    }

    return name;
  }

  const speakerMenu = Widget.Menu({
    class_name: "audio-devices-menu",
    setup: (self) =>
      self.hook(audio, (self) => {
        self.visible = audio.speakers.length > 0;
        self.children = audio.speakers.map((speaker) => {
          return Widget.MenuItem({
            class_name: `audio-device ${
              audio.speaker.id === speaker.id ? "active" : "inactive"
            }`,
            child: Widget.Label({
              hpack: "start",
              label: `${
                audio.speaker.id === speaker.id ? "󰄴" : "󰄰"
              } ${trimAudioSourceName(speaker.description)}`,
            }),
            onActivate: () => {
              audio.speaker = speaker;
            },
          });
        });
      }),
  });

  const label = Widget.Label({
    setup: (self) =>
      self.hook(audio.speaker, () => {
        self.label = `${parseInt(audio.speaker.volume * 100) || 0}%`;
      }),
  });

  const increaseVolume = (audio) => {
    if (audio.speaker.volume >= 1) {
      audio.speaker.volume = 1;
      return;
    }
    audio.speaker.volume += 0.05;
  };

  return Widget.Button({
    // setup: (self) => {
    //   self.on_middle_click = () => {
    //     menu(self);
    //   };
    // },
    classNames: ["volume-button"],
    on_scroll_up: () => {
      increaseVolume(audio);
    },
    on_scroll_down: () => (audio.speaker.volume -= 0.05),
    on_primary_click: () => {
      audio.speaker.is_muted = !audio.speaker.is_muted;
    },
    on_secondary_click: (_, event) => {
      speakerMenu.popup_at_pointer(event);
    },
    child: Widget.Box({ spacing: 8, children: [icon, label] }),
  });
}
