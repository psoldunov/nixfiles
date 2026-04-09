export default function IdleInhibitor() {
  const hypridleStatus = Variable(true);
  const inhibitorStatus = Variable(false);

  Utils.subprocess(
    ["bash", "-c", "systemctl --user is-active hypridle.service"],
    (output) => {
      inhibitorStatus.setValue(output === "active" ? false : true);
      hypridleStatus.setValue(output === "active" ? true : false);
    },
    (error) => logError(error)
  );

  inhibitorStatus.connect("changed", ({ value }) => {
    hypridleStatus.setValue(!value);
  });

  const updateInhibitor = () => {
    log(
      `Hypridle is ${
        hypridleStatus.value ? "active" : "inactive"
      }, toggling inhibitor ${hypridleStatus.value ? "on" : "off"}`
    );

    return Utils.subprocess(
      [
        "bash",
        "-c",
        `systemctl --user ${
          hypridleStatus.value ? "stop" : "start"
        } hypridle.service && systemctl --user is-active hypridle.service`,
      ],
      (output) => {
        inhibitorStatus.setValue(output === "active" ? false : true);
      },
      (error) => logError(error)
    );
  };

  return Widget.Button({
    class_name: inhibitorStatus
      .bind()
      .as((value) => "idle-inhibitor" + (value ? " active" : "")),
    child: Widget.Icon({
      size: 16,
      icon: inhibitorStatus
        .bind()
        .as((value) => (value ? "eye-symbolic" : "eye-slash-symbolic")),
    }),
    on_clicked: () => {
      updateInhibitor();
    },
  });
}
