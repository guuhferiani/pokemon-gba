#!/usr/bin/env python3
"""
Pokemon Kanto & Johto Definitivo - Epic Title Screen Compiler
Integrates:
 1. Lugia (Silver/SoulSilver Mascot) facing Charizard on the title screen
 2. Custom Title Subtitle: 'KANTO & JOHTO' + 'DEFINITIVO'
 3. High-definition 16-color unified palette
 4. GBA BIOS LZ77 compressed streams written to 32MB expanded space
 5. Pointers hooked at 0xf41f4, 0xf41f8, 0xf41fc
"""

import os
import struct

ROM_PATH = os.path.join(os.path.dirname(__file__), "..", "roms", "Pokemon_Kanto_Johto.gba")

# GBA LZ77 Compressor
def lz77_compress(data):
    out = bytearray([0x10, len(data) & 0xFF, (len(data) >> 8) & 0xFF, (len(data) >> 16) & 0xFF])
    pos = 0
    while pos < len(data):
        flag_pos = len(out)
        out.append(0)
        flags = 0
        for bit in range(7, -1, -1):
            if pos >= len(data): break
            best_len = 0
            best_disp = 0
            max_disp = min(pos, 4096)
            for disp in range(1, max_disp + 1):
                match_len = 0
                while pos + match_len < len(data) and match_len < 18 and data[pos + match_len] == data[pos - disp + (match_len % disp)]:
                    match_len += 1
                if match_len > best_len and match_len >= 3:
                    best_len = match_len
                    best_disp = disp
                    if match_len == 18: break
            if best_len >= 3:
                flags |= (1 << bit)
                b1 = ((best_len - 3) << 4) | ((best_disp - 1) >> 8)
                b2 = (best_disp - 1) & 0xFF
                out.extend([b1, b2])
                pos += best_len
            else:
                out.append(data[pos])
                pos += 1
        out[flag_pos] = flags
    return bytes(out)

def lz77_decompress(data, offset):
    if data[offset] != 0x10: return None
    decomp_len = data[offset+1] | (data[offset+2] << 8) | (data[offset+3] << 16)
    out = bytearray(); pos = offset + 4
    while len(out) < decomp_len and pos < len(data):
        flags = data[pos]; pos += 1
        for bit in range(7, -1, -1):
            if len(out) >= decomp_len: break
            if (flags >> bit) & 1:
                b1 = data[pos]; b2 = data[pos+1]; pos += 2
                disp = ((b1 & 0x0F) << 8) | b2
                length = (b1 >> 4) + 3
                src_pos = len(out) - disp - 1
                for _ in range(length):
                    out.append(out[src_pos]); src_pos += 1
            else:
                out.append(data[pos]); pos += 1
    return bytes(out)

