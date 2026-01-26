# 🍚 my-rice-glass: Configuração Hyprland (Wayland)

Este repositório contém os arquivos de configuração (dotfiles) para o meu ambiente de desktop no Linux, focado no gerenciador de janelas **Hyprland** (Wayland). A configuração é projetada para ser visualmente agradável, com efeitos de *blur* (glassmorphism) e integração de cores dinâmica.

## ⚙️ Componentes Principais

A "rice" (configuração visual) é construída em torno dos seguintes componentes principais:

| Componente | Função | Arquivos de Configuração |
| :--- | :--- | :--- |
| **Hyprland** | Gerenciador de Janelas (Tiling) | `hypr/hyprland.conf`, `hypr/colors.conf` |
| **Waybar** | Barra de Status | `waybar/config`, `waybar/style.css` |
| **Kitty** | Emulador de Terminal | `kitty/kitty.conf`, `kitty/colors.conf` |
| **Wofi** | Lançador de Aplicações | `wofi/style.css` |
| **SwayNC** | Central de Notificações | `swaync/config.json`, `swaync/style.css` |
| **Swww** | Gerenciador de Wallpaper | Integrado via `hypr/scripts/wallpaper.sh` |
| **Matugen** | Geração de Esquema de Cores | `matugen/config.toml` |
| **Hyprlock** | Bloqueio de Tela | `hypr/hyprlock.conf` |

## 🚀 Comandos e Atalhos de Sistema

O coração da interação com o sistema é o arquivo `hypr/hyprland.conf`, que define todos os atalhos de teclado. A tecla principal (`$mainMod`) é a tecla **SUPER** (também conhecida como `Win` ou `Meta`).

### 1. Menu de Energia e Controle do Sistema

O controle de energia e sessão é feito através de um **Submap** do Hyprland, que é ativado com `SUPER + X`.

| Ação | Atalho | Comando Executado | Observações |
| :--- | :--- | :--- | :--- |
| **Ativar Menu** | `SUPER + X` | `hyprctl dispatch submap power` | Exibe uma notificação com as opções. |
| **Desligar** | `P` (após `SUPER + X`) | `systemctl poweroff` | Desliga o computador. |
| **Reiniciar** | `R` (após `SUPER + X`) | `systemctl reboot` | Reinicia o computador. |
| **Bloquear Tela** | `L` (após `SUPER + X`) | `hyprlock` | Bloqueia a tela com o Hyprlock. |
| **Suspender** | `S` (após `SUPER + X`) | `systemctl suspend` | Coloca o computador em modo de suspensão. |
| **Encerrar Sessão** | `E` (após `SUPER + X`) | `hyprctl dispatch exit` | Sai do Hyprland (Logout). |
| **Cancelar Menu** | `Escape` (após `SUPER + X`) | `hyprctl dispatch submap reset` | Volta ao modo de atalhos normal. |

### 2. Troca de Wallpaper

A troca de papel de parede é automatizada e é um dos pontos chave desta configuração, pois ela dispara a atualização de cores de todo o sistema.

| Ação | Atalho | Script Executado | Observações |
| :--- | :--- | :--- | :--- |
| **Trocar Wallpaper** | `SUPER + W` | `~/.config/hypr/scripts/wallpaper.sh` | Seleciona um novo wallpaper (imagem ou vídeo) e atualiza as cores do sistema via Matugen. |

O script `wallpaper.sh` faz o seguinte:
1.  Seleciona um arquivo aleatório (imagem, GIF, MP4, MKV, WEBM) da pasta `wallpapers`.
2.  Se for um vídeo, gera um *thumbnail* estático para o Hyprlock e para a transição.
3.  Aplica o wallpaper usando `swww` (para imagens) ou `mpvpaper` (para vídeos).
4.  Executa o `matugen` para extrair as cores dominantes do novo wallpaper e aplicá-las a:
    *   Bordas de janelas do Hyprland.
    *   Waybar.
    *   Kitty (terminal).
    *   SwayNC (notificações).

### 3. Atalhos de Aplicações e Janelas

| Ação | Atalho | Comando/Programa |
| :--- | :--- | :--- |
| **Terminal** | `SUPER + Q` | `kitty` |
| **Navegador** | `SUPER + B` | `firefox` |
| **Gerenciador de Arquivos** | `SUPER + E` | `thunar` |
| **Lançador de Aplicações** | `SUPER + Space` | `wofi` |
| **Fechar Janela Ativa** | `SUPER + C` | `killactive,` |
| **Alternar Flutuante** | `SUPER + V` | `togglefloating,` |
| **Tela Cheia** | `SUPER + F` | `fullscreen` |

### 4. Capturas de Tela (Screenshots)

A configuração utiliza o `hyprshot` para capturas de tela.

| Ação | Atalho | Comando Executado |
| :--- | :--- | :--- |
| **Capturar Região** | `Print` | `hyprshot -m region --clipboard-only` |
| **Capturar Janela** | `SUPER + Print` | `hyprshot -m window` |
| **Capturar Tela Inteira** | `SHIFT + Print` | `hyprshot -m output` |

## 🛠️ Instalação Simplificada

Para replicar esta configuração, você precisará dos seguintes pacotes instalados:

*   **Gerenciador de Janelas:** `Hyprland`
*   **Barra de Status:** `Waybar`
*   **Lançador:** `Wofi`
*   **Bloqueio de Tela:** `Hyprlock`
*   **Wallpaper:** `swww` e `mpvpaper` (para vídeos)
*   **Cores Dinâmicas:** `matugen`
*   **Notificações:** `SwayNC`
*   **Utilitários:** `kitty`, `thunar`, `hyprshot`, `playerctl`, `brightnessctl`, `wpctl`

**Instalação com Script (Recomendado):**

1.  **Clone o repositório:**
    ```bash
    git clone https://github.com/Skymebr/my-rice-glass.git
    cd my-rice-glass
    ```
2.  **Instale as Dependências:**
    Certifique-se de que todos os pacotes listados acima (Hyprland, Waybar, Kitty, etc.) estejam instalados no seu sistema. O script **não** instala os pacotes, apenas configura os arquivos.
3.  **Execute o Script de Instalação:**
    O script irá criar os links simbólicos necessários na sua pasta `~/.config/` e corrigir o caminho do script de wallpaper no `hyprland.conf` automaticamente.
    ```bash
    chmod +x install.sh
    ./install.sh
    ```
4.  **Reinicie:**
    Após a execução, reinicie o Hyprland ou o computador para que as novas configurações entrem em vigor.

**Instalação Manual (Alternativa):**
Se preferir, você pode seguir os passos manuais de criação de links simbólicos e correção de caminho, conforme detalhado na seção anterior.

---
*README gerado por Manus AI em 26 de Janeiro de 2026.*
