import { execAsync } from "ags/process"
import { weather, CITY, type WeatherData } from "../../services/weather"

function convert12HourTo24(time: string): [number, number] {
  const [t, ampm] = time.split(" ")
  const [h, m] = t.split(":").map(Number)
  let hour = h
  if (ampm === "PM" && hour !== 12) hour += 12
  if (ampm === "AM" && hour === 12) hour = 0
  return [hour, m]
}

function weatherIcon(data: NonNullable<WeatherData>) {
  const cur = data.current_condition[0]
  const [, time, ampm] = cur.localObsDateTime.split(" ")
  const [hourStr] = time.split(":")
  const h = parseInt(hourStr, 10)
  const isPM = ampm === "PM"
  const hour = isPM && h !== 12 ? h + 12 : h % 12

  const [sunriseH] = convert12HourTo24(data.weather[0].astronomy[0].sunrise)
  const [sunsetH] = convert12HourTo24(data.weather[0].astronomy[0].sunset)
  const isNight = hour >= sunsetH || hour < sunriseH

  const desc = cur.weatherDesc[0].value.toLowerCase()
  if (desc.includes("fog") || desc.includes("mist")) return "weather-fog-symbolic"
  if (desc.includes("storm")) return "weather-storm-symbolic"
  if (desc.includes("snow")) return "weather-snow-symbolic"
  if (desc.includes("rain") || desc.includes("drizzle")) return "weather-rain-symbolic"
  if (desc.includes("cloud")) return "weather-cloud-symbolic"
  if (isNight) return "weather-moon-symbolic"
  return "weather-sun-symbolic"
}

export default function Weather() {
  return (
    <button
      class="weather-button"
      visible={weather((d) => Boolean(d))}
      onClicked={() =>
        execAsync(["bash", "-c", `kitty -e --hold curl "wttr.in/${CITY}"`]).catch(
          () => {},
        )
      }
      tooltipMarkup={weather((d) =>
        d ? d.current_condition[0].weatherDesc[0].value : "",
      )}
    >
      <box spacing={8}>
        <icon icon={weather((d) => (d ? weatherIcon(d) : "weather-sun-symbolic"))} />
        <label
          label={weather((d) =>
            d
              ? `${d.nearest_area[0].areaName[0].value}, ${d.current_condition[0].FeelsLikeC}°C`
              : "",
          )}
        />
      </box>
    </button>
  )
}
