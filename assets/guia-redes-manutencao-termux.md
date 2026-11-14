# Guia de Redes, Diagnóstico e Manutenção no Termux (Sem Root)

Documentação técnica de referência elaborada para estudo de caso, diagnóstico de redes locais e manutenção futura do ambiente **Termux** em dispositivos Android sem acesso superusuário (*root*).

---

## 1. Contexto do Ambiente (Estudo de Caso)

Este guia toma como base um ambiente Android configurado com sucesso utilizando gerenciador de pacotes `pkg`/`dpkg`:

* **Dispositivo / Arquitetura:** Tablet Android (ARM64 / `aarch64`) sem acesso *root*.
* **Shell e Ambiente:** Termux com Bash 5.3+ e conjunto completo de utilitários de linha de comando (282+ pacotes instalados).
* **Interfaces de Rede Identificadas:**
  * `lo`: Interface de *loopback* (`127.0.0.1`).
  * `wlan0`: Rede local Wi-Fi principal (ex.: sub-rede `192.168.68.0/24`).
  * `tun1`: Interface de túnel VPN ativa (quando conectada).

### Implicações da Ausência de Root no Android
* **Restrições do Kernel:** Leituras diretas em `/proc/net/dev` ou abertura de *raw sockets* (modo promíscuo na placa `wlan0`) são bloqueadas pelo sistema operacional.
* **Ferramentas Afetadas:** Capturas em tempo real com `tcpdump`, `aircrack-ng` e `tshark` ao vivo não operam sem *root*. Contudo, o `tshark -r arquivo.pcap` funciona normalmente para análise offline de capturas importadas.
* **Ferramentas Plenas:** Varreduras TCP padrão (`nmap -sT`), testes de portas (`nc`, `ss`), conexões remotas (`ssh`), requisições HTTP (`curl`, `wget`), consultas DNS (`dig`, `whois`), rotas TCP (`traceroute -T`) e testes de banda (`speedtest-go`, `iperf3`) funcionam 100% sem *root*.

---

## 2. Procedimentos Práticos de Rede (100% Sem Root)

### 2.1. Descoberta de Dispositivos e Portas na Rede Local (`nmap`)
Sem privilégios de administrador, o `nmap` utiliza o *three-way handshake* TCP completo (`-sT`), evitando *raw sockets*.

```bash
# Descobrir todos os hosts ativos na sub-rede Wi-Fi local
nmap -sn 192.168.68.0/24

# Escanear portas TCP abertas em um dispositivo alvo (ex.: roteador ou servidor)
nmap -sT 192.168.68.1

# Identificar serviços, versões e banners (infere o Sistema Operacional remoto)
nmap -sT -sV 192.168.68.100

# Varredura rápida das 100 portas mais comuns
nmap -sT -F 192.168.68.100
```

### 2.2. Portas Disponíveis e Testes de Conectividade (`ss` e `nc`)
Para auditar portas abertas no próprio tablet e testar disponibilidade de portas em hosts remotos:

```bash
# Listar todas as portas em escuta (LISTEN) e conexões ativas no Termux
ss -tuln

# Testar se uma porta TCP específica está aberta em um destino remoto
nc -zv 192.168.68.100 22

# Testar um intervalo de portas em um servidor remoto
nc -zv 192.168.68.100 20-25

# Abrir uma porta temporária de escuta no Termux para testes de recepção
nc -l -p 8080
```

### 2.3. Identificação de Sistema e Usuário Remoto (`ssh`)
Para inspecionar máquinas Linux/Unix na rede local ou servidores externos com serviço SSH habilitado:

```bash
# Iniciar sessão remota interativa
ssh usuario@192.168.68.100

# Consultar usuário ativo, hostname e versão do kernel/SO sem abrir shell completo
ssh usuario@192.168.68.100 "whoami && hostname && uname -a"

# Listar usuários atualmente logados na máquina remota
ssh usuario@192.168.68.100 "who"

# Verificar tempo de atividade (uptime) e carga do servidor remoto
ssh usuario@192.168.68.100 "uptime"
```

