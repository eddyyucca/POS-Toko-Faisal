from PIL import Image
img = Image.open("wizard_large.bmp")
img.save("wizard_large_preview.png")
img2 = Image.open("wizard_small.bmp")
img2.save("wizard_small_preview.png")
print("preview saved")
