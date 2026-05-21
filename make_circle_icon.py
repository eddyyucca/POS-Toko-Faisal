from PIL import Image, ImageDraw

src = Image.open("assets/images/logo_toko_faisal.png").convert("RGBA")

# Crop ke kotak sempurna dari tengah
w, h = src.size
size = min(w, h)
left = (w - size) // 2
top = (h - size) // 2
src = src.crop((left, top, left + size, top + size))

# Buat mask lingkaran
mask = Image.new("L", (size, size), 0)
draw = ImageDraw.Draw(mask)
draw.ellipse((0, 0, size, size), fill=255)

# Terapkan mask
result = Image.new("RGBA", (size, size), (0, 0, 0, 0))
result.paste(src, mask=mask)

# Simpan PNG bulat untuk flutter_launcher_icons
result.save("assets/images/logo_circle.png")
print(f"Saved logo_circle.png ({size}x{size})")