### 2.4. Inspeção de Serviços Web, APIs e IP Público (`curl`)
Útil para validar saída de internet, confirmar roteamento via VPN (`tun1`) e inspecionar cabeçalhos HTTP:

```bash
# Exibir apenas os cabeçalhos HTTP de resposta (revela servidor web e tecnologia)
curl -I http://192.168.68.1

# Consultar o IP público atual visto pela internet
curl -s ifconfig.me && echo ""

# Medir latência total e código de status HTTP de um destino
curl -o /dev/null -s -w "Tempo total: %{time_total}s | Status: %{http_code}\n" https://google.com
```

### 2.5. Resolução DNS, Rotas TCP e Registros (`dig`, `traceroute`, `whois`)

```bash
# Obter o endereço IP resolvido para um domínio
dig google.com +short

# Testar resolução DNS usando um servidor específico (ex.: Cloudflare 1.1.1.1)
dig @1.1.1.1 github.com

# Rastrear saltos de roteamento usando pacotes TCP (-T evita bloqueio de ICMP sem root)
traceroute -T 8.8.8.8

# Consultar informações de proprietário, ASN e bloco de rede de um IP público
whois 177.220.178.12
```

### 2.6. Medição de Largura de Banda (`speedtest-go` e `iperf3`)

```bash
# Testar velocidade de download, upload, latência e perda de pacotes na internet
speedtest-go

# Testar largura de banda interna entre o tablet (cliente) e um PC na rede (servidor)
iperf3 -c 192.168.68.100
```

---

## 3. Padrão de Provisionamento e Manutenção de Pacotes

Para evitar falhas em cadeia durante instalações automatizadas via script Bash no Termux, recomenda-se sempre utilizar um *array* combinado com um laço `for` protegido contra erros individuais.

### Estrutura Recomendada para Scripts de Setup (`setup-termux.sh`)

```bash
#!/data/data/com.termux/files/usr/bin/bash

# Atualizar base de pacotes
pkg update -y && pkg upgrade -y

# Habilitar repositórios extras antes de pacotes avançados
pkg install -y tur-repo root-repo
pkg update -y

# Lista unificada e categorizada de pacotes
PACOTES=(
    # Essenciais e Interface
    fastfetch tmux viu chafa yazi openssh curl git golang
    # Rede e Diagnóstico (Uso pleno sem root)
    net-tools iproute2 dnsutils inetutils traceroute nmap
    wget whois netcat-openbsd tor speedtest-go iperf3
    # Análise Offline e Utilitários Extras
    tshark tcpdump aircrack-ng
    # Utilitários Bash, Arquivos e Monitoramento
    coreutils findutils grep sed gawk jq tree zip unzip
    tar htop nano vim file which util-linux procps
    termux-tools termux-api 7zip nnn eza cmatrix
)

# Instalação individual tolerante a falhas
FALHAS=()
for pacote in "${PACOTES[@]}"; do
    echo "--> Instalando: $pacote"
    if ! pkg install -y "$pacote"; then
        echo "AVISO: Falha ao instalar $pacote"
        FALHAS+=("$pacote")
    fi
done

# Relatório final de integridade
if [ ${#FALHAS[@]} -gt 0 ]; then
    echo "Pacotes que falharam na instalação: ${FALHAS[*]}"
else
    echo "Todos os pacotes foram instalados com sucesso!"
fi
```

---

## 4. Checklist de Manutenção Futura

* **Atualização Periódica:** Execute `pkg update && pkg upgrade -y` quinzenalmente para manter assinaturas de repositórios e binários atualizados.
* **Limpeza de Cache:** Utilize `pkg autoclean && pkg clean` para liberar espaço no armazenamento interno (`/data/data/com.termux`).
* **Auditoria de Rede Local:** Sempre verifique sua sub-rede atual antes de rodar varreduras com `nmap`, usando `ifconfig wlan0` ou `ip -4 addr show wlan0`.
* **Backup de Scripts:** Mantenha seus scripts de automação e este guia versionados em um repositório Git remoto para rápida restauração em caso de reinstalação do aplicativo.
