# Termux Setup Automatizado com Tools e estudo Xadrez (PGN)

Script de instalação e personalização completa para o **Termux** no Android. Configura automaticamente o ambiente visual, gerenciador de janelas em painéis, visualizadores de imagem no terminal, motores de xadrez interativos com análise PGN e atalhos para acesso remoto via Tailscale SSH, utilizando dependências próprias armazenadas na pasta `assets/` deste repositório.

---

## Instalação Rápida (Novo Aparelho)

Abra o **Termux** recém-instalado no Android e execute o comando único abaixo:

```bash
apt update && apt full-upgrade -y && pkg install curl -y && curl -fsSL https://raw.githubusercontent.com/rbtaden/termux-setup/main/instalar-termux-completo.sh -o setup.sh && chmod +x setup.sh && ./setup.sh
```

### Durante a instalação
* O sistema solicitará **permissão de armazenamento** (`termux-setup-storage`). Toque em **Permitir**.
* Ao final, o script perguntará opcionalmente o **usuário** e o **IP Tailscale** do seu PC para configurar os atalhos de acesso remoto. Caso não queira configurar agora, basta pressionar **Enter** em branco para pular.
* Quando aparecer `"Instalacao concluida!"`, feche o aplicativo completamente tocando em **Exit** na barra de notificações do Android e abra-o novamente.

---

## O que este script instala e configura

* **Visual e Tipografia:** Tema de cores **Dracula** (`colors.properties`) e fonte **JetBrainsMono Nerd Font** (`font.ttf`) com suporte a ícones, carregados diretamente da pasta `assets/`.
* **Informações do Sistema:** **Fastfetch** configurado para iniciar automaticamente ao abrir o terminal (`~/.bashrc`) e mensagem padrão ocultada (`~/.hushlogin`).
* **Gerenciador de Arquivos:** **Yazi** para navegação visual com ícones e pré-visualização.
* **Visualizadores de Imagem no Terminal:** **Pixterm** (extraído de `assets/pixterm.tar` e compilado automaticamente via Go), **Viu** e **Chafa**.
* **Multiplexador de Terminal:** **Tmux** pré-configurado (`~/.tmux.conf`) com suporte a toque na tela (`mouse on`) e prefixo alterado para `Ctrl + a`.
* **Xadrez, Estudo e Análise PGN:**
  * **GNU Chess (`xadrez`):** Configurado com livro de aberturas real (partidas de Garry Kasparov extraídas do PGN Mentor), filtro de limpeza de avisos internos (`Bad address`) e suporte ao comando `go` para iniciar com as peças pretas.
  * **Stockfish Interativo (`sf`):** Interface em Python (`~/jogar_stockfish.py`) com tabuleiro visual limpo, escolha de nível Elo (1320 a 3190), escolha de cor, dicas (`hint`), desfazer jogadas (`undo`) e exportação automática de partidas em `.pgn` direto para a pasta `Downloads`.
  * **Analisador de Partidas (`analisar`):** Script em Python (`~/analisar_pgn.py`) que lê qualquer arquivo `.pgn`, desenha o tabuleiro lance a lance, classifica automaticamente imprecisões (`?!`), erros (`?`) e erros graves/*blunders* (`??`), exibe a avaliação numérica do Stockfish com o melhor lance sugerido e gera um relatório estatístico completo ao final.
  * **Biblioteca de Estudos (`~/estudos_pgn/`):** Partidas clássicas pré-instaladas (`opera.pgn` de Paul Morphy, `pastor.pgn` e `capablanca.pgn`) prontas para treino e análise imediata.
* **Ferramentas de Rede e Sistema:** Pacotes essenciais como `nmap`, `traceroute`, `whois`, `netcat-openbsd`, `htop`, `tree`, `jq` e `tur-repo`.

---

## Atalhos e Comandos Disponíveis

### Visualização, Sistema e Jogos

| Comando | Função |
| :--- | :--- |
| `termux-setup-storage` | Libera acesso a `/sdcard`. |
| `who` | Exibe usuário e sessão atual. |
| `c` | Limpa a tela do terminal (`clear`). |
| `exit` | Fecha o painel atual. |
| `layout` | Abre o **Tmux** dividido em 3 painéis (**Yazi** no topo, **Fastfetch** embaixo à esquerda e terminal limpo embaixo à direita). |
| `painel` | Inicia o **Tmux** dividido rapidamente em 2 painéis lado a lado. |
| `info` | Executa o **Fastfetch** manualmente. |
| `arquivos` | Abre o gerenciador de arquivos visual **Yazi**. |
| `downloads` | Acessa `/sdcard/Download` e lista os arquivos. |
| `fotos` | Acessa `/sdcard/Pictures` e lista os arquivos. |
| `foto <imagem>` | Exibe a imagem no terminal usando o **Viu**. |
| `img <imagem>` | Exibe a imagem no terminal usando o **Chafa**. |
| `pixterm -s 2 <imagem>` | Exibe a imagem em blocos coloridos de alta definição usando o **Pixterm**. |
| `xadrez` | Inicia **GNU Chess** com livro de aberturas (digite `go` no início para jogar de pretas). |
| `sf` | Inicia **Stockfish** interativo com tabuleiro limpo, escolha de Elo/cor, `hint`, `undo` e exportação de `.pgn` para `Downloads`. |
| `analisar <arquivo.pgn>` | Analisa uma partida `.pgn` lance a lance com classificação de erros/blunders e relatório final do Stockfish (ex: `analisar ~/estudos_pgn/opera.pgn`). |
| `stockfish` | Abre o motor UCI **Stockfish** puro. |
| `atualizar` | Atualiza todos os pacotes do Termux (`pkg update && pkg upgrade -y`). |

### Acesso Remoto (Tailscale SSH)
(Disponível caso o usuário e IP do PC tenham sido informados durante a instalação)

| Comando | Função |
| :--- | :--- |
| `mint` | Conecta-se remotamente ao terminal do PC via SSH (`ssh usuario@ip`). |
| `puxar <caminho>` | Copia arquivos ou pastas da pasta pessoal do PC para o diretório atual no Android via SCP. |

---

## Atalhos de Teclado no Tmux

O prefixo padrão do Tmux foi alterado de `Ctrl + b` para **`Ctrl + a`**, além de permitir clicar diretamente nos painéis com o dedo:

* **`Ctrl + a` seguido de `|`** — Divide o painel atual verticalmente (lado a lado).
* **`Ctrl + a` seguido de `-`** — Divide o painel atual horizontalmente (em cima e embaixo).
* **`Ctrl + a` seguido de `r`** — Recarrega as configurações do `~/.tmux.conf`.
* **`exit`** — Fecha o painel atual.
