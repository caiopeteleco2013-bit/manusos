#!/bin/bash

# Script de Pós-Instalação para ManusOS (Arch Linux)
# Focado em debloat, performance e personalização.

# --- Funções Auxiliares ---
log_info() { echo -e "\e[32m[INFO]\e[0m $1"; }
log_warn() { echo -e "\e[33m[WARN]\e[0m $1"; }
log_error() { echo -e "\e[31m[ERROR]\e[0m $1"; exit 1; }

confirm() {
    read -r -p "$1 [y/N]: " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            true
            ;;
        *) 
            false
            ;;
    esac
}

# --- 1. Atualização do Sistema ---
log_info "Atualizando o sistema..."
sudo pacman -Syu --noconfirm || log_error "Falha ao atualizar o sistema."

# --- 2. Instalação do AUR Helper (Paru) ---
log_info "Verificando e instalando Paru (AUR Helper)..."
if ! command -v paru &> /dev/null;
then
    log_info "Paru não encontrado. Instalando..."
    sudo pacman -S --needed --noconfirm base-devel git || log_error "Falha ao instalar dependências para Paru."
    git clone https://aur.archlinux.org/paru.git /tmp/paru || log_error "Falha ao clonar repositório do Paru."
    (cd /tmp/paru && makepkg -si --noconfirm) || log_error "Falha ao compilar e instalar Paru."
    rm -rf /tmp/paru
else
    log_info "Paru já está instalado."
fi

# --- 3. Debloat: Remoção de Pacotes Desnecessários ---
log_info "Iniciando processo de debloat. Isso removerá pacotes comuns que podem não ser necessários."
if confirm "Deseja remover pacotes de debloat (ex: alguns utilitários, jogos, etc.)?"; then
    # Lista de pacotes para remover (exemplo, pode ser expandida)
    DEBLOAT_PACKAGES=(
        'nano' # Exemplo: se o usuário prefere vim/neovim
        'vi' # Exemplo: se o usuário prefere neovim
        'man-db'
        'man-pages'
        'groff'
        'texinfo'
        'games'
        'gnome-calculator'
        'epiphany'
        'totem'
        'rhythmbox'
        'brasero'
        'baobab'
        'eog'
        'evince'
        'file-roller'
        'gedit'
        'gnome-disk-utility'
        'gnome-terminal'
        'yelp'
        'xterm'
        'gvim'
        'vim'
    )
    log_info "Removendo pacotes: ${DEBLOAT_PACKAGES[*]}"
    sudo pacman -Rns --noconfirm "${DEBLOAT_PACKAGES[@]}" || log_warn "Alguns pacotes de debloat podem não ter sido encontrados ou removidos."
    sudo pacman -Qtdq | sudo pacman -Rns --noconfirm - || log_warn "Falha ao remover dependências órfãs após debloat."
else
    log_info "Debloat ignorado."
fi

# --- 4. Instalação de Pacotes Essenciais e Ambiente Gráfico ---
log_info "Instalando pacotes essenciais e ambiente gráfico."

# Pacotes base (comuns a ambos os ambientes)
ESSENTIAL_PACKAGES=(
    'xorg-server'
    'xorg-xinit'
    'mesa'
    'xf86-video-intel' # Exemplo, ajustar para sua GPU
    'networkmanager'
    'network-manager-applet'
    'pulseaudio'
    'pulseaudio-alsa'
    'pavucontrol'
    'alsa-utils'
    'firefox'
    'neovim'
    'git'
    'htop'
    'btop'
    'fastfetch'
    'unzip'
    'zip'
    'wget'
    'curl'
    'bash-completion'
    'zsh'
    'ttf-dejavu'
    'ttf-liberation'
    'noto-fonts'
    'noto-fonts-emoji'
    'terminus-font'
    'dialog'
    'wpa_supplicant'
    'grub'
    'os-prober'
    'efibootmgr'
)

sudo pacman -S --needed --noconfirm "${ESSENTIAL_PACKAGES[@]}" || log_error "Falha ao instalar pacotes essenciais."

# Escolha do Ambiente Gráfico
PS3='Escolha seu ambiente gráfico: '
options=("KDE Plasma" "i3wm" "Nenhum (apenas CLI)")
select opt in "${options[@]}"
do
    case $opt in
        "KDE Plasma")
            log_info "Instalando KDE Plasma..."
            sudo pacman -S --needed --noconfirm plasma kde-applications sddm || log_error "Falha ao instalar KDE Plasma."
            sudo systemctl enable sddm
            break
            ;;
        "i3wm")
            log_info "Instalando i3wm..."
            sudo pacman -S --needed --noconfirm i3-wm i3status dmenu lightdm lightdm-gtk-greeter || log_error "Falha ao instalar i3wm."
            sudo systemctl enable lightdm
            break
            ;;
        "Nenhum (apenas CLI)")
            log_info "Nenhum ambiente gráfico será instalado."
            break
            ;;
        *)
            log_warn "Opção inválida. Por favor, escolha 1, 2 ou 3."
            ;;
    esac
done

log_info "Configurações básicas concluídas. A personalização será feita na próxima etapa."

# Tornar o script executável: chmod +x install_manusos.sh
# Executar: ./install_manusos.sh

