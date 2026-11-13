# Estudo de Caso e Documentação Técnica: Stockfish Interativo e Setup Termux

Este documento consolida todo o estudo de caso, diagnóstico técnico, evolução dos scripts em Python para o **Stockfish** (`jogar_stockfish.py` e `analisar_pgn.py`), biblioteca de estudos e coleções de Grandes Mestres em PGN (`~/estudos_pgn/`), ajustes visuais no **GNU Chess** (`xadrez`) e o instalador automatizado definitivo para o ambiente **Termux** (`instalar-termux-completo.sh`).

---

## 1. Diagnóstico do Problema Original

Ao tentar jogar diretamente pelo comando `stockfish` no terminal do Termux usando lances simples como `e4`, ocorre um erro de interpretação.

* **Diferença de Interface:** O comando `xadrez` (GNU Chess) oferece uma interface interativa voltada para humanos, aceitando notação algébrica curta (`e4`, `Nf3`, `O-O`). Já o executável `stockfish` é um motor de cálculo puro que opera exclusivamente via protocolo **UCI (Universal Chess Interface)**.
* **Notação Exigida pelo UCI:** O motor exige a notação algébrica longa (casa de origem + destino, como `e2e4`) precedida de comandos de estado completo da partida:
  1. `uci` — Inicializa o protocolo.
  2. `position startpos moves e2e4 e7e5` — Envia todo o histórico acumulado desde o início.
  3. `go movetime 1000` — Solicita o cálculo por 1000 milissegundos.

---

## 2. Solução Arquitetural: Wrappers em Python (`python-chess`)

Para criar uma experiência fluida semelhante ao GNU Chess, mas utilizando o poder de cálculo do Stockfish tanto para jogar quanto para estudar partidas, foram desenvolvidas duas ferramentas em Python usando a biblioteca `chess` (`chess.engine` e `chess.pgn`) e registradas como executáveis diretos em `$PREFIX/bin/`.

### 2.1. Modo Jogo Interativo (`~/jogar_stockfish.py` — comando `sf`)
* **Tabuleiro Visual Unicode Limpo:** Exibição no terminal com bordas, inversão automática conforme a cor escolhida e casas vazias limpas (`empty_square=" "`), evitando a exibição de círculos pontilhados (`⭘`) causados pela substituição de glifos da fonte `JetBrainsMono Nerd Font`.
* **Controle de Dificuldade (Elo):** Ativação das flags UCI `UCI_LimitStrength` e `UCI_Elo`, permitindo ajustar a força do motor entre **1320** e **3190** pontos (padrão `1500`).
* **Escolha de Lado (`b` ou `p`):** Permite jogar de Brancas ou Pretas (com o motor fazendo o primeiro lance automaticamente quando o usuário escolhe Pretas).
* **Comando `hint` (Dica):** Solicita ao motor uma análise rápida (`time=0.5s`) e exibe a melhor jogada recomendada sem aplicá-la ao tabuleiro.
* **Comando `undo` (Desfazer):** Remove os dois últimos meio-lances da pilha (`board.pop()` duas vezes), devolvendo o tabuleiro exatamente para a vez anterior do jogador.
* **Exportação Automática em PGN:** Ao finalizar a partida (por xeque-mate, empate ou comando `quit`), salva o histórico completo com cabeçalhos padrão (`Event`, `Date`, `White`, `Black`, `Result`) diretamente na pasta **Downloads** do Android (`/data/data/com.termux/files/home/storage/downloads`), com fallback seguro para `~/` caso o armazenamento não esteja montado.

### 2.2. Modo Análise Interativa (`~/analisar_pgn.py` — comando `analisar`)
* **Menu Interativo de Arquivos:** Quando executado sem argumentos (`analisar`), varre automaticamente os diretórios `~/estudos_pgn/` e `/data/data/com.termux/files/home/storage/downloads`, listando todos os arquivos `.pgn` numerados para seleção rápida por número ou nome.
* **Seletor de Partidas em Coleções:** Ao abrir um arquivo contendo múltiplas partidas (como `Fischer.pgn` ou `Carlsen.pgn`), lê os cabeçalhos via `chess.pgn.read_headers()` e exibe as 30 primeiras partidas com os nomes dos jogadores, ano e resultado para escolha direta via `seek()`.
* **Avaliação Lance a Lance e Classificação:** Compara a pontuação em centésimos de peão (`centipawns`) antes e depois de cada movimento:
  * **Imprecisão (`?!`):** Perda entre `0.50` e `0.99` peões.
  * **Erro (`?`):** Perda entre `1.00` e `1.99` peões.
  * **Erro Grave / Blunder (`??`):** Perda de `2.00` peões ou mais.
* **Relatório Final da Partida:** Ao terminar a revisão (ou sair com `q`), imprime o resumo estatístico separado para Brancas e Pretas.

