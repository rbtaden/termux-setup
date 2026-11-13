#!/data/data/com.termux/files/usr/bin/bash

echo "=================================================="
echo "   Instalacao Customizada Automatizada - Termux   "
echo "=================================================="

# URL base dos arquivos salvos no seu repositorio (pasta assets)
REPO_ASSETS="https://raw.githubusercontent.com/rbtaden/termux-setup/main/assets"

# 1. Solicitar permissao de armazenamento
if [ ! -d ~/storage ]; then
    echo "[1/11] Solicitando permissao de armazenamento..."
    termux-setup-storage
    sleep 3
fi

# 2. Atualizar repositorios e pacotes sem travar em perguntas
echo "[2/11] Atualizando sistema e repositorios..."
yes | pkg update -y
yes | pkg upgrade -y -o Dpkg::Options::="--force-confold"

# 3. Instalar pacotes essenciais
echo "[3/11] Instalando fastfetch, tmux, viu, chafa, yazi, openssh e golang..."
pkg install fastfetch tmux viu chafa yazi openssh curl git golang -y

# 4. Habilitar repositorio da comunidade (tur-repo)
echo "[4/11] Habilitando repositorio extra (tur-repo)..."
pkg install -y tur-repo

# 5. Instalar ferramentas de Rede e Diagnostico
echo "[5/11] Instalando ferramentas de rede..."
pkg install -y net-tools iproute2 dnsutils inetutils traceroute nmap curl wget whois openssh netcat-openbsd

# 6. Instalar utilitarios Bash, Arquivos e Monitoramento
echo "[6/11] Instalando utilitarios Bash e sistema..."
pkg install -y coreutils findutils grep sed gawk jq tree zip unzip tar htop tmux git nano vim file which util-linux procps termux-tools

# 7. Criar executavel para o comando 'who' (omitido no coreutils do Android)
echo "[7/11] Configurando comando 'who'..."
printf '#!/data/data/com.termux/files/usr/bin/sh\necho "$(whoami) pts/0 $(date "+%%Y-%%m-%%d %%H:%%M")"\n' > $PREFIX/bin/who
chmod +x $PREFIX/bin/who

# 8. Instalar GNU Chess, Stockfish, Python-Chess e configurar atalhos e estudos PGN
echo "[8/11] Instalando GNU Chess, Stockfish e configurando comandos 'xadrez', 'sf' e 'analisar'..."
pkg install -y gnuchess stockfish python
pip install --quiet chess

mkdir -p "$HOME/.gnuchess"
curl -fsSL "https://www.pgnmentor.com/players/Kasparov.zip" -o "$HOME/.gnuchess/gm.zip"
unzip -p "$HOME/.gnuchess/gm.zip" > "$HOME/.gnuchess/gm.pgn"
rm -f "$HOME/.gnuchess/gm.zip"

printf '#!/data/data/com.termux/files/usr/bin/sh\ncd "$HOME/.gnuchess"\nif [ ! -f book.dat ] && [ -s gm.pgn ]; then\n  printf "book add gm.pgn\\nquit\\n" | gnuchess >/dev/null 2>&1\nfi\necho "=== GNU Chess Pronto ==="\necho "Comandos: e4 (jogar) | go (jogar de pretas) | show board (tabuleiro) | hint (dica) | quit (sair)"\nexec gnuchess 2>&1 | grep --line-buffered -v "Bad address"\n' > $PREFIX/bin/xadrez
chmod +x $PREFIX/bin/xadrez

cat << 'EOF' > ~/jogar_stockfish.py
import os
import datetime
import chess
import chess.engine
import chess.pgn

board = chess.Board()
engine = chess.engine.SimpleEngine.popen_uci("stockfish")

print("=== Stockfish Pronto ===")
elo = input("Nivel Elo (1320 a 3190, Enter para 1500): ").strip()
elo_val = int(elo) if elo.isdigit() else 1500
elo_val = max(1320, min(3190, elo_val))
engine.configure({"UCI_LimitStrength": True, "UCI_Elo": elo_val})

cor = input("Jogar de Brancas ou Pretas? (b/p, Enter para Brancas): ").strip().lower()
user_color = chess.BLACK if cor == "p" else chess.WHITE

