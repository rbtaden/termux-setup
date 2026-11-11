#!/data/data/com.termux/files/usr/bin/bash

echo "=================================================="
echo "   Instalacao Automatizada - Termux Completo      "
echo "=================================================="

# URL base dos arquivos salvos no seu repositorio (pasta assets)
REPO_ASSETS="https://githubusercontent.com"

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

# 4. Baixar e compilar o Pixterm a partir da pasta assets do seu repositorio
echo "[4/6] Compilando o Pixterm..."
rm -rf ~/pixterm ~/pixterm.tar
curl -fsSL "${REPO_ASSETS}/pixterm.tar" -o ~/pixterm.tar
tar -xf ~/pixterm.tar -C ~
rm -f ~/pixterm.tar
cd ~/pixterm || exit
go install ./cmd/pixterm
cp ~/go/bin/pixterm "$PREFIX/bin/"
cd ~ || exit
rm -rf ~/pixterm

# 5. Configurar tema Dracula e JetBrainsMono Nerd Font a partir da pasta assets
echo "[5/6] Aplicando tema Dracula e JetBrainsMono Nerd Font..."
mkdir -p ~/.termux
curl -fsSL "${REPO_ASSETS}/colors.properties" -o ~/.termux/colors.properties
curl -fsSL "${REPO_ASSETS}/JetBrainsMonoNerdFontMono-Regular.ttf" -o ~/.termux/font.ttf

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
echo "   Instalacao concluida! Reinicie o Termux.       "
echo "=================================================="
