# CONTEXT.md — Pokémon Kanto+Johto Definitivo

> **Para agentes de IA:** Leia este arquivo antes de qualquer modificação.
> É a fonte de verdade do projeto. Última verificação: 2026-09-26.

---

## Resumo do Projeto

ROM hack de Pokémon FireRed (GBA, BPRE PT-BR) que unifica Kanto e Johto.
- Base: `FireRed.gba` (16MB → expandida para 32MB)
- Output: `roms/Pokemon Kanto Johto.gba` (32MB, Game Code: BPKJ) — **Atenção:** nome com espaços!
- Launcher desktop: Lua/LÖVE2D (`main.lua`)
- Engine de compilação: Python (`tools/kj_rom_engine.py`)

## Regras Críticas

1. **Nunca editar** `roms/Pokemon Kanto Johto.gba` manualmente via hex editor avulso.
2. **Toda modificação na ROM** deve ser feita exclusivamente via `tools/kj_rom_engine.py`.
3. **Binários não vão ao Git** (`.gba`, `.sav`, `.exe`, `.srm` no `.gitignore`).
4. **O Launcher Lua** é independente da ROM.
5. **Cuidado com Offsets ASM**: Consulte a tabela abaixo antes de aplicar qualquer patch em código compilado.

## Tabela Canônica de Offsets ASM & Patches

| Endereço ROM | Função / Propósito | Estado / Conteúdo Canônico | Alerta Anti-Alucinação |
|---|---|---|---|
| `0x06DC04` | `CheckDirectionalWarp` (saída Sul/Norte) | **`0D E0 00 06`** (`B 0x6DC22; LSL R0,#24`) | **NUNCA TOCAR / NUNCA NOPEAR**. É o retorno do teste de tapete de saída (0x64). Se alterar, o jogador **não sai de imóveis**. |
| `0x06E25C` | `IsNationalPokedexEnabled` (PT-BR) | **`01 20 70 47`** (`MOV R0,#1; BX LR`) | Local correto da função da National Dex no PT-BR. Torna a Dex sempre ON. |
| `0x0CE818` | Loop da cena de evolução | **`6A 46 71 F7`** (`MOV R2,SP; BL 0x4037C`) | **NUNCA TOCAR**. Não é trava de evolução; a trava é bypassada por `0x06E25C`. |
| `0x0BD494` | `IsRunningDisallowed` (Run Indoors) | **`00 40 00 28`** (`ANDS R0,R0; CMP R0,#0`) | Patch oficial para permitir B-Button correr dentro de prédios/cavernas. |
| `0x0000BD` | Checksum Complement Cabeçalho GBA | **`0xFB`** (recalculado dinamicamente) | Garante boot sem erro em emuladores rigorosos de Android (Pizza Boy, RetroArch). |
| `0x1695bb` | Hook pós-jogo Prof. Carvalho (Oak Lab) | **`0x09831000`** (Script Carvalho pós-Liga) | Dispara autorização internacional e passagem do S.S. Aqua após o Hall da Fama. |
| `0x3b5538` | Hook Marinheiro Vermilion Port | **`0x09830000`** (Script S.S. Aqua) | Controla embarque para Johto (checa Hall da Fama e autorização do Carvalho). |
| `0x78aa0..0x78aa8`| Pointers da Title Screen | Assets Charizard vs Lugia | Free space em `0xeb0b20` / `0x01800000+`. |

## Save Data (SaveBlock2)
- **National Dex Magic**: No PT-BR BPRE, o byte mágico da National Dex (`0xB9`) fica em **`SaveBlock2 + 0x1B`** (e não `+0x1A`).

## Alocação de Memória Expandida (32MB)

| Offset ROM | Ponteiro GBA | Conteúdo |
|---|---|---|
| `0x01800000` | `0x09800000` | Boss Teams de Johto (Falkner a Red/Gold) |
| `0x01830000` | `0x09830000` | Scripts Narrativos Kanto ↔ Johto (Oak, Vermilion Sailor, Johto Sailor, Guide, Elm) |
| `0x01840000` | `0x09840000` | Tabela expandida de treinadores (752 treinadores) |
| `0x01900000` | `0x09900000` | `gMapGroups` expandido (Banks 0..44) |
| `0x01910000` | `0x09910000` | Headers e tabelas de mapas de Johto (Bank 43 e Bank 44) |
| `0x01920000` | `0x09920000` | MapEvents Customizados (New Bark Town e Lab Prof. Elm) |
| `0x01980000` | `0x09980000` | Tabela expandida de selvagens (Lv 55 a 95) |
| `0x01990000` | `0x09990000` | Tabela Physical / Special Split Gen 4 (356 golpes) |

## Estado (2026-09-27)

- ROM compilada e funcional ✅
- Narrativa Kanto ↔ Johto completa e bidirecional na ROM ✅
- Evento pós-jogo Prof. Carvalho (Pallet) & Marinheiro S.S. Aqua (Vermilion) ativos ✅
- Chegada em Johto (New Bark Town) com guia, retorno a Kanto e cura no Lab Elm ✅
- Saída de edifícios / warps 100% funcionais ✅
- Corrida em interiores e Physical/Special Split ativos ✅
- National Dex nativa sempre ativa ✅
- Checksum GBA de cabeçalho válido para Android ✅
- Tela de título customizada (Charizard vs Lugia) ✅
- Launcher desktop com gerenciamento de saves ✅

## Créditos

- ROM Base: Nintendo / Game Freak
- Modificações e Launcher: Gustavo Feriani (guuhferiani)
