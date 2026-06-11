#!/usr/bin/env python3
"""Generate Ala Rengin (Kurdish Flag) as PNG image"""

from PIL import Image, ImageDraw
import os

# Create image 300x180 (standard flag ratio)
width, height = 300, 180
img = Image.new('RGB', (width, height))
draw = ImageDraw.Draw(img)

# Draw the three stripes
stripe_height = height // 3

# Red stripe (top)
draw.rectangle([(0, 0), (width, stripe_height)], fill=(206, 17, 38))

# White stripe (middle)
draw.rectangle([(0, stripe_height), (width, 2 * stripe_height)], fill=(255, 255, 255))

# Green stripe (bottom)
draw.rectangle([(0, 2 * stripe_height), (width, height)], fill=(0, 122, 94))

# Draw the sun (Rashi) in the center
center_x, center_y = width // 2, height // 2
sun_radius = 28
sun_color = (255, 215, 0)  # Gold

# Draw sun circle
draw.ellipse(
    [(center_x - sun_radius, center_y - sun_radius),
     (center_x + sun_radius, center_y + sun_radius)],
    fill=sun_color
)

# Draw 12 rays around the sun
import math
ray_length = 20
ray_start = sun_radius + 5
ray_width = 3

for i in range(12):
    angle = (i * 30) * math.pi / 180  # 30 degrees between rays
    
    # Start and end points of the ray
    x1 = center_x + (sun_radius) * math.cos(angle)
    y1 = center_y + (sun_radius) * math.sin(angle)
    x2 = center_x + (sun_radius + ray_length) * math.cos(angle)
    y2 = center_y + (sun_radius + ray_length) * math.sin(angle)
    
    draw.line([(x1, y1), (x2, y2)], fill=sun_color, width=ray_width)

# Save the image
output_path = os.path.join(os.path.dirname(__file__), 'assets', 'images', 'ala_rengin.png')
os.makedirs(os.path.dirname(output_path), exist_ok=True)

img.save(output_path, 'PNG')
print(f"✅ Ala Rengin flag saved to: {output_path}")
