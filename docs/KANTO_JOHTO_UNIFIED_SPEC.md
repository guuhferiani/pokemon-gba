# ESPECIFICAÇÃO DE DESIGN & ARQUITETURA
## PROJETO KANTO ➔ JOHTO DEFINITIVO (GBA)

Este documento registra a visão, mecânicas, curva de nível e as duas abordagens técnicas (Caminho 2: ROM Unificada e Caminho 1: Save Bridge de Backup) para a criação da jornada contínua entre Kanto e Johto.

---

## 1. VISÃO GERAL DO PROJETO

* **Conceito Central:** Inverter a progressão clássica de Pokémon Gold/Silver/SoulSilver. O jogador inicia sua história em **Kanto** (FireRed), derrota os 8 ginásios e a Liga Indigo, e em seguida **continua no mesmo save** rumo a **Johto** para disputar uma segunda conferência em alto nível.
* **Progressão da Equipe:** **Continuação Direta (High-Level)**. O jogador não perde seus Pokémon. A equipe de Kanto (níveis 55-60) entra em Johto, e todos os líderes, treinadores e Pokémon selvagens de Johto são redimensionados para os níveis 58 a 100.
* **Plataforma:** Game Boy Advance (GBA 32-bit), testado e gerenciado pelo **Pokémon GBA Studio++** no **mGBA 0.10.5**.

---

## 2. CAMINHO 2 (PRINCIPAL): ROM HACK UNIFICADA DE 2 REGIÕES

### 2.1 Base de Engenharia
* **Engine:** FireRed v1.0 (BPRE) expandida para 32MB ou Decompilação C (`pokefirered` / `pokeemerald`).
* **Estrutura de Mapas:** O FireRed original reserva bancos de mapas inteiros para as *Sevii Islands* (Ilhas 1 a 7 e ilhas de eventos). Na ROM unificada, esses bancos e novos ponteiros de mapa são alocados para acomodar toda a região de **Johto**:
  - New Bark Town, Cherrygrove City, Violet City, Azalea Town, Goldenrod City, Ecruteak City, Olivine City, Cianwood City, Mahogany Town, Blackthorn City, Mt. Silver e todas as rotas (29 a 46).
* **Transição Kanto ➔ Johto (Evento da História):**
  - Condição: Derrotar o Campeão Blue e registrar o time no Hall da Fama de Kanto.
  - Gatilho: Ao recarregar o jogo em Pallet Town, o Professor Carvalho convoca o jogador para seu laboratório. Ele informa que a Equipe Rocket está se reorganizando em Johto e que o Professor Elm precisa de um Campeão de Kanto.
  - Transporte: O jogador recebe o **S.S. Ticket (Johto)** para embarcar no porto de Vermilion City até Olivine/New Bark, ou o **Magnet Pass** na estação do Trem Magnético em Saffron City.

### 2.2 Curva de Nível (High-Level Progression)

| Etapa | Local / Desafio | Faixa de Nível | Destaques da Equipe |
| :--- | :--- | :--- | :--- |
| **Kanto Parte 1** | Ginásios 1 a 4 (Brock, Misty, Surge, Erika) | Lv 12 - Lv 32 | Progressão clássica FireRed |
| **Kanto Parte 2** | Ginásios 5 a 8 (Koga, Sabrina, Blaine, Giovanni) | Lv 37 - Lv 52 | Desafios com IA competitiva |
| **Liga Indigo** | Elite Four (Lorelei, Bruno, Agatha, Lance) & Blue | Lv 54 - Lv 62 | Hall da Fama de Kanto |
| **Chegada em Johto** | New Bark Town & Rotas 29 a 31 | Lv 55 - Lv 58 | Selvagens já em nível alto |
| **Johto Ginásio 1** | Falkner (Violet City) | Lv 58 - Lv 62 | Pidgeot, Noctowl, Skarmory |
| **Johto Ginásio 2** | Bugsy (Azalea Town) | Lv 62 - Lv 65 | Scizor, Heracross, Yanmega |
| **Johto Ginásio 3** | Whitney (Goldenrod City) | Lv 66 - Lv 69 | Miltank (Rollout/Milk Drink), Clefable |
| **Johto Ginásio 4** | Morty (Ecruteak City) | Lv 70 - Lv 73 | Gengar, Misdreavus, Dusclops |
| **Johto Ginásio 5** | Chuck (Cianwood City) | Lv 74 - Lv 76 | Poliwrath, Machamp, Hitmontop |
| **Johto Ginásio 6** | Jasmine (Olivine City) | Lv 77 - Lv 80 | Steelix, Magneton, Forretress |
| **Johto Ginásio 7** | Pryce (Mahogany Town) | Lv 81 - Lv 83 | Mamoswine, Lapras, Walrein |
| **Johto Ginásio 8** | Clair (Blackthorn City) | Lv 84 - Lv 87 | Kingdra, Dragonite, Salamence |
| **Torre de Rádio** | Confronto Final contra os Executivos Rocket | Lv 85 - Lv 88 | Archer, Ariana e Petrel |
| **Liga de Johto** | Elite dos Quatro de Johto (Will, Koga, Bruno, Karen) | Lv 88 - Lv 94 | Batalhas de alto calibre |
| **Campeão de Johto** | Lance / Campeão Johto | Lv 92 - Lv 96 | Time completo com dragões e pseudo-lendários |
| **Monte Silver** | Pico Nevado do Mt. Silver | Lv 95 - Lv 100 | Batalha lendária final contra Gold/Ethan |