print(f"\nNivel: {elo_val} Elo | Voce joga de {'Pretas' if user_color == chess.BLACK else 'Brancas'}.")
print("Comandos: e4 (jogar) | hint (dica) | undo (voltar) | quit (sair)\n")

while not board.is_game_over():
    if board.turn == user_color:
        print(board.unicode(invert_color=True, borders=True, orientation=user_color, empty_square=" "))
        move_str = input("\nSeu lance: ").strip()
        
        if move_str == "quit":
            break
        elif move_str == "hint":
            print("Calculando dica...")
            hint_res = engine.play(board, chess.engine.Limit(time=0.5))
            print(f"Dica: tente jogar {board.san(hint_res.move)}\n")
            continue
        elif move_str == "undo":
            if len(board.move_stack) >= 2:
                board.pop()
                board.pop()
                print("Ultima jogada desfeita.\n")
            else:
                print("Ainda nao ha lances suficientes para voltar.\n")
            continue
            
        try:
            board.push_san(move_str)
        except ValueError:
            print("Lance invalido. Tente novamente (ex: e4, Nf3, O-O).")
            continue
    else:
        print("Stockfish pensando...")
        result = engine.play(board, chess.engine.Limit(time=0.2))
        print(f"Stockfish jogou: {board.san(result.move)}\n")
        board.push(result.move)

engine.quit()

if board.is_game_over():
    print(board.unicode(invert_color=True, borders=True, orientation=user_color, empty_square=" "))
    print(f"Fim de jogo! Resultado: {board.result()}")
else:
    print("Partida encerrada.")

if len(board.move_stack) > 0:
    game = chess.pgn.Game.from_board(board)
    game.headers["Event"] = "Partida no Termux"
    game.headers["Date"] = datetime.datetime.now().strftime("%Y.%m.%d")
    game.headers["White"] = "Voce" if user_color == chess.WHITE else f"Stockfish ({elo_val})"
    game.headers["Black"] = f"Stockfish ({elo_val})" if user_color == chess.WHITE else "Voce"
    game.headers["Result"] = board.result() if board.is_game_over() else "*"
    
    downloads_dir = "/data/data/com.termux/files/home/storage/downloads"
    save_dir = downloads_dir if os.path.isdir(downloads_dir) else os.path.expanduser("~")
    filename = os.path.join(save_dir, f"partida_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}.pgn")
    
    with open(filename, "w") as f:
        print(game, file=f)
    print(f"Historico salvo em: {filename}")
EOF

# Criar pasta com partidas classicas em PGN para estudo
mkdir -p ~/estudos_pgn

cat << 'EOF' > ~/estudos_pgn/opera.pgn
[Event "Paris"]
[Site "Paris FRA"]
[Date "1858.??.??"]
[White "Paul Morphy"]
[Black "Duke Karl / Count Isouard"]
[Result "1-0"]

1. e4 e5 2. Nf3 d6 3. d4 Bg4 4. dxe5 Bxf3 5. Qxf3 dxe5 6. Bc4 Nf6 7. Qb3 Qe7 8. Nc3 c6 9. Bg5 b5 10. Nxb5 cxb5 11. Bxb5+ Nbd7 12. O-O-O Rd8 13. Rxd7 Rxd7 14. Rd1 Qe6 15. Bxd7+ Nxd7 16. Qb8+ Nxb8 17. Rd8# 1-0
EOF

cat << 'EOF' > ~/estudos_pgn/pastor.pgn
[Event "Estudo de Abertura"]
[Site "Online"]
[Date "2024.01.01"]
[White "Brancas"]
[Black "Pretas"]
[Result "1-0"]

1. e4 e5 2. Qh5 Nc6 3. Bc4 Nf6 4. Qxf7# 1-0
EOF

cat << 'EOF' > ~/estudos_pgn/capablanca.pgn
[Event "Simultanea"]
[Site "Nova York EUA"]
[Date "1910.??.??"]
[White "Jose Raul Capablanca"]
[Black "Amateur"]
[Result "1-0"]

1. e4 e5 2. Nf3 Nc6 3. Bc4 d6 4. Nc3 Bg4 5. Nxe5 Bxd1 6. Bxf7+ Ke7 7. Nd5# 1-0
EOF

