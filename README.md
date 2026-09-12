# 🎮 Pokémon GBA Recomp++ (Launcher & Mod Manager Gen 3)

Interface moderna, launcher e gerenciador de mods e saves para **Game Boy Advance (GBA)**, inspirada na arquitetura do *gen1recomp*. Desenvolvida em **Lua + LÖVE 11.5**, com emulador portátil integrado (**mGBA 0.10.5**), renderização 3D de cartuchos e suporte nativo a múltiplos save slots e patches da comunidade.

---

## ✨ Recursos

- 🕹️ **Emulador Embutido Portátil:** Inclui o **mGBA v0.10.5** em modo portátil (`emulator/mGBA.exe`). Ao clicar em **JOGAR**, o jogo abre imediatamente sem diálogos do Windows.
- 👾 **Cartucho GBA 3D Interativo:** Simulação tridimensional realista em perspectiva do cartucho clássico de GBA com rotação dinâmica interativa via mouse.
- 💾 **Gerenciador de Múltiplos Save Slots:** Crie, renomeie, faça backup e alterne entre diferentes slots de salvamento independentes para cada jogo sem sobrescrever seu progresso principal.
- 🧩 **Aba de Gerenciamento de Mods:**
  - Interface dedicada para ativar e desativar mods, traduções e patches com um clique.
  - Filtro por jogo (FireRed, LeafGreen, Emerald, etc.).
  - Integração com o ecossistema e repositório da comunidade.
- 🔍 **Detecção Automática de ROMs:** Varre a pasta raiz e analisa os headers de 32-bit ARM para identificar códigos oficiais (`BPRE`, `BPGE`, `BPEE`, `AXVE`, `AXPE`).

---

## 📦 Jogos Suportados

| Jogo | Código Oficial | Nome do Arquivo Recomendado |
| :--- | :--- | :--- |
| **Pokémon FireRed** | `BPRE` | `FireRed.gba` |
| **Pokémon LeafGreen** | `BPGE` | `LeafGreen.gba` |
| **Pokémon Emerald** | `BPEE` | `Emerald.gba` |
| **Pokémon Ruby** | `AXVE` | `Ruby.gba` |
| **Pokémon Sapphire** | `AXPE` | `Sapphire.gba` |

> Coloque o arquivo `.gba` do seu jogo diretamente na pasta raiz do projeto.

---

## 🧩 Mods Inclusos

Na aba **🧩 MODS**, você pode ligar e desligar os seguintes mods pré-configurados:

1. 🇧🇷 **Tradução PT-BR FireRed:** Textos e diálogos adaptados para o Português do Brasil.
2. ⚡ **Exp. Share Moderno:** Distribuição de experiência estilo Gen 6+ para toda a equipe.
3. 🏃 **Correr em Ambientes Fechados:** Permite correr livremente dentro de casas, centros pokémon e edifícios.
4. ⏩ **Texto Instantâneo:** Elimina o delay na renderização das caixas de diálogo.
5. 💿 **TMs Reutilizáveis:** Technical Machines não quebram após o uso (estilo Gen 5+).

Para adicionar novos mods ou patches (`.ips`, `.bps`), basta colocá-los na pasta `mods/`.

---

## 🚀 Como Executar

### Pré-requisito
- Ter o **LÖVE 11.5** instalado ([love2d.org](https://love2d.org)).

### Execução Direta
Abra o terminal na pasta do projeto e execute:
```powershell
love .
```

Ou, se estiver na pasta pai dos seus projetos:
```powershell
love Pokemon-GBA
```

---

## 📂 Estrutura de Pastas

```
Pokemon-GBA/
├── conf.lua             # Configurações de janela (High-DPI, 980x660)
├── main.lua             # Entrada principal do LÖVE
├── src/
│   ├── core/
│   │   ├── GbaRom.lua   # Parser de headers ARM e varredura de ROMs
│   │   ├── GbaSave.lua  # Gerenciador de saves 128KB Flash e slots
│   │   └── GbaMods.lua  # Descoberta e alternância de mods
│   └── ui/
│       ├── Theme.lua    # Paleta Indigo escura e utilitários visuais
│       ├── Kit.lua      # Botões interativos, badges e inputs
│       ├── GbaCartView.lua # Cartucho 3D renderizado em tempo real
│       └── LauncherView.lua # Painel principal e tela de mods
├── emulator/            # mGBA 0.10.5 portátil pré-configurado
├── mods/                # Pacotes de mods e mods_config.json
├── saves/               # Backups e slots independentes de salvamento
└── README.md
```

---

## 📜 Licença

Desenvolvido para preservação e estudo de engenharia reversa de ROMs e UI interativa de emuladores. Pokémon é marca registrada da Nintendo, Game Freak e Creatures Inc.
