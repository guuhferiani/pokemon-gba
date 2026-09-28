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
| `0x05A1DC` | `TestRunningShoes` (Tênis Nativo) | **`01 20 70 47`** (`MOV R0,#1; BX LR`) | Tênis de corrida sempre ativo nativamente desde o primeiro passo em Pallet. |
| `0x0BD14C` | `PlayerNotOnBikeMoving` (Auto-Run) | **`0C D0`** (`BEQ 0xBD168`) | Auto-Run ativo por padrão (2x velocidade de corrida); segurar B anda devagar. |
| `0x1D99C4` / `0x1D9A3C` | Fast Catch (Pular tela de apelido) | **`0x081D9A50`** / **`28 50 9A 1D 08`** | Pula diálogo e prompt de apelido ao capturar qualquer Pokémon selvagem. |
| `0xC4D8A` | Limite de busca de nomes de mapa | **`FF 2D`** (`CMP R5, #255`) | Permite seções de mapa expandidas (197..237) para nomes de Johto. |
| `0xC0C94` / `0xC4DB8` | Ponteiros da tabela de seções | **`0x09940000`** (`gRegionMapNames`) | Tabela expandida com todos os nomes de Johto e Ginásios em PT-BR. |
| `0x0000BD` | Checksum Complement Cabeçalho GBA | **`0xFB`** (recalculado dinamicamente) | Garante boot sem erro em emuladores rigorosos de Android (Pizza Boy, RetroArch). |
| `0x1695bb` | Hook pós-jogo Prof. Carvalho (Oak Lab) | **`0x09831000`** (Script Carvalho pós-Liga) | Dispara autorização internacional e passagem do S.S. Aqua após o Hall da Fama. |
| `0x3b5538` | Hook Marinheiro Vermilion Port | **`0x09830000`** (Script S.S. Aqua) | Controla embarque para Johto (checa Hall da Fama e autorização do Carvalho). |
| `0x259754` | `gEvolutionTable` | Dual Evolution Paths | Evoluções sem troca por nível ou pedra/item alternativo para 10 espécies. |
| `0x3DB028` | `gItems` (Itens de Evolução) | `type=1`, `fieldUseFunc=0x080A1751` | King's Rock, Metal Coat, Dragon Scale, Up-Grade usáveis diretamente da mochila. |
| `0x0441B8` | `IsMoveHm` (HMs Esquecíveis) | **`00 20 70 47`** (`MOV R0,#0; BX LR`) | Permite esquecer e substituir qualquer HM a qualquer momento via TM ou nível. |
| `0x055D30` | `Overworld_GetFlashLevel` (Auto-Flash) | **`00 20 70 47`** (`MOV R0,#0; BX LR`) | Cavernas escuras (Rock Tunnel, Dark Cave) sempre iluminadas sem círculo de sombra. |
| `0x05C84A` | `PartyHasMonWithSurf` (Surf Prático) | **`01 20 19 E0`** (`MOV R0,#1; B 0x5C882`) | Permite surfar ao pressionar A virado para a água tendo a Insígnia do Pântano. |
| `0x15FBA4` | `gScriptCmdTable[0x7c]` (checkpartymove) | **`0x099A8001`** (Ponteiro Thumb) | Reponta `checkpartymove` para rotina que aciona o Pokémon líder se ninguém souber o golpe. |
| `0x78aa0..0x78aa8`| Pointers da Title Screen | Assets Charizard vs Lugia | Free space em `0xeb0b20` / `0x01800000+`. |

## Save Data (SaveBlock2)
- **National Dex Magic**: No PT-BR BPRE, o byte mágico da National Dex (`0xB9`) fica em **`SaveBlock2 + 0x1B`** (e não `+0x1A`).

## Alocação de Memória Expandida (32MB)

| Offset ROM | Ponteiro GBA | Conteúdo |
|---|---|---|
| `0x01800000` | `0x09800000` | Boss Teams de Johto (Falkner a Red/Gold + Executivo Archer) |
| `0x01810000` | `0x09810000` | Scripts & Diálogos PT-BR dos 8 Líderes de Johto + Archer + Gold |
| `0x01820000` | `0x09820000` | Scripts Lendários de Johto (Gyarados Vermelho Lv 75, Sudowoodo Lv 60, Lugia, Ho-Oh, Feras) |
| `0x01830000` | `0x09830000` | Scripts Narrativos Kanto ↔ Johto (Oak, Vermilion Sailor, Johto Sailor, Guide, Elm) |
| `0x01840000` | `0x09840000` | Tabela expandida de treinadores (753 treinadores com IA competitiva) |
| `0x01900000` | `0x09900000` | `gMapGroups` expandido (Banks 0..44) |
| `0x01910000` | `0x09910000` | Headers e tabelas de mapas de Johto (Bank 43: 31 mapas, Bank 44: 14 mapas) |
| `0x01920000` | `0x09920000` | MapEvents Customizados (New Bark Town, 8 Ginásios, Torre de Rádio, Mt. Silver, Dungeons Lendárias) |
| `0x01930000` | `0x09930000` | MapConnections (Conexões contínuas e bidirecionais das Rotas 29 a 46 e Cidades) |
| `0x01940000` | `0x09940000` | Tabela de Nomes de Região Expandida (153 seções com títulos PT-BR de Johto) |
| `0x01980000` | `0x09980000` | Tabela expandida de selvagens de Johto (164 entradas, Lv 55 a 100) |
| `0x01990000` | `0x09990000` | Tabela Physical / Special Split Gen 4 (356 golpes) |
| `0x019A8000` | `0x099A8000` | Rotina ASM `ScrCmd_checkpartymove_practical` (HMs Práticas no Overworld) |

## Estado (2026-09-27)