### 2.3 Melhorias Modernas Integradas (QoL)
1. **Separação Físico/Especial:** Golpes categorizados por Físico, Especial ou Status independente do tipo (ex: Shadow Ball é Físico, Waterfall é Físico, Hyper Voice é Especial).
2. **Tipo Fada (Fairy Type):** Clefairy, Togepi, Marill, Snubbull e ataques como Moonblast e Dazzling Gleam presentes.
3. **Evoluções sem Troca:** Itens como *Link Cable*, pedras evolutivas ou níveis substituem a necessidade de troca para Gengar, Alakazam, Machamp, Golem, Scizor, Steelix e Kingdra.
4. **HMs Práticas:** Pokémon aprendem a cortar árvores, quebrar pedras ou surfar automaticamente se tiverem a insígnia correspondente, sem precisar gastar os 4 slots de golpes.

---

## 3. CAMINHO 1 (BACKUP / PLANO DE CONTINGÊNCIA): O "SAVE BRIDGE" NO STUDIO++

Se a ROM unificada encontrar limitações de tamanho ou bugs intransponíveis na fusão de mapas, o **Caminho 1** garante a mesma experiência exata através do nosso Launcher.

### 3.1 Como Funciona o Save Bridge
1. **Fase Kanto:** O jogador joga o FireRed normalmente no mGBA.
2. **Detector de Hall da Fama:** O `GbaSave.lua` monitora o arquivo `.sav`. No Setor 0/1 do Flash de 128KB, a flag `FLAG_SYS_GAME_CLEAR` (0x82C) e os dados de Hall da Fama indicam quando o jogador zerou Kanto.
3. **Extração de Dados da Equipe (Party Struct):**
   - O launcher lê os 6 Pokémon da Party (100 bytes por Pokémon):
     - Dados de Espécie, Nível, Natureza.
     - Individual Values (IVs: 0-31 em HP, Atk, Def, Speed, SpAtk, SpDef).
     - Effort Values (EVs: 0-255).
     - Golpes aprendidos e PP Up aplicados.
     - Treinador Original (OT Name, OT ID, Secret ID).
     - Shininess (PID ^ OTID ^ SID).
4. **Injeção no Jogo de Johto (New Game+ Johto):**
   - O launcher cria um novo save para o jogo de Johto (ROM baseada em Johto como *Fire Gold / Liquid Crystal* ou *SoulSilver*).
   - O Treinador inicia em New Bark Town já com seu nome, ID e seus 6 Pokémon no PC ou na mochila, escalando os líderes para o modo New Game+.
5. **Interface no Launcher:**
   - Um botão dourado com badge: `🏆 HALL DA FAMA DETECTADO ➔ EMBARCAR PARA JOHTO`.

---

## 4. ROTEIRO DE EXECUÇÃO TÉCNICA

* **Passo 1:** Configuração do ambiente e da base 32MB de FireRed com suporte a expansão de bancos de mapas.
* **Passo 2:** Importação dos tilesets e mapas de Johto (New Bark Town a Mt. Silver).
* **Passo 3:** Criação do script de evento da transição em Kanto (porto de Vermilion / Trem de Saffron).
* **Passo 4:** Configuração da tabela de treinadores de Johto com os níveis ajustados (58 a 87).
* **Passo 5:** Testes contínuos de estabilidade e colisão no **mGBA** integrado via Studio++.