# Criar script de analise lance a lance com Stockfish
cat << 'EOF' > ~/analisar_pgn.py
import sys
import os
import chess
import chess.pgn
import chess.engine

if len(sys.argv) < 2:
    print("Uso: analisar <arquivo.pgn>")
    print("Exemplos prontos em: ~/estudos_pgn/opera.pgn | pastor.pgn | capablanca.pgn")
    sys.exit(1)

arquivo_pgn = sys.argv[1]
if not os.path.isfile(arquivo_pgn):
    print(f"Arquivo nao encontrado: {arquivo_pgn}")
    sys.exit(1)

engine = chess.engine.SimpleEngine.popen_uci("stockfish")

with open(arquivo_pgn) as pgn:
    jogo = chess.pgn.read_game(pgn)

if not jogo:
    print("Nenhuma partida valida encontrada no arquivo.")
    engine.quit()
    sys.exit(1)

print("\n=== Analise Stockfish ===")
print(f"Partida: {jogo.headers.get('White', '?')} vs {jogo.headers.get('Black', '?')}")
print(f"Resultado: {jogo.headers.get('Result', '*')}\n")

tabuleiro = jogo.board()

for numero_lance, lance in enumerate(jogo.mainline_moves(), start=1):
    turno = (numero_lance + 1) // 2
    cor = "Brancas" if tabuleiro.turn == chess.WHITE else "Pretas"
    lance_san = tabuleiro.san(lance)
    
    info_antes = engine.analyse(tabuleiro, chess.engine.Limit(time=0.2))
    melhor_lance = tabuleiro.san(info_antes["pv"][0]) if "pv" in info_antes and len(info_antes["pv"]) > 0 else "-"
    
    tabuleiro.push(lance)
    
    info_depois = engine.analyse(tabuleiro, chess.engine.Limit(time=0.2))
    score = info_depois["score"].white()
    
    if score.is_mate():
        avaliacao = f"Mate em {score.mate()}"
    else:
        avaliacao = f"{score.score() / 100:+.2f}"

    print("=" * 35)
    print(f"Lance {turno} ({cor}): {lance_san}")
    print(f"Melhor lance seria: {melhor_lance} | Avaliacao: {avaliacao}")
    print(tabuleiro.unicode(invert_color=True, borders=True, empty_square=" "))
    
    resp = input("\n[Enter] Proximo lance | [q] Sair: ").strip().lower()
    if resp == "q":
        break

engine.quit()
print("\nAnalise encerrada.")
EOF

echo "==========================================================="
echo "  Instalacao em andamento, aguarde e anote alguns comandos!"
echo "==========================================================="
echo "Comandos customizados disponiveis:"
echo " - termux-setup-storage  -> Libera acesso a /sdcard"
echo " - who                   -> Exibe usuario e sessao atual"
echo " - c                     -> Limpa a tela do terminal (clear)"
echo " - exit                  -> Fecha o painel atual"
echo " - layout                -> Interface customizada: Yazi, Fastfetch e Terminal"
echo " - painel                -> Interface customizada: 2 paineis"
echo " - info                  -> Executa o Fastfetch manualmente"
echo " - arquivos              -> Abre o gerenciador de arquivos Yazi"
echo " - downloads             -> Acessa /sdcard/Download e lista os arquivos"
echo " - fotos                 -> Acessa /sdcard/Pictures e lista os arquivos"
echo " - foto                  -> Exibe a imagem no terminal usando o Viu"
echo " - img                   -> Exibe a imagem no terminal usando o Chafa"
echo " - pixterm -s 2          -> Exibe a imagem em blocos coloridos com o Pixterm"
echo " - xadrez                -> Inicia GNU Chess com livro de aberturas"
echo " - sf                    -> Inicia Stockfish interativo (Elo, dicas e PGN)"
echo " - analisar <arquivo>    -> Analisa partidas .pgn lance a lance com Stockfish"
echo " - stockfish             -> Abre o motor UCI Stockfish puro"
echo " - atualizar             -> Atualiza pacotes Termux (pkg update && pkg upgrade -y)"
echo " - mint                  -> Acesso HOST remoto - (ssh usuario@ip)"
echo " - puxar                 -> Copia arquivos ou pastas do PC para o Android via scp"
echo " Ctrl + a seguido de |   -> Divide o painel verticalmente (lado a lado)"
echo " Ctrl + a seguido de -   -> Divide o painel horizontalmente (em cima e embaixo)"
echo " Ctrl + a seguido de r   -> Recarrega as configuracoes do ~/.tmux.conf"