- ROM compilada e funcional ✅
- Narrativa Kanto ↔ Johto completa e bidirecional na ROM ✅
- Evento pós-jogo Prof. Carvalho (Pallet) & Marinheiro S.S. Aqua (Vermilion) ativos ✅
- Chegada em Johto (New Bark Town) com guia, retorno a Kanto e cura no Lab Elm ✅
- Banco de Mapas de Johto (Bank 43) completo com 31 mapas (Rotas 29 a 46, Cidades e Mt. Silver) ✅
- Conexões contínuas de mapa (MapConnections) 100% bidirecionais sem telas de transição ✅
- Banco de Interiores e Ginásios (Bank 44) completo com os 8 Líderes, Torre de Rádio, Gold e 3 Dungeons Lendárias ✅
- Scripts de batalha, diálogos PT-BR e entrega de insígnias implementados para todos os líderes ✅
- Nomes de mapa na tela (pop-up banner) ativos em português para todas as áreas de Johto ✅
- Encontros selvagens de alto nível (Lv 55 a 100) ativos em todas as rotas de Johto e Monte Silver ✅
- Saída de edifícios / warps 100% funcionais ✅
- Fast Catch (pular tela de apelido na captura) ativo ✅
- Auto-Run nativo (2x velocidade de corrida por padrão, segurar B para andar) ✅
- Corrida em interiores e Physical/Special Split ativos ✅
- National Dex nativa sempre ativa ✅
- Checksum GBA de cabeçalho válido para Android ✅
- Tela de título customizada (Charizard vs Lugia) ✅
- Evoluções sem Troca: 10 espécies clássicas de Kanto e Johto (Alakazam, Machamp, Golem, Gengar, Steelix, Scizor, Kingdra, Slowking, Politoed, Porygon2) por nível ou uso direto de itens da Bag (King's Rock, Metal Coat, Dragon Scale, Up-Grade) ✅
- Experiência Pura Kanto + Johto (100% Gen 1 & 2): Remoção total de espécies e itens da Gen 3 (Hoenn). Dusclops de Morty substituído por Haunter; Walrein de Pryce substituído por Dewgong. Clamperl, Dente do Mar e Escama do Mar removidos. Todos os 10 chefes, 164 tabelas selvagens e 11 lendários/estáticos usam estritamente espécies 1..251 ✅
- Eventos Lendários de Johto: Gyarados Vermelho (Lago da Fúria Lv 75 com drop da Escama Vermelha), Sudowoodo (Rota 36 Lv 60), Lugia (Whirl Islands Lv 85), Ho-Oh (Bell Tower Lv 85) e o Trio de Feras (Raikou, Entei, Suicune Lv 80 na Torre Queimada) 100% ativos com diálogos PT-BR ✅
- Preservação total dos 4 Lendários originais de Kanto (Articuno, Zapdos, Moltres, Mewtwo) garantida e verificada ✅
- Modificação 3: HMs Práticas e Flash Automático (Opção 3):
  * **HMs 100% Esquecíveis**: Qualquer golpe de HM pode ser deletado ou trocado a qualquer momento via TM ou nível sem ir ao Move Deleter.
  * **HMs de Campo Práticas (Cut, Rock Smash, Strength, Waterfall, Surf)**: Interação direta com o botão A nas árvores, rochas, pedras e água. Se nenhum Pokémon souber o golpe, o Pokémon líder da equipe executa a ação se você tiver a respectiva insígnia.
  * **Flash Automático**: Cavernas escuras (Rock Tunnel, Dark Cave, Whirl Islands) ficam sempre 100% iluminadas e nítidas.
- Modificação 4: Lojas Competitivas, Relearner Gratuito e Rematch E4 Puro Gen 1 & 2:
  * **Elite Four Rematches (Treinadores 735..741)**: Lorelei, Bruno, Agatha, Lance e Rival têm times 100% Gen 1 e Gen 2 (sem espécies de Hoenn) com níveis Lv 80 a 90, 6 Pokémon cada e IA inteligente competitiva (0x07).
  * **Rematch Imediato Desbloqueado**: Flag `0x844` (`FLAG_SYS_CAN_LINK_WITH_RS`) é ativada pelo Prof. Carvalho logo após a Liga Índigo e no S.S. Aqua, liberando os rematches da E4 e compatibilidade sem necessidade de missões das Sevii Islands.
  * **Celadon Dept Store 4F Expandida**: Vende todas as 10 pedras e itens evolutivos (Sol, Lua, Fogo, Raio, Água, Folha, King's Rock, Metal Coat, Dragon Scale, Up-Grade, Pedra Eterna) além de Doce Raro.
  * **Move Relearner 100% Gratuito**: Ilha 2 (Two Island) e Goldenrod City relembram qualquer golpe do passado de graça sem cobrar cogumelos (bypass nos offsets `0x17163a`, `0x17164a` e `0x17170b`).
  * **Hub Competitivo em Goldenrod City (Bank 43 Map 10)**: Dois NPCs dedicados no centro da cidade — Balconista de Mart Competitivo (vende pedras evolutivas, itens de segurar competitivos como Leftovers, Choice Band, Focus Band, Exp Share, vitaminas completas, Doce Raro e Master Ball a 50k) e o Lembrador de Golpes Gratuito.
- Campanha Direta e Ágil: Transição direta pós-Liga de Kanto (Indigo Plateau) via S.S. Aqua (Porto de Vermilion) para Johto e Monte Silver (batalha com Gold), sem sidequests desnecessárias de Sevii Islands ✅
- Suíte de 19 testes de integridade com 100% de sucesso (`tools/verify_engine_integrity.py`) ✅
- Launcher desktop com gerenciamento de saves ✅

## Créditos

- ROM Base: Nintendo / Game Freak
- Modificações e Launcher: Gustavo Feriani (guuhferiani)

