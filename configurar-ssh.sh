#!/data/data/com.termux/files/usr/bin/bash

echo "=================================================="
echo "   Configuracao Interativa - Tailscale SSH        "
echo "=================================================="
echo "Lembrete: No computador/servidor de destino, ative"
echo "o Tailscale SSH executando no terminal dele:"
echo "  sudo tailscale up --ssh"
echo "--------------------------------------------------"

# Garante que openssh e rsync estejam instalados
for pkg_req in openssh rsync; do
    if ! command -v "$pkg_req" >/dev/null 2>&1; then
        echo "Instalando dependencia ausente: $pkg_req..."
        pkg install -y "$pkg_req"
    fi
done

echo ""
echo "Escolha o modo de configuracao:"
echo " [1] Configurar / Atualizar PC Principal (atalhos: remoto, sftp-pc, puxar, enviar, sincronizar, backuppc)"
echo " [2] Adicionar um Servidor Extra no ~/.ssh/config (atalho dedicado)"
echo " [0] Sair"
echo ""
read -rp "Opcao [1]: " MODO
MODO=${MODO:-1}

if [ "$MODO" = "0" ]; then
    echo "Operacao cancelada."
    exit 0
fi

echo ""
read -rp "Digite o usuario do host remoto (ex: tux): " SSH_USER
read -rp "Digite o IP Tailscale ou MagicDNS (ex: 100.x.x.x ou remote): " SSH_IP

if [ -z "$SSH_USER" ] || [ -z "$SSH_IP" ]; then
    echo "[ERRO] Usuario e IP/MagicDNS sao obrigatorios."
    exit 1
fi

if [ "$MODO" = "1" ]; then
    read -rp "Apelido curto para ~/.ssh/config [Enter para 'pc-remoto']: " SSH_ALIAS
    SSH_ALIAS=${SSH_ALIAS:-pc-remoto}

    # 1. Atualizar ~/.ssh/config para o host principal
    mkdir -p ~/.ssh && chmod 700 ~/.ssh
    touch ~/.ssh/config && chmod 600 ~/.ssh/config
    sed -i '/# --- INICIO TAILSCALE SSH PRINCIPAL ---/,/# --- FIM TAILSCALE SSH PRINCIPAL ---/d' ~/.ssh/config
    sed -i '/# --- INICIO TAILSCALE SSH ---/,/# --- FIM TAILSCALE SSH ---/d' ~/.ssh/config

    cat << EOF >> ~/.ssh/config

# --- INICIO TAILSCALE SSH PRINCIPAL ---
Host ${SSH_ALIAS}
    HostName ${SSH_IP}
    User ${SSH_USER}
    Port 22
    ServerAliveInterval 60
# --- FIM TAILSCALE SSH PRINCIPAL ---
EOF

    # 2. Gerar/Atualizar script automatizado ~/backup_pc.sh (tar + ssh on-the-fly)
    cat << EOF > ~/backup_pc.sh
#!/data/data/com.termux/files/usr/bin/bash

ORIGEM="/sdcard/Download"
DESTINO_HOST="${SSH_ALIAS}"
DESTINO_PASTA="~/Downloads/ANDROID_Backup"

echo "====================================================="
echo " Iniciando transferencia: ANDROID -> \${DESTINO_HOST}"
echo "====================================================="

if [ ! -d "\$ORIGEM" ]; then
    echo "[ERRO] Pasta \$ORIGEM nao encontrada. Rode 'termux-setup-storage'."
    exit 1
fi

tar -czf - -C "\$ORIGEM" . | ssh "\$DESTINO_HOST" "mkdir -p \$DESTINO_PASTA && tar -xzf - -C \$DESTINO_PASTA"

if [ \$? -eq 0 ]; then
    echo "[SUCESSO] Todos os arquivos foram transferidos para \${DESTINO_HOST}:\${DESTINO_PASTA}"
else
    echo "[FALHA] Erro na transferencia. Verifique a conexao Tailscale e o SSH."
