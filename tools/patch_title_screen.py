#!/usr/bin/env python3
"""
Pokemon Kanto & Johto Definitivo - Authentic Title Screen Compiler
Integrates:
 1. Lugia (Silver/SoulSilver Mascot) facing Charizard in the title screen duel on BG 1
 2. Seamless shared palette integration (Palette 13) preserving Charizard and Lugia colors
 3. Custom "KANTO JOHTO" Subtitle replacing "FIRERED DEFINITIVO"
 4. Author tag "guh feriani" in the top black band
 5. GBA BIOS LZ77 compressed streams written to safe ROM free space
 6. Pointers hooked at official FireRed title loader tables:
    - 0x78aa0: BoxArtMonPals
    - 0x78aa4: BoxArtMonTiles (LZ77)
    - 0x78aa8: BoxArtMonMap (LZ77)
    - 0x78a98: LogoTiles (LZ77)
    - 0x78a9c: LogoTilemap (LZ77)
"""

import os
import struct

def find_rom_path():
    candidates = [
        os.path.join(os.path.dirname(__file__), "..", "roms", "Pokemon Kanto Johto.gba"),
        os.path.join(os.path.dirname(__file__), "..", "roms", "Pokemon_Kanto_Johto.gba"),
        os.path.join(os.path.dirname(__file__), "..", "Pokemon Kanto Johto.gba"),
        os.path.join(os.path.dirname(__file__), "..", "Pokemon_Kanto_Johto.gba")
    ]
    for c in candidates:
        if os.path.exists(c):
            return c
    return candidates[0]

ROM_PATH = find_rom_path()

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

def rgb555(r, g, b):
    return (r >> 3) | ((g >> 3) << 5) | ((b >> 3) << 10)

def remap_lugia_col(c):
    if c == 0: return 0
    if c == 5: return 3 # Pure White body
    if c in (3, 4, 8, 12, 13): return 4 # Silver-slate shading
    if c in (6, 7, 9, 10): return 2 # Royal Indigo belly & crests
    return 1 # Black outline

GLYPHS = {
    'K': [
        "###   ####",
        "###  #### ",
        "### ####  ",
        "#######   ",
        "######    ",
        "#######   ",
        "### ####  ",
        "###  #### ",
        "###   ####",
        "###    ###",
        "###    ###",
        "###    ###"
    ],
    'A': [
        "  ######  ",
        " ######## ",
        " #### ####",
        "####   ###",
        "####   ###",
        "##########",
        "##########",
        "####   ###",
        "####   ###",
        "####   ###",
        "####   ###",
        "####   ###"
    ],
    'N': [
        "####   ###",
        "#####  ###",
        "###### ###",
        "##########",
        "### ######",
        "###  #####",
        "###   ####",
        "###    ###",
        "###    ###",
        "###    ###",
        "###    ###",
        "###    ###"
    ],
    'T': [
        "##########",
        "##########",
        "   ####   ",
        "   ####   ",
        "   ####   ",
        "   ####   ",
        "   ####   ",
        "   ####   ",
        "   ####   ",
        "   ####   ",
        "   ####   ",
        "   ####   "
    ],
    'O': [
        "  ######  ",
        " ######## ",
        "####   ###",
        "###     ##",
        "###     ##",
        "###     ##",
        "###     ##",
        "###     ##",
        "####   ###",
        " ######## ",
        "  ######  ",
        "   ####   "
    ],
    'J': [
        "    ######",
        "    ######",
        "       ###",
        "       ###",
        "       ###",
        "       ###",
        "###    ###",
        "####   ###",
        " #########",
        "  ####### ",
        "   #####  ",
        "    ###   "
    ],
    'H': [
        "###    ###",
        "###    ###",
        "###    ###",
        "###    ###",
        "##########",
        "##########",
        "###    ###",
        "###    ###",
        "###    ###",
        "###    ###",
        "###    ###",
        "###    ###"
    ]
}

