#!/data/data/com.termux/files/usr/bin/bash

echo "=================================================="
echo "   Instalacao Customizada Automatizada - Termux   "
echo "=================================================="

# URL base dos arquivos salvos no seu repositorio (pasta assets)
REPO_ASSETS="https://raw.githubusercontent.com/rbtaden/termux-setup/main/assets"

# 1. Solicitar permissao de armazenamento
if [ ! -d ~/storage/shared ]; then
    echo "[1/11] Solicitando permissao de armazenamento..."
    termux-setup-storage
    sleep 3
fi

# 2. Atualizar repositorios e pacotes sem travar em perguntas
echo "[2/11] Atualizando sistema e repositorios..."
yes | pkg update -y
yes | pkg upgrade -y -o Dpkg::Options::="--force-confold"

# 3. Habilitar repositorios da comunidade (tur-repo & root-repo)
echo "[3/11] Habilitando repositorios extras (tur-repo & root-repo)..."
yes | pkg install -y tur-repo root-repo
yes | pkg update -y

# 4. Instalar pacotes essenciais, Rede, Diagnostico e Utilitarios Bash
echo "[4/11] Instalando pacotes essenciais, rede e utilitarios Bash..."

PACOTES=(
    # Essenciais e Leitor RSS
    fastfetch tmux viu chafa yazi openssh curl git golang newsboat
    # Utilitarios Bash, Arquivos e Monitoramento
    coreutils findutils grep sed gawk jq tree zip unzip
    tar htop nano vim file which util-linux procps
    termux-tools termux-api p7zip nnn eza cmatrix tsu
    # Dependencias reais no Termux (para Aircrack-ng e rede)
    clang make autoconf automake pkg-config wget openssl pcre zlib
    ethtool wpa-supplicant tcpdump screen iw usbutils expect
    libc++ libnl libpcap libsqlite libtool
    # Rede e Diagnostico
    net-tools iproute2 dnsutils inetutils traceroute nmap
    whois netcat-openbsd tor speedtest-go tshark iperf3
)

for pacote in "${PACOTES[@]}"; do
    echo "--> Instalando: $pacote"
    pkg install -y "$pacote" || echo "AVISO: Falha ao instalar $pacote"
done

# 5. Instalacao automatizada do Aircrack-ng 1.7 (direto da pasta assets do repositorio)
echo "[5/11] Detectando arquitetura e instalando Aircrack-ng 1.7..."
ARCH=$(uname -m)

case "$ARCH" in
    aarch64)
        DEB_FILE="aircrack-ng_3_1.7_aarch64.deb"
        ;;
    armv7l|armv8l|arm)
        DEB_FILE="aircrack-ng_3_1.7_arm.deb"
        ;;
    x86_64)
        DEB_FILE="aircrack-ng_3_1.7_x86_64.deb"
        ;;
    i686)
        DEB_FILE="aircrack-ng_3_1.7_i686.deb"
        ;;
    *)
        echo "AVISO: Arquitetura $ARCH nao suportada para o aircrack-ng."
        DEB_FILE=""
        ;;
esac

if [ -n "$DEB_FILE" ]; then
    echo "--> Arquitetura detectada: $ARCH ($DEB_FILE)"
    curl -fsSL "${REPO_ASSETS}/${DEB_FILE}" -o "$TMPDIR/aircrack-ng.deb" && \
    dpkg -i "$TMPDIR/aircrack-ng.deb" && \
    rm -f "$TMPDIR/aircrack-ng.deb" || echo "AVISO: Falha ao instalar $DEB_FILE"
fi

# 6. Criar executavel para o comando 'who' (omitido no coreutils do Android)
echo "[6/11] Configurando comando 'who'..."
printf '#!/data/data/com.termux/files/usr/bin/sh\necho "$(whoami) pts/0 $(date "+%%Y-%%m-%%d %%H:%%M")"\n' > $PREFIX/bin/who
chmod +x $PREFIX/bin/who

# 7. Instalar GNU Chess, Stockfish, Python-Chess e configurar atalhos e estudos PGN
echo "[7/11] Instalando GNU Chess, Stockfish e configurando comandos 'xadrez', 'sf' e 'analisar'..."
pkg install -y gnuchess stockfish python
pip install --quiet chess

