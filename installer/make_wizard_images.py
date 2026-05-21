from PIL import Image, ImageDraw, ImageFont
import os

NAVY   = (28, 43, 58)
ORANGE = (247, 148, 29)
WHITE  = (255, 255, 255)
CREAM  = (255, 248, 240)
GRAY   = (139, 163, 180)
NAVY2  = (38, 56, 76)

def load_font(size, bold=False):
    for name in (['arialbd','calibrib','segoeuib'] if bold else ['arial','calibri','segoeui']):
        p = f"C:/Windows/Fonts/{name}.ttf"
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()

# ── Wizard Large Image 164x314 (panel kiri, WizardStyle=classic) ──
W, H = 164, 314
img = Image.new("RGB", (W, H), NAVY)
draw = ImageDraw.Draw(img)

# Gradient efek — strip gelap di bawah
for y in range(H):
    ratio = y / H
    r = int(NAVY[0] + (NAVY2[0]-NAVY[0]) * ratio)
    g = int(NAVY[1] + (NAVY2[1]-NAVY[1]) * ratio)
    b = int(NAVY[2] + (NAVY2[2]-NAVY[2]) * ratio)
    draw.line([(0,y),(W,y)], fill=(r,g,b))

# Aksen garis vertikal kanan
draw.rectangle([W-3, 0, W, H], fill=ORANGE)

# Strip orange atas
draw.rectangle([0, 0, W, 5], fill=ORANGE)

# Logo
logo = Image.open("../assets/images/logo_circle.png").convert("RGBA")
logo = logo.resize((88, 88), Image.LANCZOS)
x = (W - 88) // 2
img.paste(logo, (x, 22), logo)

# Teks nama
draw.text((W//2, 122), "TOKO",   font=load_font(13,True), fill=CREAM,  anchor="mm")
draw.text((W//2, 140), "FAISAL", font=load_font(20,True), fill=ORANGE, anchor="mm")

# Garis
draw.line([(16, 156), (W-18, 156)], fill=(60,85,108), width=1)

draw.text((W//2, 167), "Sembako & Kebutuhan Harian", font=load_font(7), fill=GRAY, anchor="mm")
draw.text((W//2, 180), "Aplikasi Kasir (POS)",       font=load_font(8), fill=GRAY, anchor="mm")
draw.text((W//2, 193), "Versi 1.0.0",               font=load_font(9,True), fill=WHITE, anchor="mm")

# Kotak info PT
draw.rounded_rectangle([12, 228, W-16, 298], radius=8, fill=(20,34,46), outline=(60,85,108), width=1)
draw.text((W//2, 241), "Dikembangkan oleh",    font=load_font(7),    fill=GRAY,   anchor="mm")
draw.text((W//2, 254), "PT FLUXA TRITAMA",     font=load_font(8,True), fill=ORANGE, anchor="mm")
draw.text((W//2, 266), "INDONESIA",            font=load_font(8,True), fill=ORANGE, anchor="mm")
draw.line([(24, 274), (W-28, 274)], fill=(60,85,108), width=1)
draw.text((W//2, 284), "2026 - All Rights Reserved", font=load_font(6), fill=GRAY, anchor="mm")

# Simpan sebagai 24-bit BMP
img.convert("RGB").save("wizard_large.bmp", format="BMP")
print("wizard_large.bmp (164x314) saved")

# ── Wizard Small Image 55x55 (pojok kanan atas) ──
S = 55
simg = Image.new("RGB", (S, S), NAVY)
sdraw = ImageDraw.Draw(simg)
sdraw.rectangle([0,0,S-1,S-1], outline=ORANGE, width=2)
slogo = logo.resize((40,40), Image.LANCZOS)
simg.paste(slogo, (7,7), slogo)
simg.convert("RGB").save("wizard_small.bmp", format="BMP")
print("wizard_small.bmp (55x55) saved")

# Preview PNG
img.save("wizard_large_preview.png")
print("Preview saved")
