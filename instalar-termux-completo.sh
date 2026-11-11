#!/data/data/com.termux/files/usr/bin/bash

echo "=================================================="
echo "   Instalacao Automatizada - Termux Completo      "
echo "=================================================="

# 1. Solicitar permissao de armazenamento
if [ ! -d ~/storage ]; then
    echo "[1/6] Solicitando permissao de armazenamento..."
    termux-setup-storage
    sleep 3
fi

# 2. Atualizar repositorios e pacotes sem travar em perguntas
echo "[2/6] Atualizando sistema e repositorios..."
yes | pkg update -y
yes | pkg upgrade -y -o Dpkg::Options::="--force-confold"

# 3. Instalar pacotes essenciais
echo "[3/6] Instalando fastfetch, tmux, viu, chafa, yazi, openssh e golang..."
pkg install fastfetch tmux viu chafa yazi openssh curl git golang -y

# 4. Baixar e compilar o Pixterm
echo "[4/6] Compilando o Pixterm..."
rm -rf ~/pixterm
git clone https://github.com ~/pixterm
cd ~/pixterm || exit
go install ./cmd/pixterm
cp ~/go/bin/pixterm "$PREFIX/bin/"
cd ~ || exit
rm -rf ~/pixterm

# 5. Configurar tema Dracula e JetBrainsMono Nerd Font
echo "[5/6] Aplicando tema Dracula e JetBrainsMono Nerd Font..."
mkdir -p ~/.termux
curl -fsSL https://githubusercontent.com -o ~/.termux/colors.properties
curl -fsSL https://github.com -o ~/.termux/font.ttf

# 6. Configurar Tmux, aliases e funcao layout
echo "[6/6] Configurando Tmux, atalhos e layout..."
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

# Acesso rapido ao Linux Mint via Tailscale SSH
alias mint='ssh taden@100.106.98.88'
alias puxar='scp -r taden@100.106.98.88:~/'

# Layout completo (Yazi no topo, Fastfetch embaixo-esquerda, Terminal limpo embaixo-direita)
layout() {
  tmux new-session -d -s vitrine 'yazi'
  tmux split-window -v -t vitrine 'fastfetch --logo small; bash'
  tmux split-window -h -t vitrine.1 'cd /sdcard/Download && clear && bash'
  tmux select-pane -t vitrine.2
  tmux attach-session -t vitrine
}
EOF

termux-reload-settings
source ~/.bashrc

echo "=================================================="
echo "   Instalacao concluida! Reinicie o Termux.       "
echo "=================================================="