mkdir -p "$HOME/.gnuchess" ~/estudos_pgn

for JOGADOR in Alekhine Capablanca Carlsen Fischer Kasparov Tal; do
    echo "Baixando colecao PGN: ${JOGADOR}..."
    curl -fsSL "${REPO_ASSETS}/${JOGADOR}.zip" -o "$HOME/estudos_pgn/${JOGADOR}.zip"
    unzip -p "$HOME/estudos_pgn/${JOGADOR}.zip" > "$HOME/estudos_pgn/${JOGADOR}.pgn"
    rm -f "$HOME/estudos_pgn/${JOGADOR}.zip"
done

cp "$HOME/estudos_pgn/Kasparov.pgn" "$HOME/.gnuchess/gm.pgn"

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

cat << 'EOF' > ~/analisar_pgn.py
import sys
import os
import glob
import chess
import chess.pgn
import chess.engine

def escolher_arquivo():
    pastas = [
        os.path.expanduser("~/estudos_pgn"),
        "/data/data/com.termux/files/home/storage/downloads"
    ]
    arquivos = []
    for p in pastas:
        if os.path.isdir(p):
            arquivos.extend(sorted(glob.glob(os.path.join(p, "*.pgn"))))
            
    if not arquivos:
        print("Nenhum arquivo .pgn encontrado em ~/estudos_pgn ou Downloads.")
        sys.exit(1)
        
    print("\n=== Arquivos PGN Disponiveis ===")
    for idx, arq in enumerate(arquivos, start=1):
        pasta_nome = "Downloads" if "downloads" in arq.lower() else "estudos_pgn"
        print(f" [{idx}] {os.path.basename(arq)} ({pasta_nome})")
        
    escolha = input("\nDigite o numero ou o nome do arquivo (Enter para sair): ").strip()
    if not escolha:
        sys.exit(0)
    if escolha.isdigit() and 1 <= int(escolha) <= len(arquivos):
        return arquivos[int(escolha) - 1]
    for arq in arquivos:
        if os.path.basename(arq).lower() == escolha.lower() or arq == escolha:
            return arq
    print("Arquivo nao encontrado.")
    sys.exit(1)

def escolher_partida(caminho_pgn):
    partidas = []
    with open(caminho_pgn, encoding="utf-8", errors="ignore") as pgn:
        while len(partidas) < 30:
            offset = pgn.tell()
            headers = chess.pgn.read_headers(pgn)
            if headers is None:
                break
            partidas.append((offset, headers))
            
    if not partidas:
        print("Nenhuma partida valida encontrada no arquivo.")
        sys.exit(1)
        
    if len(partidas) == 1:
        with open(caminho_pgn, encoding="utf-8", errors="ignore") as pgn:
            return chess.pgn.read_game(pgn)
            
    print(f"\n=== Partidas em {os.path.basename(caminho_pgn)} (Primeiras {len(partidas)}) ===")
    for idx, (_, h) in enumerate(partidas, start=1):
        w = h.get("White", "?")
        b = h.get("Black", "?")
        dt = h.get("Date", "????")[:4]
        res = h.get("Result", "*")
        print(f" [{idx}] {w} vs {b} ({dt}) [{res}]")
        
    sel = input("\nEscolha o numero da partida (Enter para a #1): ").strip()
    indice = int(sel) - 1 if sel.isdigit() and 1 <= int(sel) <= len(partidas) else 0
    
    with open(caminho_pgn, encoding="utf-8", errors="ignore") as pgn:
        pgn.seek(partidas[indice][0])
        return chess.pgn.read_game(pgn)

def obter_centipawns(score_obj):
    if score_obj.is_mate():
        return 10000 if score_obj.mate() > 0 else -10000
    return score_obj.score()

arquivo_pgn = sys.argv[1] if len(sys.argv) >= 2 else escolher_arquivo()
if not os.path.isfile(arquivo_pgn):
    print(f"Arquivo nao encontrado: {arquivo_pgn}")
    sys.exit(1)

jogo = escolher_partida(arquivo_pgn)
engine = chess.engine.SimpleEngine.popen_uci("stockfish")