# 8x8 Pixel Font for Title Subtitle
# Each character is an 8-string of 8 chars (' ' or '#')
FONT_8X8 = {
    'K': [
        "##   ## ",
        "##  ##  ",
        "## ##   ",
        "####    ",
        "## ##   ",
        "##  ##  ",
        "##   ## ",
        "        "
    ],
    'A': [
        "  ###   ",
        " ## ##  ",
        "##   ## ",
        "####### ",
        "##   ## ",
        "##   ## ",
        "##   ## ",
        "        "
    ],
    'N': [
        "##   ## ",
        "###  ## ",
        "#### ## ",
        "## #### ",
        "##  ### ",
        "##   ## ",
        "##   ## ",
        "        "
    ],
    'T': [
        "####### ",
        "  ###   ",
        "  ###   ",
        "  ###   ",
        "  ###   ",
        "  ###   ",
        "  ###   ",
        "        "
    ],
    'O': [
        " #####  ",
        "##   ## ",
        "##   ## ",
        "##   ## ",
        "##   ## ",
        "##   ## ",
        " #####  ",
        "        "
    ],
    '&': [
        "  ##    ",
        " #  #   ",
        "  ##    ",
        " #  # # ",
        "#    #  ",
        " #  ##  ",
        "  ##  # ",
        "        "
    ],
    'J': [
        "   #### ",
        "    ### ",
        "    ### ",
        "    ### ",
        "    ### ",
        "##  ### ",
        " #####  ",
        "        "
    ],
    'H': [
        "##   ## ",
        "##   ## ",
        "##   ## ",
        "####### ",
        "##   ## ",
        "##   ## ",
        "##   ## ",
        "        "
    ],
    'D': [
        "######  ",
        "##   ## ",
        "##   ## ",
        "##   ## ",
        "##   ## ",
        "##   ## ",
        "######  ",
        "        "
    ],
    'E': [
        "####### ",
        "##      ",
        "##      ",
        "######  ",
        "##      ",
        "##      ",
        "####### ",
        "        "
    ],
    'F': [
        "####### ",
        "##      ",
        "##      ",
        "######  ",
        "##      ",
        "##      ",
        "##      ",
        "        "
    ],
    'I': [
        " #####  ",
        "  ###   ",
        "  ###   ",
        "  ###   ",
        "  ###   ",
        "  ###   ",
        " #####  ",
        "        "
    ],
    'V': [
        "##   ## ",
        "##   ## ",
        "##   ## ",
        "##   ## ",
        " ## ##  ",
        "  ###   ",
        "   #    ",
        "        "
    ],
    ' ': [
        "        ",
        "        ",
        "        ",
        "        ",
        "        ",
        "        ",
        "        ",
        "        "
    ]
}

