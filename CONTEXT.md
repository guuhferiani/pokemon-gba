# CONTEXT.md — Pokémon Kanto+Johto Definitivo

> **Para agentes de IA:** Leia este arquivo antes de qualquer modificação.
> É a fonte de verdade do projeto. Última verificação: 2026-09-24.

---

## Resumo do Projeto

ROM hack de Pokémon FireRed (GBA, BPRE) que unifica Kanto e Johto.
- Base: `FireRed.gba` (16MB → expandida para 32MB)
- Output: `roms/Pokemon_Kanto_Johto.gba` (32MB, Game Code: BPKJ)
- Launcher desktop: Lua/LÖVE2D (`main.lua`)
- Engine de compilação: Python (`tools/kj_rom_engine.py`)

## Regras Críticas

1. **Nunca editar** `roms/Pokemon_Kanto_Johto.gba` manualmente
2. **Toda modificação na ROM** deve ser feita via `tools/kj_rom_engine.py`
3. **Binários não vão ao Git** (`.gba`, `.sav`, `.exe`, `.srm` no `.gitignore`)
4. **O Launcher Lua** é independente da ROM

## Estrutura de Pastas

| Pasta/Arquivo | Propósito |
|---|---|
| `tools/kj_rom_engine.py` | Engine principal — compila a ROM final |
| `tools/patch_title_screen.py` | Tela de título customizada (Charizard vs Lugia) |
| `src/ui/` | Componentes do Launcher desktop |
| `mods/` | Patches modulares opcionais |
| `assets/` | Box art e imagens |
| `roms/` | ROMs e saves (ignorados no Git) |
| `saves/` | Saves gerenciados pelo Launcher |
| `emulator/` | mGBA embutido (ignorado no Git) |

## Offsets ROM Importantes

| Endereço | Uso |
|---|---|
| `0x78aa0` | Pointer table: sprite BG tela de título |
| `0x78aa4` | Pointer table: paleta tela de título |
| `0x78aa8` | Pointer table: loader config |
| `0xeb0b20` | Bloco livre para assets customizados |

## Mods Ativos no Build Padrão

- `physical_special_split` ✅
- `run_indoors` ✅

## Estado (2026-09-24)

- ROM compilada e funcional ✅
- Tela de título customizada ✅
- Launcher com box art ✅
- GitHub limpo (sem binários) ✅

## Créditos

- ROM Base: Nintendo / Game Freak
- Modificações e Launcher: Gustavo Feriani (guuhferiani)