brancas = jogo.headers.get("White", "Brancas")
pretas = jogo.headers.get("Black", "Pretas")

print("\n=== Analise Stockfish ===")
print(f"Partida: {brancas} vs {pretas}")
print(f"Resultado: {jogo.headers.get('Result', '*')}\n")

stats = {
    "Brancas": {"lances": 0, "imprecisoes": 0, "erros": 0, "blunders": 0},
    "Pretas": {"lances": 0, "imprecisoes": 0, "erros": 0, "blunders": 0}
}

tabuleiro = jogo.board()

for numero_lance, lance in enumerate(jogo.mainline_moves(), start=1):
    turno = (numero_lance + 1) // 2
    vez_brancas = (tabuleiro.turn == chess.WHITE)
    cor = "Brancas" if vez_brancas else "Pretas"
    lance_san = tabuleiro.san(lance)
    
    info_antes = engine.analyse(tabuleiro, chess.engine.Limit(time=0.2))
    melhor_lance = tabuleiro.san(info_antes["pv"][0]) if "pv" in info_antes and len(info_antes["pv"]) > 0 else "-"
    cp_antes = obter_centipawns(info_antes["score"].pov(tabuleiro.turn))
    
    tabuleiro.push(lance)
    
    info_depois = engine.analyse(tabuleiro, chess.engine.Limit(time=0.2))
    score_white = info_depois["score"].white()
    cp_depois = obter_centipawns(info_depois["score"].pov(not tabuleiro.turn))
    
    perda = max(0, cp_antes - cp_depois)
    stats[cor]["lances"] += 1
    tag = ""
    
    if lance_san != melhor_lance:
        if perda >= 200:
            stats[cor]["blunders"] += 1
            tag = " [?? Erro Grave / Blunder]"
        elif perda >= 100:
            stats[cor]["erros"] += 1
            tag = " [? Erro]"
        elif perda >= 50:
            stats[cor]["imprecisoes"] += 1
            tag = " [?! Imprecisao]"

    if score_white.is_mate():
        avaliacao = f"Mate em {score_white.mate()}"
    else:
        avaliacao = f"{score_white.score() / 100:+.2f}"

    print("=" * 40)
    print(f"Lance {turno} ({cor}): {lance_san}{tag}")
    print(f"Melhor lance seria: {melhor_lance} | Avaliacao: {avaliacao}")
    print(tabuleiro.unicode(invert_color=True, borders=True, empty_square=" "))
    
    resp = input("\n[Enter] Proximo lance | [q] Sair e ver relatorio: ").strip().lower()
    if resp == "q":
        break

engine.quit()

print("\n" + "=" * 40)
print("      RELATORIO FINAL DA PARTIDA")
print("=" * 40)
for lado, nome in [("Brancas", brancas), ("Pretas", pretas)]:
    s = stats[lado]
    print(f"\n{lado} ({nome}):")
    print(f" - Lances analisados : {s['lances']}")
    print(f" - Imprecisoes (?!)  : {s['imprecisoes']}")
    print(f" - Erros (?)         : {s['erros']}")
    print(f" - Blunders (??)     : {s['blunders']}")
print("\n" + "=" * 40)
EOF

printf '#!/data/data/com.termux/files/usr/bin/sh\nexec python "$HOME/jogar_stockfish.py" "$@"\n' > $PREFIX/bin/sf
chmod +x $PREFIX/bin/sf

printf '#!/data/data/com.termux/files/usr/bin/sh\nexec python "$HOME/analisar_pgn.py" "$@"\n' > $PREFIX/bin/analisar
chmod +x $PREFIX/bin/analisar

# 8. Configurar Leitor RSS (Newsboat) e Descanso de Tela Phosphor Ambar
echo "[8/11] Configurando Newsboat e descanso de tela Phosphor Ambar..."
pip install --quiet feedparser

mkdir -p ~/.newsboat
if ! grep -q "g1.globo.com/dynamo/rss2.xml" ~/.newsboat/urls 2>/dev/null; then
    echo 'https://g1.globo.com/dynamo/rss2.xml "~G1 - Últimas Notícias"' >> ~/.newsboat/urls