fi
EOF
    chmod +x ~/backup_pc.sh

    # 3. Registrar atalhos e funcoes principais no ~/.bashrc
    touch ~/.bashrc
    sed -i '/# --- INICIO TAILSCALE SSH ---/,/# --- FIM TAILSCALE SSH ---/d' ~/.bashrc

    cat << EOF >> ~/.bashrc

# --- INICIO TAILSCALE SSH ---
alias remoto='ssh ${SSH_ALIAS}'
alias sftp-pc='sftp ${SSH_ALIAS}'
alias backuppc='~/backup_pc.sh'

puxar() {
  scp -r "${SSH_ALIAS}:\$1" "\${2:-/sdcard/Download/}"
}

enviar() {
  scp -r "\$1" "${SSH_ALIAS}:\${2:-~/Downloads/}"
}

sincronizar() {
  rsync -avz --progress "\$1" "${SSH_ALIAS}:\${2:-~/Downloads/ANDROID_Backup/}"
}
# --- FIM TAILSCALE SSH ---
EOF

    echo ""
    echo "[OK] PC Principal configurado como '${SSH_ALIAS}' (${SSH_USER}@${SSH_IP})."
    echo "[OK] Comandos disponiveis: remoto | sftp-pc | puxar | enviar | sincronizar | backuppc"

elif [ "$MODO" = "2" ]; then
    read -rp "Nome/Apelido unico para este servidor (ex: servidor-casa, vps): " SSH_ALIAS
    if [ -z "$SSH_ALIAS" ]; then
        echo "[ERRO] O apelido do servidor nao pode ficar em branco."
        exit 1
    fi

    mkdir -p ~/.ssh && chmod 700 ~/.ssh
    touch ~/.ssh/config && chmod 600 ~/.ssh/config
    sed -i "/# --- INICIO HOST EXTRA: ${SSH_ALIAS} ---/,/# --- FIM HOST EXTRA: ${SSH_ALIAS} ---/d" ~/.ssh/config

    cat << EOF >> ~/.ssh/config

# --- INICIO HOST EXTRA: ${SSH_ALIAS} ---
Host ${SSH_ALIAS}
    HostName ${SSH_IP}
    User ${SSH_USER}
    Port 22
    ServerAliveInterval 60
# --- FIM HOST EXTRA: ${SSH_ALIAS} ---
EOF

    touch ~/.bashrc
    sed -i "/# --- ATALHO HOST EXTRA: ${SSH_ALIAS} ---/,/# --- FIM ATALHO HOST EXTRA: ${SSH_ALIAS} ---/d" ~/.bashrc

    cat << EOF >> ~/.bashrc

# --- ATALHO HOST EXTRA: ${SSH_ALIAS} ---
alias ssh-${SSH_ALIAS}='ssh ${SSH_ALIAS}'
# --- FIM ATALHO HOST EXTRA: ${SSH_ALIAS} ---
EOF

    echo ""
    echo "[OK] Servidor extra '${SSH_ALIAS}' adicionado ao ~/.ssh/config!"
    echo "[OK] Conecte usando 'ssh ${SSH_ALIAS}' ou 'ssh-${SSH_ALIAS}'."
else
    echo "[ERRO] Opcao invalida."
    exit 1
fi

# 4. Configuracao opcional de chave Ed25519 sem senha
echo ""
read -rp "Deseja gerar/enviar chave SSH Ed25519 para acesso sem senha agora? (s/N): " GERAR_CHAVE
if [[ "$GERAR_CHAVE" =~ ^[Ss]$ ]]; then
    if [ ! -f ~/.ssh/id_ed25519 ]; then
        ssh-keygen -t ed25519 -C "termux-android" -N "" -f ~/.ssh/id_ed25519
    fi
    echo "Copiando chave publica para ${SSH_USER}@${SSH_IP} (digite a senha do host se solicitado)..."
    ssh-copy-id -i ~/.ssh/id_ed25519.pub "${SSH_USER}@${SSH_IP}" || \
        echo "AVISO: Nao foi possivel copiar a chave agora. Tente depois com: ssh-copy-id ${SSH_ALIAS}"
fi

echo ""
echo "=================================================="
echo " Configuracao concluida!                          "
echo " Execute 'source ~/.bashrc' para ativar agora.    "
echo "=================================================="
