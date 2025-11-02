# Icons Directory

This directory should contain PNG icons for the PWA in the following sizes:
- 72x72
- 96x96
- 128x128
- 144x144
- 152x152
- 192x192
- 384x384
- 512x512

You can generate these from the `icon.svg` file using an online tool or ImageMagick:

```bash
# Using ImageMagick (if installed)
for size in 72 96 128 144 152 192 384 512; do
  convert icon.svg -resize ${size}x${size} icon-${size}.png
done
```

Or use an online SVG to PNG converter to create these icons.

For now, browsers will use the SVG icon as a fallback.
