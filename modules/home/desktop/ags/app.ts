import app from "ags/gtk3/app"
import style from "./style.scss"
import Bar from "./widget/Bar"

app.start({
  css: style,
  icons: `${SRC}/assets`,
  main() {
    app.get_monitors().map(Bar)
  },
})
