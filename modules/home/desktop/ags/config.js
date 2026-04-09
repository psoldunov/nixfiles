import Bar from "./bar/bar.js";

const scss = `${App.configDir}/scss/style.scss`;
const css = `${App.configDir}/style.css`;
Utils.exec(`sassc ${scss} ${css}`);

App.config({
  style: "./style.css",

  windows: [Bar()],
});

App.addIcons(`${App.configDir}/assets`);

export {};
