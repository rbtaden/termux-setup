# Termux: Setup Automatizado & Tools & RSS & Chess Analítico (♔ ♕ ♖ ♗ ♘ ♙)

Script de instalação e personalização completa para o **Termux** no Android. Configura automaticamente o ambiente visual, gerenciador de janelas em painéis, visualizadores de imagem no terminal, leitor de feeds RSS com descanso de tela estilo monitor de fósforo âmbar, motores de xadrez interativos com biblioteca de Grandes Mestres, análise PGN e configuração interativa de acesso remoto e transferência de arquivos via **Tailscale SSH**, utilizando dependências próprias armazenadas na pasta `assets/` deste repositório.

---

## Instalação Rápida (Novo Aparelho)

Abra o **Termux** recém-instalado no Android (<https://github.com/termux/termux-app/releases>) e execute o comando único abaixo:

```bash
apt update && apt full-upgrade -y && pkg install curl -y && curl -fsSL https://raw.githubusercontent.com/rbtaden/termux-setup/main/instalar-termux-completo.sh -o setup.sh && chmod +x setup.sh && ./setup.sh
```

### Instalação Apenas do Módulo Tailscale SSH (Standalone)
Caso já possua o Termux configurado e queira apenas instalar ou reconfigurar o acesso remoto e os atalhos de transferência (`config-ssh`, `remoto`, `sftp-pc`, `puxar`, `enviar`, `sincronizar` e `backuppc`):

```bash
curl -fsSL https://raw.githubusercontent.com/rbtaden/termux-setup/main/configurar-ssh.sh -o configurar-ssh.sh && chmod +x configurar-ssh.sh && ./configurar-ssh.sh
```

### Durante a instalação completa
* Caso o sistema solicite **permissão de armazenamento** (`termux-setup-storage`), toque em **Permitir**. Demais solicitações: apenas pressione **ENTER** (padrão).
* Ao final, o script perguntará se você deseja configurar o **Acesso Remoto Tailscale SSH** (`config-ssh`) naquele momento. Caso prefira fazer depois, basta pressionar **Enter** e rodar o comando `config-ssh` quando quiser.
* Quando aparecer `"Instalacao concluida!"`, feche o aplicativo completamente tocando em **Exit** na barra de notificações do Android e abra o Termux novamente.

---

## O que este script instala e configura

* **Visual e Tipografia:** Tema de cores **Dracula** (`colors.properties`) e fonte **JetBrainsMono Nerd Font** (`font.ttf`) com suporte a ícones, carregados diretamente da pasta `assets/`.
* **Informações do Sistema:** **Fastfetch** configurado para iniciar automaticamente ao abrir o terminal (`~/.bashrc`) e mensagem padrão ocultada (`~/.hushlogin`).
* **Gerenciador de Arquivos:** **Yazi** para navegação visual com ícones e pré-visualização.
* **Visualizadores de Imagem no Terminal:** **Pixterm** (extraído de `assets/pixterm.tar` e compilado automaticamente via Go), **Viu** e **Chafa**.
* **Multiplexador de Terminal:** **Tmux** pré-configurado (`~/.tmux.conf`) com abertura automática ao iniciar o Termux, suporte a toque na tela (`mouse on`), prefixo alterado para `Ctrl + a` e bloqueio automático por inatividade.
* **Leitor RSS e Descanso de Tela Retrô:**
  * **Newsboat (`noticias`):** Leitor leve de feeds RSS no terminal pré-configurado com o feed de notícias em `~/.newsboat/urls`.
  * **Descanso de Tela Phosphor Âmbar (`descanso`):** Script em Python (`~/phosphor_rss.py`) utilizando `feedparser` e códigos ANSI de 256 cores que exibe manchetes e resumos em tom âmbar retrô. Configurado no `~/.tmux.conf` para iniciar automaticamente após **60 segundos** de inatividade (basta pressionar qualquer tecla para voltar ao terminal).
* **Xadrez, Biblioteca de Grandes Mestres e Análise PGN:**
  * **GNU Chess (`xadrez`):** Configurado com livro de aberturas compilado localmente a partir do acervo `Kasparov.pgn` (extraído de `assets/Kasparov.zip`), filtro de limpeza de avisos internos (`Bad address`) e suporte ao comando `go` para iniciar com as peças pretas.
  * **Stockfish Interativo (`sf`):** Interface em Python (`~/jogar_stockfish.py`) registrada como executável nativo em `$PREFIX/bin/sf`, com tabuleiro visual limpo, escolha de nível Elo (1320 a 3190), escolha de cor, dicas (`hint`), desfazer jogadas (`undo`) e exportação automática de partidas em `.pgn` direto para a pasta `Downloads`.
  * **Analisador Interativo de Partidas (`analisar`):** Script em Python (`~/analisar_pgn.py`) registrado em `$PREFIX/bin/analisar` que oferece um **menu interativo** para listar arquivos `.pgn` de `~/estudos_pgn/` e `Downloads`, selecionar qualquer partida dentro das coleções de Grandes Mestres (primeiras 30 partidas por arquivo), avaliar lance a lance com o Stockfish e gerar um **relatório final** com contagem de imprecisões (`?!`), erros (`?`) e erros graves (*blunders* `??`).
  * **Biblioteca de Estudos (`~/estudos_pgn/`):** Inclui partidas clássicas individuais (`opera.pgn` de Paul Morphy, `pastor.pgn` e `capablanca.pgn`) e as **6 coleções completas** extraídas da pasta `assets/`: `Alekhine.pgn`, `Capablanca.pgn`, `Carlsen.pgn`, `Fischer.pgn`, `Kasparov.pgn` e `Tal.pgn`.
* **Módulo Tailscale SSH (`config-ssh`):** Script utilitário instalado em `$PREFIX/bin/config-ssh` para configurar ou adicionar múltiplos hosts Tailscale SSH no `~/.ssh/config`, gerar chaves Ed25519 sem senha e criar atalhos de transferência e backup.
* **Ferramentas de Rede, Sincronização e Sistema:** `openssh`, `rsync`, `nmap`, `traceroute`, `whois`, `netcat-openbsd`, `htop`, `tree`, `jq`, `tur-repo` e `aircrack-ng` 1.7 (instalado automaticamente conforme a arquitetura do aparelho).

---

## Configuração do Tailscale SSH no Servidor (PC Host)

O **Tailscale SSH** permite acessar servidores e dispositivos remotamente de forma segura sem precisar gerenciar chaves SSH manuais ou abrir portas no roteador, autenticando diretamente pela sua conta Tailscale.

### 1. Pré-requisitos
* **Conta ativa:** Uma conta no [Tailscale](https://tailscale.com/) configurada em ambos os dispositivos (Android e PC).
* **Versão atualizada:** Cliente Tailscale na versão **1.26 ou superior**.
* **Sistema operacional:** O servidor de destino (host) precisa rodar **Linux** ou **macOS**.

### 2. Ativando o Tailscale SSH no PC (Host)
No computador ou servidor que deseja acessar remotamente, execute no terminal:
```bash
sudo tailscale up --ssh
```
*(Alternativa: caso o Tailscale já esteja rodando, use `sudo tailscale set --ssh` para ativar sem refazer o login).*

### 3. Regras de Acesso (ACLs)
No painel **Admin Console** do Tailscale (`Access Controls`), confirme se o bloco `ssh` está habilitado:
```json
"ssh": [
  {
    "action": "check",
    "src":    ["autogroup:member"],
    "dst":    ["autogroup:self"],
    "users":  ["autogroup:nonroot", "root"],
  },
],
```
* **Modo `check`:** Solicita validação periódica no navegador (mais seguro).
* **Modo `accept`:** Permite conexão direta sem reautenticação constante.

---

## Atalhos e Comandos Disponíveis

### Visualização, Sistema, RSS e Jogos

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
| `noticias` | Abre o leitor de feeds RSS **Newsboat**. |
| `descanso` | Inicia manualmente o descanso de tela **Phosphor Âmbar** com notícias RSS (também ativa sozinho após 60s de ociosidade). |
| `downloads` | Acessa `/sdcard/Download` e lista os arquivos. |
| `fotos` | Acessa `/sdcard/Pictures` e lista os arquivos. |
| `foto <imagem>` | Exibe a imagem no terminal usando o **Viu**. |
| `img <imagem>` | Exibe a imagem no terminal usando o **Chafa**. |
| `pixterm -s 2 <imagem>` | Exibe a imagem em blocos coloridos de alta definição usando o **Pixterm**. |
| `xadrez` | Inicia **GNU Chess** com livro de aberturas (digite `go` no início para jogar de pretas). |
| `sf` | Inicia **Stockfish** interativo com tabuleiro limpo, escolha de Elo/cor, `hint`, `undo` e exportação de `.pgn` para `Downloads`. |
| `analisar [arquivo.pgn]` | Abre o menu interativo de arquivos e partidas `.pgn` com avaliação lance a lance e relatório de *blunders*. |
| `stockfish` | Abre o motor UCI **Stockfish** puro. |
| `atualizar` | Atualiza todos os pacotes do Termux (`pkg update && pkg upgrade -y`). |

### Acesso Remoto e Transferência de Arquivos (Tailscale SSH)

| Comando | Função |
| :--- | :--- |
| `config-ssh` | Abre o assistente interativo para configurar o PC principal ou adicionar novos servidores Tailscale SSH. |
| `remoto` | Conecta-se ao terminal do PC principal via SSH usando o apelido salvo em `~/.ssh/config`. |
| `sftp-pc` | Abre sessão interativa **SFTP** com o PC (`ls`, `cd`, `get`, `mget *.jpg`, `put`, `exit`). |
| `puxar <remoto> [local]` | Copia arquivos ou pastas do PC para `/sdcard/Download/` no Android via `scp -r`. |
| `enviar <local> [remoto]` | Copia arquivos ou pastas do Android para `~/Downloads/` no PC via `scp -r`. |
| `sincronizar <orig> [dest]` | Sincroniza pastas de forma incremental via `rsync -avz --progress`. |
| `backuppc` | Executa `~/backup_pc.sh`: empacota `/sdcard/Download` e extrai em `~/Downloads/ANDROID_Backup` no PC via fluxo `tar + ssh`. |

---

## Procedimentos Operacionais Padrão (POP) de Transferência

Todos os comandos abaixo são executados no **terminal local do Termux** (substitua `pc-remoto` pelo apelido configurado no `~/.ssh/config` ou por `usuario@ip`):

### Método A: Transferência Direta com `scp`
* **Baixar arquivo do PC para o Android:**
  ```bash
  scp pc-remoto:~/Downloads/arquivo.extensao /sdcard/Download/
  ```
* **Enviar arquivo com espaços no nome (uso obrigatório de aspas):**
  ```bash
  scp "/sdcard/Download/outro arquivo.extensao" pc-remoto:~/Downloads/
  ```
* **Transferir pastas inteiras recursivamente (`-r`):**
  ```bash
  scp -r /sdcard/Download/pasta_origem pc-remoto:~/Downloads/
  ```

### Método B: Transferência Interativa com `sftp`
1. Inicie com `sftp-pc` (ou `sftp pc-remoto`).
2. Comandos internos: `lpwd` / `lcd /sdcard/Download` (local), `pwd` / `cd Downloads` (remoto), `ls` (lista remoto), `lls` (lista local), `mget *.jpeg` (baixa múltiplos), `put arquivo.pdf` (envia) e `exit`.

### Método C: Fluxo Compactado em Tempo Real (`tar` + `ssh`)
Ideal para transferir grandes volumes de arquivos sem ocupar espaço temporário em disco:
* **Enviar pasta do Android e extrair automaticamente no PC:**
  ```bash
  tar -czf - -C /sdcard/Download minha_pasta | ssh pc-remoto "tar -xzf - -C ~/Downloads/"
  ```
* **Salvar como arquivo `.tar.gz` datado no PC (sem extrair):**
  ```bash
  tar -czf - -C /sdcard/Download minha_pasta | ssh pc-remoto "cat > ~/Downloads/ANDROID_Backup_$(date +%Y%m%d).tar.gz"
  ```

### Método D: Sincronização Inteligente com `rsync`
Transfere apenas arquivos novos ou modificados e permite retomar transferências interrompidas:
```bash
rsync -avz --progress /sdcard/Download/ pc-remoto:~/Downloads/ANDROID_Backup/
```

---

## Troubleshooting (Solução de Problemas)

1. **Status da VPN (Tailscale):** Confirme se o túnel VPN está ativo no Android (`tun0`/`tun1` visível no `fastfetch`) e no host PC (`tailscale status`).
2. **Permissões de Armazenamento:** Se ocorrer erro `Permission denied` ao acessar `/sdcard/Download/`, execute `termux-setup-storage`.
3. **Serviço SSH no Servidor:** No PC Linux, verifique se o daemon SSH está ativo com `sudo systemctl status ssh`.
4. **Espaço em Disco:** Verifique o armazenamento disponível no destino com `df -h`.

---

## Atalhos de Teclado no Tmux

O prefixo padrão do Tmux foi alterado de `Ctrl + b` para **`Ctrl + a`**, além de permitir clicar diretamente nos painéis com o dedo:

* **`Ctrl + a` seguido de `|`** — Divide o painel atual verticalmente (lado a lado).
* **`Ctrl + a` seguido de `-`** — Divide o painel atual horizontalmente (em cima e embaixo).
* **`Ctrl + a` seguido de `r`** — Recarrega as configurações do `~/.tmux.conf`.
* **`exit`** — Fecha o painel atual.