fi

cat << 'EOF' > ~/phosphor_rss.py
import os
import re
import sys
import time
import select
import termios
import tty
import urllib.request
import feedparser

# Adicione quantos feeds RSS desejar na lista abaixo
FEEDS = [
    "https://g1.globo.com/dynamo/rss2.xml",
]

# Cores ANSI para simular monitor de fosforo ambar (paleta 256 cores)
AMBAR_BRILHANTE = "\033[1;38;5;214m"
AMBAR_ESCURO = "\033[38;5;172m"
LIMPAR_TELA = "\033[2J\033[H"
ESCONDER_CURSOR = "\033[?25l"
MOSTRAR_CURSOR = "\033[?25h"

def limpar_html(texto):
    texto_limpo = re.sub(r'<[^<]+?>', '', texto)
    return " ".join(texto_limpo.split())

def tecla_pressionada():
    return select.select([sys.stdin], [], [], 0) == ([sys.stdin], [], [])

def escrever_lento(texto, velocidade=0.02):
    for char in texto:
        if tecla_pressionada():
            return False
        sys.stdout.write(char)
        sys.stdout.flush()
        time.sleep(velocidade)
    return True

def buscar_noticias():
    noticias = []
    req_headers = {'User-Agent': 'Mozilla/5.0'}
    for url in FEEDS:
        try:
            req = urllib.request.Request(url, headers=req_headers)
            xml_data = urllib.request.urlopen(req, timeout=10).read()
            feed = feedparser.parse(xml_data)
            for entry in feed.entries[:15]:
                titulo = limpar_html(entry.get("title", ""))
                resumo = limpar_html(entry.get("description", ""))
                noticias.append((titulo, resumo))
        except Exception:
            pass
    return noticias

def main():
    fd = sys.stdin.fileno()
    config_antiga = termios.tcgetattr(fd)
    try:
        tty.setcbreak(fd)
        sys.stdout.write(ESCONDER_CURSOR + LIMPAR_TELA)
        
        while True:
            sys.stdout.write(f"{AMBAR_BRILHANTE}>>> SINCRONIZANDO TERMINAL DE NOTICIAS...\n\n")
            noticias = buscar_noticias()
            
            if not noticias:
                if not escrever_lento("SEM CONEXAO. TENTANDO NOVAMENTE...\n", 0.04):
                    break
                time.sleep(5)
                continue

            for titulo, resumo in noticias:
                sys.stdout.write(LIMPAR_TELA)
                if not escrever_lento(f"{AMBAR_BRILHANTE}[MANCHETE] {titulo.upper()}\n\n", 0.025):
                    return
                if not escrever_lento(f"{AMBAR_ESCURO}{resumo}\n\n", 0.015):
                    return
                if not escrever_lento(f"{AMBAR_BRILHANTE}_", 0.05):
                    return
                
                # Pausa de 4 segundos para leitura antes da proxima noticia
                for _ in range(40):
                    if tecla_pressionada():
                        return
                    time.sleep(0.1)
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, config_antiga)
        sys.stdout.write(MOSTRAR_CURSOR + "\033[0m" + LIMPAR_TELA)

if __name__ == "__main__":
    main()
EOF
chmod +x ~/phosphor_rss.py

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
echo " - noticias              -> Abre o leitor de feeds RSS (Newsboat)"
echo " - descanso              -> Inicia o descanso de tela Phosphor Ambar"
echo " - downloads             -> Acessa /sdcard/Download e lista os arquivos"
echo " - fotos                 -> Acessa /sdcard/Pictures e lista os arquivos"
echo " - foto                  -> Exibe a imagem no terminal usando o Viu"
echo " - img                   -> Exibe a imagem no terminal usando o Chafa"
echo " - pixterm -s 2          -> Exibe a imagem em blocos coloridos com o Pixterm"
echo " - xadrez                -> Inicia GNU Chess com livro de aberturas"
echo " - sf                    -> Inicia Stockfish interativo (Elo, dicas e PGN)"
echo " - analisar              -> Menu interativo para analisar partidas .pgn e blunders"
echo " - stockfish             -> Abre o motor UCI Stockfish puro"
echo " - atualizar             -> Atualiza pacotes Termux (pkg update && pkg upgrade -y)"
echo " - mint                  -> Acesso HOST remoto - (ssh usuario@ip)"
echo " - puxar <caminho_local> [destino_remoto] -> Copia arquivos ou pastas do PC para o Android"
echo " - enviar <caminho_remoto> [destino_local] -> Copia arquivos ou pastas do Android para o PC"
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