MINI_FONT = {
    'g': [
        " 111 ",
        "1   1",
        " 1111",
        "    1",
        "1   1",
        " 111 "
    ],
    'u': [
        "1   1",
        "1   1",
        "1   1",
        "1   1",
        "1   1",
        " 1111"
    ],
    'h': [
        "1    ",
        "1    ",
        "1111 ",
        "1   1",
        "1   1",
        "1   1"
    ],
    ' ': [
        "  ",
        "  ",
        "  ",
        "  ",
        "  ",
        "  "
    ],
    'f': [
        "  11",
        " 1  ",
        "111 ",
        " 1  ",
        " 1  ",
        " 1  "
    ],
    'e': [
        " 111 ",
        "1   1",
        "11111",
        "1    ",
        "1   1",
        " 111 "
    ],
    'r': [
        "1 11",
        "11  ",
        "1   ",
        "1   ",
        "1   ",
        "1   "
    ],
    'i': [
        "1",
        " ",
        "1",
        "1",
        "1",
        "1"
    ],
    'a': [
        " 111 ",
        "    1",
        " 1111",
        "1   1",
        "1  11",
        " 11 1"
    ],
    'n': [
        "1111 ",
        "1   1",
        "1   1",
        "1   1",
        "1   1",
        "1   1"
    ]
}

def render_line(word, fill_col=105, highlight_col=109, shadow_col=108, outline_col=1):
    letter_widths = [len(GLYPHS[ch][0]) for ch in word]
    spacing = 2
    total_w = sum(letter_widths) + spacing * (len(word) - 1)
    h = 16
    grid = [[0] * total_w for _ in range(h)]
    cur_x = 0
    for ch in word:
        glyph = GLYPHS[ch]
        gw = len(glyph[0])
        gh = len(glyph)
        start_y = (h - gh) // 2
        for y in range(gh):
            for x in range(gw):
                if glyph[y][x] == '#':
                    col = fill_col
                    if y < 3: col = highlight_col
                    elif y >= gh - 3: col = shadow_col
                    grid[start_y + y][cur_x + x] = col
        cur_x += gw + spacing
    
    out_w = total_w + 2
    out_grid = [[0] * out_w for _ in range(h)]
    for y in range(h):
        for x in range(total_w):
            if grid[y][x] != 0:
                out_grid[y][x + 1] = grid[y][x]
    
    final_grid = [[0] * out_w for _ in range(h)]
    for y in range(h):
        for x in range(out_w):
            if out_grid[y][x] != 0:
                final_grid[y][x] = out_grid[y][x]
            else:
                has_n = False
                for dy in [-1, 0, 1]:
                    for dx in [-1, 0, 1]:
                        if dy == 0 and dx == 0: continue
                        ny, nx = y + dy, x + dx
                        if 0 <= ny < h and 0 <= nx < out_w and out_grid[ny][nx] != 0:
                            has_n = True; break
                    if has_n: break
                if has_n: final_grid[y][x] = outline_col
                
    return final_grid, out_w, h

def render_mini_text(text, fill_col=109, shadow_col=112):
    widths = [len(MINI_FONT[ch][0]) for ch in text]
    spacing = 1
    total_w = sum(widths) + spacing * (len(text) - 1)
    grid = [[0] * total_w for _ in range(8)]
    cur_x = 0
    for ch in text:
        g = MINI_FONT[ch]
        gw = len(g[0])
        gh = len(g)
        start_y = 1
        for y in range(gh):
            for x in range(gw):
                if g[y][x] == '1':
                    grid[start_y + y][cur_x + x] = fill_col
                    if start_y + y + 1 < 8 and grid[start_y + y + 1][cur_x + x] == 0:
                        grid[start_y + y + 1][cur_x + x] = shadow_col
        cur_x += gw + spacing
    return grid, total_w