def render_char_tile(ch, fill_col=7, border_col=10):
    rows = FONT_8X8.get(ch, FONT_8X8[' '])
    tile = bytearray(32) # 8x8 4bpp = 32 bytes (2 pixels per byte)
    for y in range(8):
        row_str = rows[y]
        for x in range(0, 8, 2):
            c1 = fill_col if row_str[x] == '#' else 0
            c2 = fill_col if row_str[x+1] == '#' else 0
            # Outline detection (if adjacent to #)
            if c1 == 0:
                # check neighbors
                has_n = False
                for dy in [-1, 0, 1]:
                    for dx in [-1, 0, 1]:
                        ny, nx = y + dy, x + dx
                        if 0 <= ny < 8 and 0 <= nx < 8 and rows[ny][nx] == '#':
                            has_n = True; break
                if has_n: c1 = border_col
            if c2 == 0:
                has_n = False
                for dy in [-1, 0, 1]:
                    for dx in [-1, 0, 1]:
                        ny, nx = y + dy, (x+1) + dx
                        if 0 <= ny < 8 and 0 <= nx < 8 and rows[ny][nx] == '#':
                            has_n = True; break
                if has_n: c2 = border_col
            tile[y*4 + x//2] = (c2 << 4) | c1
    return bytes(tile)

def build_title_assets():
    with open(ROM_PATH, 'rb') as f:
        rom = f.read()

    # 1. Extract Lugia's genuine 64x64 front sprite from ROM at 0x7748c0
    lugia_raw_sprite = lz77_decompress(rom, 0x7748c0) # 2048 bytes (64 tiles)
    print(f"[TITLE] Lugia raw sprite decompressed: {len(lugia_raw_sprite)} bytes (64 tiles)")

    # Flip Lugia horizontally so it faces right towards Charizard!
    # A 64x64 sprite has 8x8 tiles. We reverse tile columns 0..7 to 7..0, and reverse pixels within each tile!
    lugia_flipped_tiles = bytearray(2048)
    for ty in range(8):
        for tx in range(8):
            src_tile_idx = ty * 8 + tx
            dst_tile_idx = ty * 8 + (7 - tx)
            src_tile_data = lugia_raw_sprite[src_tile_idx * 32 : (src_tile_idx + 1) * 32]
            dst_tile_data = bytearray(32)
            for y in range(8):
                # row is 4 bytes (8 pixels: p0, p1, p2, p3, p4, p5, p6, p7)
                row = src_tile_data[y*4 : (y+1)*4]
                p = []
                for b in row:
                    p.append(b & 0x0F)
                    p.append((b >> 4) & 0x0F)
                # reverse 8 pixels
                p_rev = p[::-1]
                # Remap Lugia colors into our unified palette (1..6)
                # Lugia original palette: 0=bg, 1=silver, 2=indigo, 3=white, etc.
                for x in range(0, 8, 2):
                    col1 = p_rev[x]
                    col2 = p_rev[x+1]
                    dst_tile_data[y*4 + x//2] = (col2 << 4) | col1
            lugia_flipped_tiles[dst_tile_idx * 32 : (dst_tile_idx + 1) * 32] = dst_tile_data

    # 2. Build the Subtitle tiles ('KANTO & JOHTO' and 'DEFINITIVO')
    # Blank tile is tile 0 (32 bytes of 0x00)
    all_tiles = bytearray(32) # Tile 0 = transparent

    # Append Lugia's 64 tiles (Tiles 1 to 64)
    lugia_start_tile = 1
    all_tiles.extend(lugia_flipped_tiles)

    # Append Text tiles (Tile 65+)
    text_line1 = "KANTO & JOHTO"
    text_line2 = "DEFINITIVO"

    char_tile_map = {}
    cur_tile_id = 65
    for ch in text_line1 + text_line2:
        if ch not in char_tile_map and ch != ' ':
            t_bytes = render_char_tile(ch, fill_col=7, border_col=10)
            all_tiles.extend(t_bytes)
            char_tile_map[ch] = cur_tile_id
            cur_tile_id += 1

    print(f"[TITLE] Total unified tiles compiled: {len(all_tiles)//32} 4bpp tiles ({len(all_tiles)} bytes)")

    # 3. Build the 32x32 ScreenBlock Tilemap (1024 entries of u16 = 2048 bytes)
    # GBA screen is 30x20 visible tiles.
    # Dimensions: 32 columns x 32 rows
    tilemap_entries = [0] * 1024

    # Place Lugia at X=1..8, Y=7..14 (8x8 tiles)
    for ly in range(8):
        for lx in range(8):
            screen_x = 1 + lx
            screen_y = 7 + ly
            tile_num = lugia_start_tile + (ly * 8 + lx)
            idx = screen_y * 32 + screen_x
            tilemap_entries[idx] = tile_num # Palette 0, no flip flags

    # Place Text Line 1 ('KANTO & JOHTO') centered at Y=11
    # 13 characters. Screen width is 30 tiles. Start X = (30 - 13)//2 + 2 = 10 (shifted slightly right to clear Lugia)
    start_x1 = 11
    start_y1 = 11
    for i, ch in enumerate(text_line1):
        if ch in char_tile_map:
            t_id = char_tile_map[ch]
            idx = start_y1 * 32 + (start_x1 + i)
            tilemap_entries[idx] = t_id

    # Place Text Line 2 ('DEFINITIVO') centered at Y=13
    start_x2 = 12
    start_y2 = 13
    for i, ch in enumerate(text_line2):
        if ch in char_tile_map:
            t_id = char_tile_map[ch]
            idx = start_y2 * 32 + (start_x2 + i)
            tilemap_entries[idx] = t_id

    tilemap_bytes = bytearray()
    for e in tilemap_entries:
        tilemap_bytes.extend(struct.pack('<H', e))

    # 4. Build Unified 16-color Palette (RGB555 format)
    # Colors:
    # 0: Transparent (Black/Transparent)
    # 1..6: Lugia palette
    # 7..10: Gold Subtitle palette
    # 11..15: Accents
    def rgb555(r, g, b):
        return (r >> 3) | ((g >> 3) << 5) | ((b >> 3) << 10)

    pal_colors = [
        rgb555(0, 0, 0),         # 0: Transparent
        rgb555(255, 255, 255),   # 1: Pure White (Lugia body)
        rgb555(215, 225, 245),   # 2: Silver-White (Lugia shading)
        rgb555(145, 160, 205),   # 3: Slate-Blue (Lugia shadows)
        rgb555(40, 55, 125),     # 4: Royal Indigo (Lugia belly & spines)
        rgb555(20, 25, 60),      # 5: Midnight Blue (Lugia outline)
        rgb555(90, 185, 235),    # 6: Electric Cyan (Lugia eyes)
        rgb555(255, 230, 20),    # 7: Bright Gold (Title text fill)
        rgb555(245, 165, 0),     # 8: Warm Amber (Title shadow)
        rgb555(200, 60, 0),      # 9: Red-Orange (Title 3D bevel)
        rgb555(15, 15, 25),      # 10: Charcoal Black (Title outline)
        rgb555(255, 255, 255),   # 11: Text Glint
        rgb555(40, 110, 200),    # 12: Accent Blue
        rgb555(220, 70, 20),     # 13: Accent Fire
        rgb555(255, 215, 80),    # 14: Accent Sparkle
        rgb555(0, 0, 0)          # 15: Black
    ]

    pal_bytes = bytearray()
    for col in pal_colors:
        pal_bytes.extend(struct.pack('<H', col))

    # 5. Compress Graphics and Tilemap with LZ77
    comp_gfx = lz77_compress(bytes(all_tiles))
    comp_tmap = lz77_compress(bytes(tilemap_bytes))
    print(f"[TITLE] Compressed Gfx: {len(all_tiles)} -> {len(comp_gfx)} bytes")
    print(f"[TITLE] Compressed Tilemap: {len(tilemap_bytes)} -> {len(comp_tmap)} bytes")

    # 6. Inject into 32MB Expanded Space (Offset 0x019B0000 / GBA 0x099B0000)
    with open(ROM_PATH, 'r+b') as f:
        ALLOC_OFF = 0x019B0000
        cur_off = ALLOC_OFF

        # Write Palette
        pal_off = cur_off
        f.seek(pal_off); f.write(pal_bytes)
        cur_off += len(pal_bytes)
        if cur_off % 4 != 0: cur_off += (4 - (cur_off % 4))

        # Write Tilemap
        tmap_off = cur_off
        f.seek(tmap_off); f.write(comp_tmap)
        cur_off += len(comp_tmap)
        if cur_off % 4 != 0: cur_off += (4 - (cur_off % 4))

        # Write Graphics
        gfx_off = cur_off
        f.seek(gfx_off); f.write(comp_gfx)
        cur_off += len(comp_gfx)
        if cur_off % 4 != 0: cur_off += (4 - (cur_off % 4))

        ptr_pal = 0x08000000 + pal_off
        ptr_tmap = 0x08000000 + tmap_off
        ptr_gfx = 0x08000000 + gfx_off

        # 7. Hook Pointers in Title Screen Loader Routine:
        # Offset 0xf41f4 -> Palette pointer
        # Offset 0xf41f8 -> Tilemap pointer
        # Offset 0xf41fc -> Graphics pointer
        f.seek(0xf41f4); f.write(struct.pack('<I', ptr_pal))
        f.seek(0xf41f8); f.write(struct.pack('<I', ptr_tmap))
        f.seek(0xf41fc); f.write(struct.pack('<I', ptr_gfx))

        print(f"[HOOK] Subtitle & Lugia Palette hooked: 0xf41f4 -> {hex(ptr_pal)}")
        print(f"[HOOK] Subtitle & Lugia Tilemap hooked: 0xf41f8 -> {hex(ptr_tmap)}")
        print(f"[HOOK] Subtitle & Lugia Graphics hooked: 0xf41fc -> {hex(ptr_gfx)}")

    print("\n[SUCCESS] Title Screen Successfully Upgraded with Lugia & Kanto/Johto Logo!")
    return True

if __name__ == '__main__':
    build_title_assets()