# 11. Configurar Tmux, descanso de tela automatico, aliases e funcao layout
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

# Descanso de tela Phosphor Ambar apos 60 segundos de inatividade
set -g lock-after-time 60
set -g lock-command "python ~/phosphor_rss.py"
EOF

cat << 'EOF' > ~/.bashrc
# Iniciar automaticamente dentro do tmux (necessario para o descanso de tela por inatividade)
if [ -z "$TMUX" ] && [[ $- == *i* ]]; then
  tmux attach || tmux new
fi

# Iniciar Fastfetch ao abrir
fastfetch

# --- Atalhos Personalizados Termux ---
alias c='clear'
alias atualizar='pkg update && pkg upgrade -y'
alias info='fastfetch'
alias arquivos='yazi'
alias noticias='newsboat'
alias descanso='python ~/phosphor_rss.py'
alias foto='viu'
alias img='chafa'
alias downloads='cd /sdcard/Download && ls -la'
alias fotos='cd /sdcard/Pictures && ls -la'
alias painel='tmux new-session \; split-window -h \; attach'
alias sf='python ~/jogar_stockfish.py'
alias analisar='python ~/analisar_pgn.py'

# Layout completo (Yazi no topo, Fastfetch embaixo-esquerda, Terminal limpo embaixo-direita)
layout() {
  if [ -n "$TMUX" ]; then
    tmux split-window -v 'fastfetch --logo small; bash'
    tmux split-window -h 'cd /sdcard/Download && clear && bash'
    tmux select-pane -U
    yazi
  else
    tmux new-session -d -s vitrine 'yazi'
    tmux split-window -v -t vitrine 'fastfetch --logo small; bash'
    tmux split-window -h -t vitrine.1 'cd /sdcard/Download && clear && bash'
    tmux select-pane -t vitrine.2
    tmux attach-session -t vitrine
  fi
}
EOF

# --- Configuracao Interativa de Acesso Remoto (Tailscale SSH) ---
echo ""
echo "--------------------------------------------------"
echo " Configuracao Opcional: Acesso Remoto SSH (PC)"
echo " (Pressione Enter em branco para pular esta etapa)"
echo "--------------------------------------------------"
read -rp "Digite o usuario do PC (ex: tux): " SSH_USER
read -rp "Digite o IP ou nome MagicDNS do PC (ex: 100.x.x.x ou linux-mint): " SSH_IP

if [ -n "$SSH_USER" ] && [ -n "$SSH_IP" ]; then
  # Remove configuracao anterior, caso o script seja executado novamente
  sed -i '/# --- INICIO TAILSCALE SSH ---/,/# --- FIM TAILSCALE SSH ---/d' ~/.bashrc

  cat << EOF >> ~/.bashrc

# --- INICIO TAILSCALE SSH ---
alias mint='ssh ${SSH_USER}@${SSH_IP}'

puxar() {
  scp -r "${SSH_USER}@${SSH_IP}:\$1" "\${2:-.}"
}

enviar() {
  scp -r "\$1" "${SSH_USER}@${SSH_IP}:\${2:-~/}"
}
# --- FIM TAILSCALE SSH ---
EOF

  echo "Atalhos 'mint', 'puxar' e 'enviar' configurados para ${SSH_USER}@${SSH_IP}!"
  echo "Exemplos de uso (apos reiniciar o terminal ou rodar 'source ~/.bashrc'):"
  echo "  mint"
  echo "  puxar <caminho_remoto> [destino_local]"
  echo "  enviar <caminho_local> [destino_remoto]"
else
  echo "Configuracao SSH ignorada."
fi

termux-reload-settings

echo "=================================================="
echo " Instalacao concluida! Reinicie o Termux (exit).  "
echo "=================================================="