def build_title_assets():
    target_roms = []
    r1 = os.path.join(os.path.dirname(__file__), "..", "roms", "Pokemon Kanto Johto.gba")
    r2 = os.path.join(os.path.dirname(__file__), "..", "roms", "Pokemon_Kanto_Johto.gba")
    if os.path.exists(r1): target_roms.append(r1)
    if os.path.exists(r2) and r2 not in target_roms: target_roms.append(r2)
    if not target_roms:
        target_roms = [r1]

    for rom_path in target_roms:
        if not os.path.exists(rom_path):
            continue
        print(f"[TITLE] Processing ROM: {rom_path}")
        with open(rom_path, 'rb') as f:
            rom = bytearray(f.read())

        # =====================================================================
        # PART 1: CHARIZARD VS LUGIA DUEL ON BG1
        # =====================================================================
        charizard_tiles = lz77_decompress(rom, 0xead608)
        charizard_tmap = lz77_decompress(rom, 0xeadee4)
        charizard_pal = rom[0xead5e8 : 0xead5e8 + 32]
        lugia_raw = lz77_decompress(rom, 0x7748c0)

        colors_raw = list(struct.unpack('<16H', charizard_pal))
        colors_raw[2] = rgb555(45, 60, 130)    # Royal Indigo
        colors_raw[3] = rgb555(255, 255, 255)  # Pure White
        colors_raw[4] = rgb555(180, 195, 225)  # Silver Slate
        new_pal_bytes = bytearray()
        for c in colors_raw:
            new_pal_bytes.extend(struct.pack('<H', c))

        combined_tiles = bytearray(charizard_tiles)
        lugia_start_tile = len(charizard_tiles) // 32

        grid = [[0]*64 for _ in range(64)]
        for ty in range(8):
            for tx in range(8):
                tile_idx = ty * 8 + tx
                tile_data = lugia_raw[tile_idx * 32 : (tile_idx + 1) * 32]
                for y in range(8):
                    row = tile_data[y*4 : (y+1)*4]
                    for x in range(0, 8, 2):
                        b = row[x//2]
                        grid[ty*8 + y][63 - (tx*8 + x)] = remap_lugia_col(b & 0xF)
                        grid[ty*8 + y][63 - (tx*8 + x + 1)] = remap_lugia_col((b >> 4) & 0xF)

        for ty in range(8):
            for tx in range(8):
                tile_bytes = bytearray(32)
                for y in range(8):
                    for x in range(0, 8, 2):
                        c1 = grid[ty*8 + y][tx*8 + x]
                        c2 = grid[ty*8 + y][tx*8 + x + 1]
                        tile_bytes[y*4 + x//2] = (c2 << 4) | c1
                combined_tiles.extend(tile_bytes)

        tmap_entries = list(struct.unpack(f'<{len(charizard_tmap)//2}H', charizard_tmap))
        lugia_col = 1
        lugia_row = 10
        for ty in range(8):
            for tx in range(8):
                tile_id = lugia_start_tile + (ty * 8 + tx)
                tile_data = combined_tiles[tile_id * 32 : (tile_id + 1) * 32]
                if any(b != 0 for b in tile_data):
                    row = lugia_row + ty
                    col = lugia_col + tx
                    if row < 20 and col < 32:
                        tmap_entries[row * 32 + col] = (13 << 12) | tile_id

        new_tmap_bytes = bytearray()
        for e in tmap_entries:
            new_tmap_bytes.extend(struct.pack('<H', e))

        comp_char_tiles = lz77_compress(bytes(combined_tiles))
        comp_char_tmap = lz77_compress(bytes(new_tmap_bytes))

        # Write Charizard vs Lugia to 0xeb0b20
        cur_off = 0xeb0b20
        pal_off = cur_off
        cur_off += len(new_pal_bytes)
        while cur_off % 4 != 0: cur_off += 1

        tiles_off = cur_off
        cur_off += len(comp_char_tiles)
        while cur_off % 4 != 0: cur_off += 1

        tmap_off = cur_off
        cur_off += len(comp_char_tmap)
        while cur_off % 4 != 0: cur_off += 1

        ptr_pal = 0x08000000 + pal_off
        ptr_char_tiles = 0x08000000 + tiles_off
        ptr_char_tmap = 0x08000000 + tmap_off

        rom[pal_off : pal_off + len(new_pal_bytes)] = new_pal_bytes
        rom[tiles_off : tiles_off + len(comp_char_tiles)] = comp_char_tiles
        rom[tmap_off : tmap_off + len(comp_char_tmap)] = comp_char_tmap

        struct.pack_into('<I', rom, 0x78aa0, ptr_pal)
        struct.pack_into('<I', rom, 0x78aa4, ptr_char_tiles)
        struct.pack_into('<I', rom, 0x78aa8, ptr_char_tmap)
        struct.pack_into('<I', rom, 0x796c4, ptr_pal)
        struct.pack_into('<I', rom, 0x78f90, ptr_pal)

        # =====================================================================
        # PART 2: "KANTO JOHTO" SUBTITLE & "guh feriani" LOGO LAYER
        # =====================================================================
        logo_tiles = bytearray(lz77_decompress(rom, 0x7D6CC0))
        logo_tmap = bytearray(lz77_decompress(rom, 0xEAD390))

        # Clear old subtitle (rows 7..12, cols 5..17)
        for r in range(7, 13):
            for c in range(5, 18):
                struct.pack_into('<H', logo_tmap, (r * 32 + c) * 2, 0)

        # KANTO (rows 8 & 9)
        kanto_grid, kw, kh = render_line("KANTO", fill_col=105, highlight_col=109, shadow_col=108, outline_col=1)
        kanto_canvas = [[0] * 104 for _ in range(16)]
        start_x = (104 - kw) // 2
        for y in range(kh):
            for x in range(kw):
                kanto_canvas[y][start_x + x] = kanto_grid[y][x]

        # JOHTO (rows 10 & 11)
        johto_grid, jw, jh = render_line("JOHTO", fill_col=105, highlight_col=109, shadow_col=108, outline_col=1)
        johto_canvas = [[0] * 104 for _ in range(16)]
        start_x = (104 - jw) // 2
        for y in range(jh):
            for x in range(jw):
                johto_canvas[y][start_x + x] = johto_grid[y][x]

        # guh feriani (row 00, cols 1..9)
        name_grid, nw = render_mini_text("guh feriani", fill_col=109, shadow_col=112)
        name_canvas = [[0] * 72 for _ in range(8)]
        start_name_x = (72 - nw) // 2
        for y in range(8):
            for x in range(nw):
                name_canvas[y][start_name_x + x] = name_grid[y][x]

        next_tile_id = 175
        for tr in range(2):
            row_idx = 8 + tr
            for tc in range(13):
                col_idx = 5 + tc
                tile_bytes = bytearray(64)
                has_pixels = False
                for py in range(8):
                    for px in range(8):
                        val = kanto_canvas[tr * 8 + py][tc * 8 + px]
                        tile_bytes[py * 8 + px] = val
                        if val != 0: has_pixels = True
                if has_pixels:
                    t_id = next_tile_id
                    next_tile_id += 1
                    logo_tiles[t_id * 64 : (t_id + 1) * 64] = tile_bytes
                    struct.pack_into('<H', logo_tmap, (row_idx * 32 + col_idx) * 2, t_id)

        for tr in range(2):
            row_idx = 10 + tr
            for tc in range(13):
                col_idx = 5 + tc
                tile_bytes = bytearray(64)
                has_pixels = False
                for py in range(8):
                    for px in range(8):
                        val = johto_canvas[tr * 8 + py][tc * 8 + px]
                        tile_bytes[py * 8 + px] = val
                        if val != 0: has_pixels = True
                if has_pixels:
                    t_id = next_tile_id
                    next_tile_id += 1
                    logo_tiles[t_id * 64 : (t_id + 1) * 64] = tile_bytes
                    struct.pack_into('<H', logo_tmap, (row_idx * 32 + col_idx) * 2, t_id)

        for tc in range(9):
            col_idx = 1 + tc
            tile_bytes = bytearray(64)
            has_pixels = False
            for py in range(8):
                for px in range(8):
                    val = name_canvas[py][tc * 8 + px]
                    tile_bytes[py * 8 + px] = val
                    if val != 0: has_pixels = True
            if has_pixels:
                t_id = next_tile_id
                next_tile_id += 1
                logo_tiles[t_id * 64 : (t_id + 1) * 64] = tile_bytes
                struct.pack_into('<H', logo_tmap, (0 * 32 + col_idx) * 2, t_id)

        comp_logo_tiles = lz77_compress(bytes(logo_tiles))
        comp_logo_tmap = lz77_compress(bytes(logo_tmap))

        # Write to safe expanded 32MB space at 0x019C0000
        logo_tiles_off = 0x019C0000
        logo_tmap_off = logo_tiles_off + len(comp_logo_tiles)
        while logo_tmap_off % 4 != 0: logo_tmap_off += 1

        ptr_logo_tiles = 0x08000000 + logo_tiles_off
        ptr_logo_tmap = 0x08000000 + logo_tmap_off

        rom[logo_tiles_off : logo_tiles_off + len(comp_logo_tiles)] = comp_logo_tiles
        rom[logo_tmap_off : logo_tmap_off + len(comp_logo_tmap)] = comp_logo_tmap

        struct.pack_into('<I', rom, 0x78A98, ptr_logo_tiles)
        struct.pack_into('<I', rom, 0x78A9C, ptr_logo_tmap)

        with open(rom_path, 'wb') as f:
            f.write(rom)

        print(f"[SUCCESS] {os.path.basename(rom_path)} compiled with Duel, KANTO JOHTO and guh feriani!")

    return True

if __name__ == '__main__':
    build_title_assets()
