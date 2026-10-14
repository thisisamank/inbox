#!/usr/bin/env bash
set -euo pipefail

app="$(cd "$(dirname "$0")/.." && pwd)"
brand="$app/assets/brand"
res="$app/android/app/src/main/res"
ios="$app/ios/Runner/Assets.xcassets/AppIcon.appiconset"

for tool in rsvg-convert magick; do
  command -v "$tool" >/dev/null || { echo "missing $tool (brew install librsvg imagemagick)" >&2; exit 1; }
done

render() { rsvg-convert -w "$2" -h "$2" "$1" -o "$3"; }

for pair in mdpi:1 hdpi:1.5 xhdpi:2 xxhdpi:3 xxxhdpi:4; do
  density="${pair%%:*}"
  scale="${pair##*:}"
  dir="$res/mipmap-$density"
  mkdir -p "$dir"
  legacy=$(awk "BEGIN { printf \"%d\", 48 * $scale }")
  layer=$(awk "BEGIN { printf \"%d\", 108 * $scale }")
  render "$brand/icon.svg" "$legacy" "$dir/ic_launcher.png"
  render "$brand/icon_foreground.svg" "$layer" "$dir/ic_launcher_foreground.png"
  render "$brand/icon_monochrome.svg" "$layer" "$dir/ic_launcher_monochrome.png"
done

mkdir -p "$res/mipmap-anydpi-v26" "$res/values"
cat > "$res/mipmap-anydpi-v26/ic_launcher.xml" <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome"/>
</adaptive-icon>
XML
cat > "$res/values/ic_launcher_background.xml" <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#C2410C</color>
</resources>
XML

python3 - "$ios/Contents.json" <<'PY' | while read -r file px; do
import json, sys
for image in json.load(open(sys.argv[1]))["images"]:
    size = float(image["size"].split("x")[0])
    scale = float(image["scale"].rstrip("x"))
    print(image["filename"], round(size * scale))
PY
  render "$brand/icon.svg" "$px" "$ios/$file.tmp.png"
  magick "$ios/$file.tmp.png" -background "#C2410C" -alpha remove -alpha off "$ios/$file"
  rm "$ios/$file.tmp.png"
done

echo "icons written"
