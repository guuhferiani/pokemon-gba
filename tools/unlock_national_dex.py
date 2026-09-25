import os
import struct
import shutil
import time

SECTION_SIZES = {
    0: 3884,
    1: 3968,
    2: 3968,
    3: 3968,
    4: 3848,
    5: 3968,
    6: 3968,
    7: 3968,
    8: 3968,
    9: 3968,
    10: 3968,
    11: 3968,
    12: 3968,
    13: 2000
}

def calculate_checksum(data, sec_offset, sec_id):
    size = SECTION_SIZES.get(sec_id, 3968)
    words_count = size // 4
    total = 0
    for w in range(words_count):
        off = sec_offset + w * 4
        word = struct.unpack_from('<I', data, off)[0]
        total = (total + word) & 0xFFFFFFFF
    lower16 = total & 0xFFFF
    upper16 = (total >> 16) & 0xFFFF
    return (lower16 + upper16) & 0xFFFF

def find_sections_in_slot(data, slot_base):
    sec_map = {}
    counter = 0
    for s in range(14):
        sec_off = slot_base + s * 0x1000
        footer = sec_off + 0x0FF4
        sec_id, chk, sig, c = struct.unpack('<HHII', data[footer:footer+12])
        if sig == 0x08012025 and sec_id < 14:
            sec_map[sec_id] = sec_off
            counter = max(counter, c)
    return sec_map, counter

def upgrade_save_file(filepath, mark_all_caught=False):
    if not os.path.exists(filepath):
        print(f"[SKIP] File not found: {filepath}")
        return False

    with open(filepath, 'rb') as f:
        data = bytearray(f.read())

    if len(data) < 0x10000:
        print(f"[ERROR] Save file too small: {filepath}")
        return False

    # Create backup
    backup_dir = os.path.join(os.path.dirname(filepath), "backups")
    os.makedirs(backup_dir, exist_ok=True)
    ts = int(time.time())
    backup_path = os.path.join(backup_dir, f"{os.path.basename(filepath)}.pre_natdex_{ts}.bak")
    with open(backup_path, 'wb') as bf:
        bf.write(data)
    print(f"[BACKUP] Created {backup_path}")

    # Process BOTH save slots (0 and 1) so game continues seamlessly regardless of which slot is loaded
    slots_upgraded = 0
    for slot_idx in [0, 1]:
        slot_base = slot_idx * 0xE000
        sec_map, counter = find_sections_in_slot(data, slot_base)
        sec0 = sec_map.get(0)
        sec1 = sec_map.get(1)
        sec2 = sec_map.get(2)

        if sec0 is None or sec1 is None:
            continue

        print(f"[SLOT {slot_idx}] Upgrading National Dex (counter: {counter})...")

        # 1. Section 0 (SaveBlock2): Pokédex structure
        data[sec0 + 0x0018] = 0x01 # order
        data[sec0 + 0x0019] = 0x01 # mode: has pokedex
        data[sec0 + 0x001A] = 0x01 # dex mode flag
        data[sec0 + 0x001B] = 0xB9 # nationalMagic (0xB9 triggers IsNationalPokedexEnabled in this PT-BR build!)

        # Also register Poochyena (#261) as seen and caught if not already
        # Bit index for #261 in dex (1-based: 261 -> 0-based: 260)
        dex_num = 261
        byte_idx = (dex_num - 1) // 8
        bit_idx = (dex_num - 1) % 8
        # Owned: 0x28 + byte_idx
        data[sec0 + 0x0028 + byte_idx] |= (1 << bit_idx)
        # Seen: 0x5C, 0x90, 0xC4
        data[sec0 + 0x005C + byte_idx] |= (1 << bit_idx)
        data[sec0 + 0x0090 + byte_idx] |= (1 << bit_idx)
        data[sec0 + 0x00C4 + byte_idx] |= (1 << bit_idx)

        if mark_all_caught:
            print(f"[SLOT {slot_idx}] Marking all 386 Pokémon as caught...")
            for b in range(49):
                val = 0x03 if b == 48 else 0xFF
                data[sec0 + 0x0028 + b] = val
                data[sec0 + 0x005C + b] = val
                data[sec0 + 0x0090 + b] = val
                data[sec0 + 0x00C4 + b] = val

        # 2. Section 1 (SaveBlock1): Flags & Vars
        # FLAG_SYS_NATIONAL_DEX (0x829)
        nat_flag_byte = sec1 + 0x0EE0 + (0x829 // 8)
        data[nat_flag_byte] |= (1 << (0x829 % 8))

        # FLAG_SYS_POKEDEX_GET (0x82A)
        pok_flag_byte = sec1 + 0x0EE0 + (0x82A // 8)
        data[pok_flag_byte] |= (1 << (0x82A % 8))

        # VAR_NATIONAL_DEX (0x404E) = 0x6258 in Section 1 (offset +0x0F10)
        struct.pack_into('<H', data, sec1 + 0x0F10, 0x6258)

        # 3. Section 2 (SaveBlock1 vars if present)
        if sec2 is not None:
            var_offset = sec2 + (0x404E - 0x4000) * 2
            if var_offset + 2 <= sec2 + 0x0FF4:
                struct.pack_into('<H', data, var_offset, 0x6258)

        # Recalculate checksums for Section 0, Section 1, Section 2
        chk0 = calculate_checksum(data, sec0, 0)
        struct.pack_into('<H', data, sec0 + 0x0FF6, chk0)

        chk1 = calculate_checksum(data, sec1, 1)
        struct.pack_into('<H', data, sec1 + 0x0FF6, chk1)

        if sec2 is not None:
            chk2 = calculate_checksum(data, sec2, 2)
            struct.pack_into('<H', data, sec2 + 0x0FF6, chk2)

        slots_upgraded += 1

    with open(filepath, 'wb') as f:
        f.write(data)

    print(f"[SUCCESS] {filepath} upgraded with National Dex ({slots_upgraded} slots updated)!")
    return True

if __name__ == '__main__':
    targets = [
        os.path.join(os.path.dirname(__file__), "..", "saves", "kantojohto_slot1.sav"),
        os.path.join(os.path.dirname(__file__), "..", "roms", "Pokemon Kanto Johto.sav"),
        os.path.join(os.path.dirname(__file__), "..", "saves", "Pokemon Kanto Johto.srm")
    ]
    for t in targets:
        upgrade_save_file(t, mark_all_caught=False)