### 2.3. Biblioteca de Estudos e Coleções Próprias (`~/estudos_pgn/`)
Para eliminar dependências de links externos sujeitos a falhas, os 6 arquivos `.zip` de Grandes Mestres foram hospedados diretamente na pasta `assets/` do repositório GitHub (`Alekhine.zip`, `Capablanca.zip`, `Carlsen.zip`, `Fischer.zip`, `Kasparov.zip` e `Tal.zip`), sendo baixados e extraídos durante a instalação junto com as três partidas clássicas individuais (`opera.pgn`, `pastor.pgn` e `capablanca.pgn`).

---

## 3. Código Definitivo dos Scripts em Python

### 3.1. Jogo Interativo (`~/jogar_stockfish.py`)

```python
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

print(f"
Nivel: {elo_val} Elo | Voce joga de {'Pretas' if user_color == chess.BLACK else 'Brancas'}.")
print("Comandos: e4 (jogar) | hint (dica) | undo (voltar) | quit (sair)
")

while not board.is_game_over():
    if board.turn == user_color:
        print(board.unicode(invert_color=True, borders=True, orientation=user_color, empty_square=" "))
        move_str = input("
Seu lance: ").strip()
        
        if move_str == "quit":
            break
        elif move_str == "hint":
            print("Calculando dica...")
            hint_res = engine.play(board, chess.engine.Limit(time=0.5))
            print(f"Dica: tente jogar {board.san(hint_res.move)}
")
            continue
        elif move_str == "undo":
            if len(board.move_stack) >= 2:
                board.pop()
                board.pop()
                print("Ultima jogada desfeita.
")
            else:
                print("Ainda nao ha lances suficientes para voltar.
")
            continue
            
        try:
            board.push_san(move_str)
        except ValueError:
            print("Lance invalido. Tente novamente (ex: e4, Nf3, O-O).")
            continue
    else:
        print("Stockfish pensando...")
        result = engine.play(board, chess.engine.Limit(time=0.2))
        print(f"Stockfish jogou: {board.san(result.move)}
")
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
```

### 3.2. Analisador Interativo de Partidas PGN (`~/analisar_pgn.py`)

```python
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
        
    print("
=== Arquivos PGN Disponiveis ===")
    for idx, arq in enumerate(arquivos, start=1):
        pasta_nome = "Downloads" if "downloads" in arq.lower() else "estudos_pgn"
        print(f" [{idx}] {os.path.basename(arq)} ({pasta_nome})")
        
    escolha = input("
Digite o numero ou o nome do arquivo (Enter para sair): ").strip()
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
            
    print(f"
=== Partidas em {os.path.basename(caminho_pgn)} (Primeiras {len(partidas)}) ===")
    for idx, (_, h) in enumerate(partidas, start=1):
        w = h.get("White", "?")
        b = h.get("Black", "?")
        dt = h.get("Date", "????")[:4]
        res = h.get("Result", "*")
        print(f" [{idx}] {w} vs {b} ({dt}) [{res}]")
        
    sel = input("
Escolha o numero da partida (Enter para a #1): ").strip()
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

print("
=== Analise Stockfish ===")
print(f"Partida: {brancas} vs {pretas}")
print(f"Resultado: {jogo.headers.get('Result', '*')}
")

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
    
    resp = input("
[Enter] Proximo lance | [q] Sair e ver relatorio: ").strip().lower()
    if resp == "q":
        break

engine.quit()

print("
" + "=" * 40)
print("      RELATORIO FINAL DA PARTIDA")
print("=" * 40)
for lado, nome in [("Brancas", brancas), ("Pretas", pretas)]:
    s = stats[lado]
    print(f"
{lado} ({nome}):")
    print(f" - Lances analisados : {s['lances']}")
    print(f" - Imprecisoes (?!)  : {s['imprecisoes']}")
    print(f" - Erros (?)         : {s['erros']}")
    print(f" - Blunders (??)     : {s['blunders']}")
print("
" + "=" * 40)
```

---

## 4. Melhorias Aplicadas no GNU Chess (`xadrez`)

1. **Livro de Aberturas Local:** Uso direto da coleção `Kasparov.pgn` extraída de `${REPO_ASSETS}/Kasparov.zip` e copiada para `$HOME/.gnuchess/gm.pgn`, gerando `book.dat` sem depender de servidores de terceiros.
2. **Supressão do Aviso `Bad address`:** Execução ajustada para `exec gnuchess 2>&1 | grep --line-buffered -v "Bad address"`, mantendo a interface do terminal limpa sem bloquear o buffer de saída.
3. **Dica Inicial de Lado:** Inclusão da instrução `go (jogar de pretas)` na mensagem de boas-vindas do executável `xadrez`.

---

## 5. Script Instalador Definitivo (`instalar-termux-completo.sh`)

