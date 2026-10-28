// osascript -l JavaScript app-icon.js APP OUT: writes the icon macOS shows for
// the app bundle at APP to the PNG file OUT. NSWorkspace knows every app's
// icon, including the ones that live only in an asset catalog.
ObjC.import("AppKit");

function run(argv) {
  const [app, out] = argv;
  const image = $.NSWorkspace.sharedWorkspace.iconForFile(app);
  const bitmap = $.NSBitmapImageRep.imageRepWithData(image.TIFFRepresentation);
  const png = bitmap.representationUsingTypeProperties($.NSBitmapImageFileTypePNG, $());
  if (!png.writeToFileAtomically(out, true)) {
    throw new Error(`cannot write ${out}`);
  }
}
