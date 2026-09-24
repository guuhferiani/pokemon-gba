#!/usr/bin/env python3
"""
Pokemon Kanto & Johto Definitivo - Authentic Title Screen Compiler
Integrates:
 1. Lugia (Silver/SoulSilver Mascot) facing Charizard in the title screen duel on BG 1
 2. Seamless shared palette integration (Palette 13) preserving Charizard and Lugia colors
 3. GBA BIOS LZ77 compressed streams written to safe ROM free space (0xeb0b20)
 4. Pointers hooked at official FireRed title loader tables:
    - 0x78aa0: BoxArtMonPals
    - 0x78aa4: BoxArtMonTiles (LZ77)
    - 0x78aa8: BoxArtMonMap (LZ77)
    - 0x796c4 & 0x78f90: BoxArtMonPals reloads
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

def rgb555(r, g, b):
    return (r >> 3) | ((g >> 3) << 5) | ((b >> 3) << 10)

def remap_lugia_col(c):
    if c == 0: return 0
    if c == 5: return 3 # Pure White body
    if c in (3, 4, 8, 12, 13): return 4 # Silver-slate shading
    if c in (6, 7, 9, 10): return 2 # Royal Indigo belly & crests
    return 1 # Black outline

def build_title_assets():
    if not os.path.exists(ROM_PATH):
        print(f"[ERROR] ROM not found at: {ROM_PATH}")
        return False

    with open(ROM_PATH, 'rb') as f:
        rom = bytearray(f.read())

    # 1. Decompress original Charizard title screen assets (BG 1)
    charizard_tiles = lz77_decompress(rom, 0xead608)
    charizard_tmap = lz77_decompress(rom, 0xeadee4)
    charizard_pal = rom[0xead5e8 : 0xead5e8 + 32]

    # 2. Decompress Lugia front battle sprite from Gen 3 ROM tables (0x7748c0)
    lugia_raw = lz77_decompress(rom, 0x7748c0)

    # 3. Build unified 16-color Palette 13 (Charizard + Lugia)
    colors_raw = list(struct.unpack('<16H', charizard_pal))
    colors_raw[2] = rgb555(45, 60, 130)    # Royal Indigo (Lugia belly & eye spikes)
    colors_raw[3] = rgb555(255, 255, 255)  # Pure White (Lugia body)
    colors_raw[4] = rgb555(180, 195, 225)  # Silver Slate (Lugia shadows)
    # Colors 6..15 remain authentic Charizard flame and scales
    new_pal_bytes = bytearray()
    for c in colors_raw:
        new_pal_bytes.extend(struct.pack('<H', c))

    # 4. Build combined tiles: Charizard tiles (0..134) + Lugia tiles (135..198)
    combined_tiles = bytearray(charizard_tiles)
    lugia_start_tile = len(charizard_tiles) // 32

    # Decode Lugia's 64x64 sprite into grid, flipping horizontally so Lugia faces Charizard
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

    # Encode flipped Lugia into 4bpp GBA tiles
    for ty in range(8):
        for tx in range(8):
            tile_bytes = bytearray(32)
            for y in range(8):
                for x in range(0, 8, 2):
                    c1 = grid[ty*8 + y][tx*8 + x]
                    c2 = grid[ty*8 + y][tx*8 + x + 1]
                    tile_bytes[y*4 + x//2] = (c2 << 4) | c1
            combined_tiles.extend(tile_bytes)

    # 5. Build combined tilemap: Charizard at cols 17..30 + Lugia at cols 1..8, rows 10..17
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

    # 6. Compress with BIOS-compatible LZ77
    comp_tiles = lz77_compress(bytes(combined_tiles))
    comp_tmap = lz77_compress(bytes(new_tmap_bytes))
    print(f"[TITLE] Combined Tiles compressed: {len(combined_tiles)} -> {len(comp_tiles)} bytes")
    print(f"[TITLE] Combined Tilemap compressed: {len(new_tmap_bytes)} -> {len(comp_tmap)} bytes")

    # 7. Write to safe ROM free space (0xeb0b20)
    cur_off = 0xeb0b20
    pal_off = cur_off
    cur_off += len(new_pal_bytes)
    while cur_off % 4 != 0: cur_off += 1

    tiles_off = cur_off
    cur_off += len(comp_tiles)
    while cur_off % 4 != 0: cur_off += 1

    tmap_off = cur_off
    cur_off += len(comp_tmap)
    while cur_off % 4 != 0: cur_off += 1

    ptr_pal = 0x08000000 + pal_off
    ptr_tiles = 0x08000000 + tiles_off
    ptr_tmap = 0x08000000 + tmap_off

    rom[pal_off : pal_off + len(new_pal_bytes)] = new_pal_bytes
    rom[tiles_off : tiles_off + len(comp_tiles)] = comp_tiles
    rom[tmap_off : tmap_off + len(comp_tmap)] = comp_tmap

    # 8. Hook official FireRed title screen loader pointers
    struct.pack_into('<I', rom, 0x78aa0, ptr_pal)
    struct.pack_into('<I', rom, 0x78aa4, ptr_tiles)
    struct.pack_into('<I', rom, 0x78aa8, ptr_tmap)
    struct.pack_into('<I', rom, 0x796c4, ptr_pal)
    struct.pack_into('<I', rom, 0x78f90, ptr_pal)

    with open(ROM_PATH, 'wb') as f:
        f.write(rom)

    print(f"\n[SUCCESS] Title Screen updated with Charizard vs Lugia Duel!")
    print(f"  • Palette Pointer: 0x78aa0 -> {hex(ptr_pal)}")
    print(f"  • Tileset Pointer: 0x78aa4 -> {hex(ptr_tiles)}")
    print(f"  • Tilemap Pointer: 0x78aa8 -> {hex(ptr_tmap)}")
    return True

if __name__ == '__main__':
    build_title_assets()
