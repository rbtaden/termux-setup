
# Alguns Atalhos e Comandos Customizados Disponíveis

## Visualização, Sistema e Jogos:

 - termux-setup-storage -> Libera acesso a /sdcard
 - who                              -> Exibe usuario e sessao atual
 - c                                   -> Limpa a tela do terminal (clear)
 - exit                               -> Fecha o painel atual
 - layout                           -> Interface customizada: Yazi, Fastfetch e Terminal
                                              Abre o Tmux dividido em 3 painéis (Yazi no topo, Fastfetch embaixo à esquerda
                                              e Terminal limpo embaixo à direita).
 - painel                           -> Interface customizada: 2 paineis
                                              Inicia o Tmux dividido rapidamente em 2 painéis lado a lado.
 - info                               -> Executa o Fastfetch manualmente
 - arquivos                        -> Abre o gerenciador de arquivos Yazi
 - downloads                     -> Acessa /sdcard/Download e lista os arquivos
 - fotos                              -> Acessa /sdcard/Pictures e lista os arquivos
 - foto <imagem>             -> Exibe a imagem no terminal usando o Viu
 - img <imagem>             -> Exibe a imagem no terminal usando o Chafa
 - pixterm -s 2 <imagem>-> Exibe a imagem em blocos coloridos de alta definição  com o Pixterm
 - xadrez                            -> Inicia GNU Chess com livro de aberturas (digite go no início para jogar de pretas)
 - sf                                    -> Inicia Stockfish interativo (Elo, dicas e PGN)
                                                Inicia Stockfish interativo com tabuleiro limpo,
                                                escolha de Elo/cor, hint, undo e exportação de .pgn para Downloads.
 - analisar [arquivo.pgn]     -> Menu interativo para analisar partidas .pgn e blunders
                                                Abre o menu interativo de arquivos e partidas .pgn
                                                (ou analisa diretamente o arquivo informado) com avaliação lance a lance
                                                e relatório de blunders.
 - stockfish                         -> Abre o motor UCI Stockfish puro
 - atualizar                         -> Atualiza pacotes Termux (pkg update && pkg upgrade -y)
 - exit                                 -> Fecha o painel atual

## Atalhos de Teclado no Tmux:
 (O prefixo padrão do Tmux foi alterado de Ctrl + b para Ctrl + a,
 além de permitir clicar diretamente nos painéis com o dedo)

 Ctrl + a seguido de |         -> Divide o painel verticalmente (lado a lado)
 Ctrl + a seguido de -        -> Divide o painel horizontalmente (em cima e embaixo)
 Ctrl + a seguido de r         -> Recarrega as configuracoes do ~/.tmux.conf
 Ctrl + c                              -> Finalização do processo.

## Acesso Remoto (Tailscale SSH):
(Disponível caso o usuário e IP do PC tenham sido informados durante a instalação)

 - mint                                ->  Acesso HOST remoto via SSH & Tailscale (ssh usuario@ip)
 - puxar <caminho>          -> Copia arquivos e/ou pastas do PC para diretório atual no Android via SCP

