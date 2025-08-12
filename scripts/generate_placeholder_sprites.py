#!/usr/bin/env python3
"""
Generate 64x64 placeholder sprites for Repto Rumble character animations.
Each animation gets a different colored rectangle.
"""

from PIL import Image, ImageDraw
import os

# Animation colors (RGB)
COLORS = {
    'idle': (100, 150, 255),      # Light blue
    'run': (100, 255, 100),       # Green
    'jump_start': (255, 200, 100), # Orange
    'air': (255, 150, 150),       # Pink
    'land': (150, 100, 255),      # Purple
    'attack_light_1': (255, 100, 100),  # Red
    'attack_light_2': (200, 100, 100),  # Dark red
    'attack_heavy': (150, 0, 0),         # Very dark red
    'hurt': (255, 255, 100),      # Yellow
    'wall_slide': (150, 150, 150), # Gray
    'wall_jump': (200, 200, 200),  # Light gray
}

def create_placeholder_sprite(color, filename):
    """Create a 64x64 colored rectangle sprite."""
    img = Image.new('RGBA', (64, 64), (0, 0, 0, 0))  # Transparent background
    draw = ImageDraw.Draw(img)
    
    # Draw a colored rectangle (character body)
    draw.rectangle([16, 8, 48, 56], fill=color + (255,))  # 32x48 character
    
    # Add simple eyes
    draw.rectangle([22, 16, 26, 20], fill=(0, 0, 0, 255))  # Left eye
    draw.rectangle([38, 16, 42, 20], fill=(0, 0, 0, 255))  # Right eye
    
    img.save(filename)
    print(f"Created {filename}")

def main():
    output_dir = "/home/will/code/repto-rumble/sprites/characters/placeholder"
    os.makedirs(output_dir, exist_ok=True)
    
    for anim_name, color in COLORS.items():
        # Create multiple frames for variety (just slightly different positions)
        for frame in range(3):
            filename = f"{output_dir}/{anim_name}_{frame:02d}.png"
            create_placeholder_sprite(color, filename)

if __name__ == "__main__":
    main()
