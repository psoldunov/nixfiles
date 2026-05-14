import { createPoll } from "ags/time"
import fetch from "ags/fetch"

export const CITY = "Pareklisia"

export type WeatherData = {
  current_condition: {
    FeelsLikeC: string
    weatherDesc: { value: string }[]
    localObsDateTime: string
  }[]
  weather: {
    astronomy: { sunrise: string; sunset: string }[]
  }[]
  nearest_area: {
    areaName: { value: string }[]
  }[]
} | null

async function fetchWeather(): Promise<WeatherData> {
  try {
    const res = await fetch(`http://wttr.in/${CITY}?format=j1`)
    const text = await res.text()
    return JSON.parse(text) as WeatherData
  } catch (err) {
    console.error("weather fetch:", err)
    return null
  }
}

export const weather = createPoll<WeatherData>(null, 1_200_000, fetchWeather)