# 9. Baixar e compilar o Pixterm a partir da pasta assets do seu repositorio
echo "[9/11] Compilando o Pixterm..."
rm -rf ~/pixterm ~/pixterm.tar
curl -fsSL "${REPO_ASSETS}/pixterm.tar" -o ~/pixterm.tar
tar -xf ~/pixterm.tar -C ~
rm -f ~/pixterm.tar
cd ~/pixterm || exit
go install ./cmd/pixterm
cp ~/go/bin/pixterm "$PREFIX/bin/"
cd ~ || exit
rm -rf ~/pixterm

# 10. Configurar tema Dracula e JetBrainsMono Nerd Font a partir da pasta assets
echo "[10/11] Aplicando tema Dracula e JetBrainsMono Nerd Font..."
mkdir -p ~/.termux
curl -fsSL "${REPO_ASSETS}/colors.properties" -o ~/.termux/colors.properties
curl -fsSL "${REPO_ASSETS}/JetBrainsMonoNerdFontMono-Regular.ttf" -o ~/.termux/font.ttf

# 11. Configurar Tmux, aliases e funcao layout
echo "[11/11] Configurando Tmux, atalhos e layout..."
touch ~/.hushlogin

cat << 'EOF' > ~/.tmux.conf
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix
set -g mouse on
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'
unbind %
bind r source-file ~/.tmux.conf \; display-message "Configuracao recarregada!"
set -g default-terminal "screen-256color"
set -g status-style "bg=#282a36,fg=#f8f8f2"
set -g status-left "#[fg=#50fa7b,bold] [Termux] "
set -g status-right "#[fg=#bd93f9]%H:%M "
EOF

cat << 'EOF' > ~/.bashrc
# Iniciar Fastfetch ao abrir
fastfetch

# --- Atalhos Personalizados Termux ---
alias c='clear'
alias atualizar='pkg update && pkg upgrade -y'
alias info='fastfetch'
alias arquivos='yazi'
alias foto='viu'
alias img='chafa'
alias downloads='cd /sdcard/Download && ls -la'
alias fotos='cd /sdcard/Pictures && ls -la'
alias painel='tmux new-session \; split-window -h \; attach'
alias sf='python ~/jogar_stockfish.py'
alias analisar='python ~/analisar_pgn.py'

# Layout completo (Yazi no topo, Fastfetch embaixo-esquerda, Terminal limpo embaixo-direita)
layout() {
  tmux new-session -d -s vitrine 'yazi'
  tmux split-window -v -t vitrine 'fastfetch --logo small; bash'
  tmux split-window -h -t vitrine.1 'cd /sdcard/Download && clear && bash'
  tmux select-pane -t vitrine.2
  tmux attach-session -t vitrine
}
EOF

# --- Configuracao Interativa de Acesso Remoto (Tailscale SSH) ---
echo ""
echo "--------------------------------------------------"
echo " Configuracao Opcional: Acesso Remoto SSH (PC)"
echo " (Pressione Enter em branco para pular esta etapa)"
echo "--------------------------------------------------"
read -rp "Digite o usuario do PC (ex: joao): " SSH_USER
read -rp "Digite o IP Tailscale do PC (ex: 100.x.x.x): " SSH_IP

if [ -n "$SSH_USER" ] && [ -n "$SSH_IP" ]; then
  cat << EOF >> ~/.bashrc

# Acesso rapido ao PC via Tailscale SSH
alias mint='ssh ${SSH_USER}@${SSH_IP}'
alias puxar='scp -r ${SSH_USER}@${SSH_IP}:~/'
EOF
  echo "Atalhos 'mint' e 'puxar' configurados para ${SSH_USER}@${SSH_IP}!"
else
  echo "Configuracao SSH ignorada."
fi

termux-reload-settings
source ~/.bashrc

echo "=================================================="
echo " Instalacao concluida! Reinicie o Termux (exit).  "
echo "=================================================="
