# Pokémon Kanto+Johto Definitivo — Estado do Projeto & Âncora Técnica

> **Guia Obrigatório para Agentes de IA:**
> Consulte este documento antes de planejar ou aplicar qualquer alteração na ROM ou nos scripts.
> Atualizado em: 2026-09-26.

---

## 1. Identificação da ROM
- **Base:** Pokémon FireRed (BPRE, v1.0, tradução PT-BR).
- **Tamanho:** 32 MB (expandida de 16MB para 32MB).
- **Caminho:** `roms/Pokemon Kanto Johto.gba` *(cuidado: nome com espaços!)*.
- **Game Code do Cabeçalho:** `BPKJ`.
- **Title do Cabeçalho:** `POKEMON KJ`.
- **GBA Header Complement (0xBD):** `0xFB` (recalculado dinamicamente em `kj_rom_engine.py`).

---

## 2. Mapa Crítico de Offsets e Proteções Anti-Alucinação

| Endereço ROM | Conteúdo Canônico / Patch | Função | Alerta Crítico |
|---|---|---|---|
| `0x06DC04` | `0D E0 00 06` | Retorno do warp Sul e entrada do warp Norte em `CheckDirectionalWarp` (`0x06DBD8`) | **NUNCA ALTERAR / NUNCA NOPEAR**. Qualquer alteração faz o jogador não conseguir sair de prédios. |
| `0x06E25C` | `01 20 70 47` (`MOV R0,#1; BX LR`) | Função canônica `IsNationalPokedexEnabled` no BPRE PT-BR | Ativa National Dex no motor do jogo globalmente. |
| `0x0CE818` | `6A 46 71 F7` (`MOV R2,SP; BL 0x4037C`) | Instrução do loop em `0x0CE748` (Cena de Evolução) | **NUNCA ALTERAR**. Trava de evolução já é bypassada por `0x06E25C`. |
| `0x0BD494` | `00 40 00 28` (`ANDS R0,R0; CMP R0,#0`) | Patch oficial de corrida indoor em `IsRunningDisallowed` | Permite B-Button correr em casas, prédios e cavernas. |
| `0x0000BD` | `0xFB` | Complement Checksum do cabeçalho da ROM | Essencial para Pizza Boy, RetroArch e emuladores estritos no Android. |
| `0x05524C` | Ponteiro para `0x09900000` | Tabela `gMapGroups` repontada para Banks 0..44 | Permite mapas novos de Johto em Banks 43 e 44. |

---

## 3. Save Data (SRAM / Flash 128KB)
- **National Dex Magic:** No save PT-BR, o magic byte da National Dex (`0xB9`) fica em **`SaveBlock2 + 0x1B`** (Section 0 do save).
- Não confundir com `+0x1A` de algumas versões US em inglês.

---

## 4. Alocação de Memória Expandida (Espaço Seguro de 32MB)
- `0x01800000` (`0x09800000`): Equipes dos 8 Líderes de Johto e Red/Gold em Mt. Silver.
- `0x01830000` (`0x09830000`): Script de diálogo e warp do marinheiro do S.S. Aqua em Vermilion.
- `0x01840000` (`0x09840000`): Tabela expandida de treinadores (752 treinadores).
- `0x01900000` (`0x09900000`): `gMapGroups` expandido (Banks 0..44).
- `0x01910000` (`0x09910000`): Headers de mapa de Johto (Bank 43 Overworld, Bank 44 Interiores/Ginásios).
- `0x01980000` (`0x09980000`): Tabela expandida de encontros de selvagens (Lv 55 a 95).
- `0x01990000` (`0x09990000`): Tabela Physical / Special Split (356 golpes Gen 4).

---

## 5. Fluxo de Compilação
- Toda modificação estrutural na ROM deve ser registrada em `tools/kj_rom_engine.py` e executada via `python tools/kj_rom_engine.py`.
- O script injeta o motor unificado e automaticamente executa `patch_title_screen.py` para construir a tela de título personalizada (Charizard vs Lugia).
