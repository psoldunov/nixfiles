// Prints `name:dir` for every monorepo workspace package that
// packages/coding-agent needs at runtime, following @earendil-works
// dependencies transitively. Run from the monorepo root.
//
// nixpkgs hardcodes this list in postInstall, so every release that adds or
// drops a workspace package breaks the pinned build. Deriving it from the
// package.json files keeps the overlay working across releases.
const fs = require("node:fs");
const path = require("node:path");

const readManifest = (dir) =>
  JSON.parse(fs.readFileSync(path.join(dir, "package.json"), "utf8"));

const workspaces = new Map(
  fs
    .readdirSync("packages", { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .map((entry) => path.join("packages", entry.name))
    .filter((dir) => fs.existsSync(path.join(dir, "package.json")))
    .map((dir) => [readManifest(dir).name, dir]),
);

const runtimeDeps = (dir) => {
  const manifest = readManifest(dir);
  return Object.keys({
    ...manifest.dependencies,
    ...manifest.optionalDependencies,
    ...manifest.peerDependencies,
  }).filter((name) => workspaces.has(name));
};

const seen = new Set();
const queue = runtimeDeps("packages/coding-agent");
while (queue.length > 0) {
  const name = queue.shift();
  if (seen.has(name)) continue;
  seen.add(name);
  queue.push(...runtimeDeps(workspaces.get(name)));
}

if (seen.size === 0) {
  console.error("runtime-workspaces: no workspace dependencies found");
  process.exit(1);
}

for (const name of [...seen].sort()) {
  console.log(`${name}:${workspaces.get(name)}`);
}
