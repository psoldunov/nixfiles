const city = "Tallinn";

const weather = Variable([], {
  poll: [
    1200000,
    () =>
      Utils.fetch(`http://wttr.in/${city}?format=j1`)
        .then((res) => res.text())
        .then((data) => JSON.parse(data))
        .catch(console.error),
  ],
});

export default function Weather() {
  const getConditionIcon = (data) => {
    if (!data) return;

    const { localObsDateTime, weatherDesc } = data.current_condition[0];
    const [date, time, ampm] = localObsDateTime.split(" ");
    const [hourStr, minuteStr] = time.split(":");
    const currentHour = parseInt(hourStr);
    const isPM = ampm === "PM";
    const hour =
      isPM && currentHour !== 12 ? currentHour + 12 : currentHour % 12;

    const { sunrise, sunset } = data.weather[0].astronomy[0];
    const [sunriseHour, sunriseMinute] = convert12HourTo24Hour(sunrise);
    const [sunsetHour, sunsetMinute] = convert12HourTo24Hour(sunset);

    const isNight = hour >= sunsetHour || hour < sunriseHour;

    const descriptionString = weatherDesc[0].value.toLowerCase();

    if (
      descriptionString.includes("fog") ||
      descriptionString.includes("mist")
    ) {
      return "weather-fog-symbolic";
    }
    if (descriptionString.includes("storm")) return "weather-storm-symbolic";
    if (descriptionString.includes("snow")) return "weather-snow-symbolic";
    if (
      descriptionString.includes("rain") ||
      descriptionString.includes("drizzle")
    )
      return "weather-rain-symbolic";
    if (descriptionString.includes("cloud")) return "weather-cloud-symbolic";
    if (isNight) return "weather-moon-symbolic";
    return "weather-sun-symbolic";
  };

  const convert12HourTo24Hour = (time) => {
    const [timePart, ampm] = time.split(" ");
    let [hour, minute] = timePart.split(":").map(Number);
    if (ampm === "PM" && hour !== 12) hour += 12;
    if (ampm === "AM" && hour === 12) hour = 0;
    return [hour, minute];
  };

  return Widget.Button({
    visible: weather.bind().as((data) => !!data),
    className: "weather-button",
    onClicked: () =>
      Utils.execAsync([
        "bash",
        "-c",
        `ghostty -e --hold curl "wttr.in/${city}"`,
      ]),
    child: Widget.Box({
      spacing: 8,
      children: [
        Widget.Icon({
          size: 16,
          icon: weather.bind().as(getConditionIcon),
        }),
        Widget.Label({
          label: weather.bind().as((data) => {
            return `${data.nearest_area[0].areaName[0].value}, ${data.current_condition[0].FeelsLikeC}°C`;
          }),
        }),
      ],
    }),
    tooltip_markup: weather.bind().as((data) => {
      return `${data.current_condition[0].weatherDesc[0].value}`;
    }),
  });
}