# --- 5. Personalização do Shell (ZSH com Oh-My-Zsh) ---
log_info "Configurando ZSH e Oh-My-Zsh..."
if confirm "Deseja configurar ZSH como shell padrão e instalar Oh-My-Zsh?"; then
    chsh -s $(which zsh) || log_warn "Falha ao definir ZSH como shell padrão. Faça manualmente com 'chsh -s $(which zsh)'."
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || log_error "Falha ao instalar Oh-My-Zsh."
    else
        log_info "Oh-My-Zsh já está instalado."
    fi

    # Instalar plugins comuns (zsh-autosuggestions, zsh-syntax-highlighting)
    log_info "Instalando plugins ZSH..."
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions || log_warn "Falha ao instalar zsh-autosuggestions."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting || log_warn "Falha ao instalar zsh-syntax-highlighting."

    # Ativar plugins no .zshrc (se não estiverem lá)
    if [ -f "$HOME/.zshrc" ]; then
        sed -i 's/^plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc"
    fi

    log_info "ZSH e Oh-My-Zsh configurados. Reinicie o terminal para aplicar as mudanças."
else
    log_info "Configuração do ZSH ignorada."
fi

# --- 6. Instalação e Configuração do Terminal (Alacritty) ---
log_info "Instalando e configurando Alacritty..."
if confirm "Deseja instalar Alacritty como terminal padrão?"; then
    sudo pacman -S --needed --noconfirm alacritty || log_error "Falha ao instalar Alacritty."
    mkdir -p $HOME/.config/alacritty
    # Baixar uma configuração base do Catppuccin para Alacritty
    curl -o $HOME/.config/alacritty/alacritty.toml https://raw.githubusercontent.com/catppuccin/alacritty/main/catppuccin-mocha.toml || log_warn "Falha ao baixar configuração do Alacritty. Usando padrão."
    log_info "Alacritty instalado e configurado com tema Catppuccin Mocha."
else
    log_info "Instalação do Alacritty ignorada."
fi

# --- 7. Configuração do Neovim ---
log_info "Configurando Neovim..."
if confirm "Deseja configurar Neovim com uma configuração básica?"; then
    # Instalar dependências para Neovim (ex: ripgrep, fd)
    sudo pacman -S --needed --noconfirm ripgrep fd || log_warn "Falha ao instalar dependências do Neovim."
    
    # Exemplo de configuração básica (pode ser um link para dotfiles mais complexos)
    mkdir -p $HOME/.config/nvim
    echo "set number" > $HOME/.config/nvim/init.lua
    echo "set relativenumber" >> $HOME/.config/nvim/init.lua
    echo "set tabstop=4" >> $HOME/.config/nvim/init.lua
    echo "set shiftwidth=4" >> $HOME/.config/nvim/init.lua
    echo "set expandtab" >> $HOME/.config/nvim/init.lua
    echo "syntax enable" >> $HOME/.config/nvim/init.lua
    echo "colorscheme default" >> $HOME/.config/nvim/init.lua
    log_info "Neovim configurado com uma configuração básica."
else
    log_info "Configuração do Neovim ignorada."
fi

# --- 8. Temas, Ícones e Fontes (Catppuccin) ---
log_info "Aplicando temas, ícones e fontes (Catppuccin)..."
if confirm "Deseja instalar e aplicar o tema Catppuccin (GTK, ícones, fontes)?"; then
    # Instalar pacotes de tema, ícones e fontes
    sudo pacman -S --needed --noconfirm lxappearance qt5ct qt6ct || log_warn "Falha ao instalar ferramentas de tema."
    paru -S --noconfirm catppuccin-gtk-theme-mocha catppuccin-cursors-mocha catppuccin-fonts-mocha || log_warn "Falha ao instalar tema Catppuccin via AUR."
    
    # Configurar tema GTK (requer configuração manual via lxappearance ou gsettings para KDE)
    # Para KDE, o tema Catppuccin pode ser instalado via as configurações do sistema.
    # Para GTK, pode ser necessário definir manualmente ou via gsettings.
    # Exemplo para GTK (pode não funcionar em todos os DEs sem ajustes):
    # gsettings set org.gnome.desktop.interface gtk-theme 'Catppuccin-Mocha-Standard-Lavender-Dark'
    # gsettings set org.gnome.desktop.interface icon-theme 'Catppuccin-Mocha-Lavender'
    # gsettings set org.gnome.desktop.interface cursor-theme 'Catppuccin-Mocha-Lavender-Cursors'
    log_info "Tema Catppuccin instalado. Pode ser necessário aplicar manualmente via configurações do sistema (ex: 'lxappearance' para GTK, 'Configurações do Sistema' para KDE).
    As fontes Catppuccin também foram instaladas."
else
    log_info "Instalação de temas e fontes ignorada."
fi

# --- 9. Otimizações do Sistema ---
log_info "Aplicando otimizações básicas do sistema..."
if confirm "Deseja aplicar otimizações de kernel e serviços (ex: zram, swappiness)?"; then
    # Habilitar zram (se não estiver habilitado)
    if ! systemctl is-active --quiet zramswap.service; then
        log_info "Habilitando zram..."
        sudo pacman -S --noconfirm zram-generator || log_warn "Falha ao instalar zram-generator."
        echo "[zram0]\ncompression-algorithm = zstd\nmax-zram-size = 50%" | sudo tee /etc/systemd/zram-generator.conf > /dev/null
        sudo systemctl daemon-reload
        sudo systemctl start /dev/zram0
        log_info "Zram habilitado. Reinicie para efeito total."
    else
        log_info "Zram já está habilitado."
    fi

    # Ajustar swappiness
    log_info "Ajustando swappiness para 10..."
    echo "vm.swappiness=10" | sudo tee /etc/sysctl.d/99-swappiness.conf > /dev/null
    sudo sysctl -p /etc/sysctl.d/99-swappiness.conf

    log_info "Otimizações básicas aplicadas."
else
    log_info "Otimizações do sistema ignoradas."
fi

log_info "Script de pós-instalação da ManusOS concluído!"
log_info "Por favor, reinicie o sistema para que todas as mudanças tenham efeito completo."