```bash
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
printf '#!/data/data/com.termux/files/usr/bin/sh
echo "$(whoami) pts/0 $(date "+%%Y-%%m-%%d %%H:%%M")"
' > $PREFIX/bin/who
chmod +x $PREFIX/bin/who

# 8. Instalar GNU Chess, Stockfish, Python-Chess e configurar atalhos e estudos PGN
echo "[8/11] Instalando GNU Chess, Stockfish e configurando comandos 'xadrez', 'sf' e 'analisar'..."
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

printf '#!/data/data/com.termux/files/usr/bin/sh
cd "$HOME/.gnuchess"
if [ ! -f book.dat ] && [ -s gm.pgn ]; then
  printf "book add gm.pgn\nquit\n" | gnuchess >/dev/null 2>&1
fi
echo "=== GNU Chess Pronto ==="
echo "Comandos: e4 (jogar) | go (jogar de pretas) | show board (tabuleiro) | hint (dica) | quit (sair)"
exec gnuchess 2>&1 | grep --line-buffered -v "Bad address"
' > $PREFIX/bin/xadrez
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

print(f"
Nivel: {elo_val} Elo | Voce joga de {'Pretas' if user_color == chess.BLACK else 'Brancas'}.")
print("Comandos: e4 (jogar) | hint (dica) | undo (voltar) | quit (sair)
")

while not board.is_game_over():
    if board.turn == user_color:
        print(board.unicode(invert_color=True, borders=True, orientation=user_color, empty_square=" "))
        move_str = input("
Seu lance: ").strip()
        
        if move_str == "quit":
            break
        elif move_str == "hint":
            print("Calculando dica...")
            hint_res = engine.play(board, chess.engine.Limit(time=0.5))
            print(f"Dica: tente jogar {board.san(hint_res.move)}
")
            continue
        elif move_str == "undo":
            if len(board.move_stack) >= 2:
                board.pop()
                board.pop()
                print("Ultima jogada desfeita.
")
            else:
                print("Ainda nao ha lances suficientes para voltar.
")
            continue
            
        try:
            board.push_san(move_str)
        except ValueError:
            print("Lance invalido. Tente novamente (ex: e4, Nf3, O-O).")
            continue
    else:
        print("Stockfish pensando...")
        result = engine.play(board, chess.engine.Limit(time=0.2))
        print(f"Stockfish jogou: {board.san(result.move)}
")
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

# Criar script de analise interativa com menu de arquivos, selecao de partidas e relatorio de blunders
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
        
    print("
=== Arquivos PGN Disponiveis ===")
    for idx, arq in enumerate(arquivos, start=1):
        pasta_nome = "Downloads" if "downloads" in arq.lower() else "estudos_pgn"
        print(f" [{idx}] {os.path.basename(arq)} ({pasta_nome})")
        
    escolha = input("
Digite o numero ou o nome do arquivo (Enter para sair): ").strip()
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
            
    print(f"
=== Partidas em {os.path.basename(caminho_pgn)} (Primeiras {len(partidas)}) ===")
    for idx, (_, h) in enumerate(partidas, start=1):
        w = h.get("White", "?")
        b = h.get("Black", "?")
        dt = h.get("Date", "????")[:4]
        res = h.get("Result", "*")
        print(f" [{idx}] {w} vs {b} ({dt}) [{res}]")
        
    sel = input("
Escolha o numero da partida (Enter para a #1): ").strip()
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

print("
=== Analise Stockfish ===")
print(f"Partida: {brancas} vs {pretas}")
print(f"Resultado: {jogo.headers.get('Result', '*')}
")

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
    
    resp = input("
[Enter] Proximo lance | [q] Sair e ver relatorio: ").strip().lower()
    if resp == "q":
        break

engine.quit()

print("
" + "=" * 40)
print("      RELATORIO FINAL DA PARTIDA")
print("=" * 40)
for lado, nome in [("Brancas", brancas), ("Pretas", pretas)]:
    s = stats[lado]
    print(f"
{lado} ({nome}):")
    print(f" - Lances analisados : {s['lances']}")
    print(f" - Imprecisoes (?!)  : {s['imprecisoes']}")
    print(f" - Erros (?)         : {s['erros']}")
    print(f" - Blunders (??)     : {s['blunders']}")
print("
" + "=" * 40)
EOF

printf '#!/data/data/com.termux/files/usr/bin/sh
exec python "$HOME/jogar_stockfish.py" "$@"
' > $PREFIX/bin/sf
chmod +x $PREFIX/bin/sf

printf '#!/data/data/com.termux/files/usr/bin/sh
exec python "$HOME/analisar_pgn.py" "$@"
' > $PREFIX/bin/analisar
chmod +x $PREFIX/bin/analisar

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
echo " - analisar              -> Menu interativo para analisar partidas .pgn e blunders"
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
```

---

## 6. Guia de Manutenção e Boas Práticas

* **Padrão de Quebra de Linha (`LF`):** Sempre edite e salve os scripts `.sh` com quebras de linha no padrão Unix (`LF`). Se editar no Windows, converta antes do commit usando `dos2unix instalar-termux-completo.sh`.
* **Validação de Sintaxe antes de Subir:** Execute `bash -n instalar-termux-completo.sh` no Termux para garantir que não há blocos `EOF` abertos ou erros de sintaxe.
* **Expansão da Biblioteca de Estudos:** Para adicionar novas coleções `.zip` de jogadores ou aberturas no futuro, basta enviar o arquivo `.zip` para a pasta `assets/` do seu repositório e incluir o nome dele no laço `for JOGADOR in ...` da Etapa 8.
