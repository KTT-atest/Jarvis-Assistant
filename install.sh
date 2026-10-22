#!/bin/bash

# ─────────────────────────────────────────────────────
#  J.A.R.V.I.S. Universal Linux Installer
#  Supports: Fedora, Ubuntu/Debian, Arch, openSUSE
# ─────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

print_banner() {
    echo -e "${CYAN}"
    echo "     ██╗ █████╗ ██████╗ ██╗   ██╗██╗███████╗"
    echo "     ██║██╔══██╗██╔══██╗██║   ██║██║██╔════╝"
    echo "     ██║███████║██████╔╝██║   ██║██║███████╗"
    echo "██   ██║██╔══██║██╔══██╗╚██╗ ██╔╝██║╚════██║"
    echo "╚█████╔╝██║  ██║██║  ██║ ╚████╔╝ ██║███████║"
    echo " ╚════╝ ╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚══════╝"
    echo -e "${NC}"
    echo -e "${BOLD}  Universal Linux Voice Assistant Installer${NC}"
    echo -e "  ${BLUE}──────────────────────────────────────────${NC}"
    echo ""
}

ok()   { echo -e "  ${GREEN}✔${NC} $1"; }
info() { echo -e "  ${BLUE}→${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; }
fail() { echo -e "  ${RED}✘${NC} $1"; exit 1; }
ask()  { echo -e "  ${YELLOW}?${NC} $1"; read -r "$2"; }

print_banner

# ── Detect distro ─────────────────────────────────────────────────────────────
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DISTRO_ID="${ID,,}"
        DISTRO_LIKE="${ID_LIKE,,}"
    else
        fail "Cannot detect Linux distribution."
    fi

    if [[ "$DISTRO_ID" == "fedora" || "$DISTRO_LIKE" == *"fedora"* || "$DISTRO_LIKE" == *"rhel"* ]]; then
        DISTRO="fedora"
        PKG_MANAGER="dnf"
        INSTALL_CMD="sudo dnf install -y"
        PKGS="python3 python3-pip portaudio-devel espeak-ng wget unzip curl"
    elif [[ "$DISTRO_ID" == "ubuntu" || "$DISTRO_ID" == "debian" || "$DISTRO_LIKE" == *"debian"* || "$DISTRO_LIKE" == *"ubuntu"* ]]; then
        DISTRO="debian"
        PKG_MANAGER="apt"
        INSTALL_CMD="sudo apt install -y"
        PKGS="python3 python3-pip portaudio19-dev espeak-ng wget unzip curl"
    elif [[ "$DISTRO_ID" == "arch" || "$DISTRO_LIKE" == *"arch"* ]]; then
        DISTRO="arch"
        PKG_MANAGER="pacman"
        INSTALL_CMD="sudo pacman -S --noconfirm"
        PKGS="python python-pip portaudio espeak-ng wget unzip curl"
    elif [[ "$DISTRO_ID" == "opensuse"* || "$DISTRO_LIKE" == *"suse"* ]]; then
        DISTRO="opensuse"
        PKG_MANAGER="zypper"
        INSTALL_CMD="sudo zypper install -y"
        PKGS="python3 python3-pip portaudio-devel espeak-ng wget unzip curl"
    else
        warn "Distro '$DISTRO_ID' not officially supported."
        warn "Will attempt to continue — you may need to install dependencies manually."
        DISTRO="unknown"
        PKG_MANAGER="unknown"
        INSTALL_CMD=""
        PKGS=""
    fi

    ok "Detected: $PRETTY_NAME"
}

detect_distro

# ── Check sudo ────────────────────────────────────────────────────────────────
if ! sudo -v &>/dev/null; then
    fail "This installer requires sudo privileges."
fi

# ── Check Python version ──────────────────────────────────────────────────────
PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null)
PYTHON_MAJOR=$(echo "$PYTHON_VERSION" | cut -d. -f1)
PYTHON_MINOR=$(echo "$PYTHON_VERSION" | cut -d. -f2)

if [[ -z "$PYTHON_VERSION" ]]; then
    fail "Python 3 not found. Please install Python 3.8 or newer."
elif [[ "$PYTHON_MAJOR" -lt 3 || ( "$PYTHON_MAJOR" -eq 3 && "$PYTHON_MINOR" -lt 8 ) ]]; then
    fail "Python $PYTHON_VERSION detected. JARVIS requires Python 3.8 or newer."
else
    ok "Python $PYTHON_VERSION detected."
fi

# ── Gemini API key ────────────────────────────────────────────────────────────
echo ""
echo -e "  ${BOLD}Step 1 — Gemini API Key${NC}"
echo -e "  Get a free key at: ${CYAN}https://aistudio.google.com/app/apikey${NC}"
echo ""
ask "Paste your Gemini API key (or press Enter to skip):" GEMINI_KEY
if [[ -z "$GEMINI_KEY" ]]; then
    warn "No key entered. Add it later in ~/jarvis.py"
    GEMINI_KEY="YOUR_KEY_HERE"
fi

# ── System dependencies ───────────────────────────────────────────────────────
echo ""
echo -e "  ${BOLD}Step 2 — Installing system dependencies${NC}"

if [[ "$DISTRO" == "debian" ]]; then
    sudo apt update -q &>/dev/null
fi

if [[ -n "$INSTALL_CMD" ]]; then
    info "Installing packages via $PKG_MANAGER..."
    $INSTALL_CMD $PKGS &>/dev/null \
        && ok "System packages installed." \
        || warn "Some packages may have failed — continuing anyway."
else
    warn "Unknown distro — skipping system packages. Install manually: python3 pip portaudio espeak-ng wget unzip curl"
fi

# ── Python packages ───────────────────────────────────────────────────────────
echo ""
echo -e "  ${BOLD}Step 3 — Installing Python packages${NC}"
info "Installing vosk, sounddevice, requests, piper-tts..."

# Try with --break-system-packages first (needed on newer distros)
if pip install vosk sounddevice requests piper-tts \
    --break-system-packages -q 2>/dev/null; then
    ok "Python packages installed."
elif pip3 install vosk sounddevice requests piper-tts \
    --break-system-packages -q 2>/dev/null; then
    ok "Python packages installed via pip3."
elif python3 -m pip install vosk sounddevice requests piper-tts -q 2>/dev/null; then
    ok "Python packages installed via python3 -m pip."
else
    fail "Could not install Python packages. Try manually: pip install vosk sounddevice requests piper-tts"
fi

# ── Vosk model ────────────────────────────────────────────────────────────────
echo ""
echo -e "  ${BOLD}Step 4 — Vosk speech recognition model${NC}"
echo ""
echo -e "  ${YELLOW}Choose model size:${NC}"
echo "    1) Small  (~40 MB)  — faster, less accurate"
echo "    2) Large  (~1.8 GB) — slower to load, much more accurate"
echo ""
ask "Enter choice [1/2] (default: 1):" MODEL_CHOICE

mkdir -p ~/vosk-model
cd ~/vosk-model

if [[ "$MODEL_CHOICE" == "2" ]]; then
    MODEL_NAME="vosk-model-en-us-0.22"
    MODEL_URL="https://alphacephei.com/vosk/models/vosk-model-en-us-0.22.zip"
    info "Downloading large model (~1.8 GB)..."
else
    MODEL_NAME="vosk-model-small-en-us-0.15"
    MODEL_URL="https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip"
    info "Downloading small model (~40 MB)..."
fi

if [[ -d "$HOME/vosk-model/$MODEL_NAME" ]]; then
    ok "Vosk model already exists, skipping."
else
    wget -q --show-progress "$MODEL_URL" -O /tmp/vosk-model.zip \
        && unzip -q /tmp/vosk-model.zip -d ~/vosk-model/ \
        && rm /tmp/vosk-model.zip \
        && ok "Vosk model installed." \
        || fail "Failed to download Vosk model."
fi

# ── Piper JARVIS voice ────────────────────────────────────────────────────────
echo ""
echo -e "  ${BOLD}Step 5 — JARVIS voice model${NC}"
echo ""
echo -e "  ${YELLOW}Choose voice quality:${NC}"
echo "    1) Medium (~64 MB)  — good quality"
echo "    2) High   (~114 MB) — best quality (recommended)"
echo ""
ask "Enter choice [1/2] (default: 2):" VOICE_CHOICE

mkdir -p ~/piper-voices
cd ~/piper-voices

if [[ "$VOICE_CHOICE" == "1" ]]; then
    VOICE_FILE="jarvis-medium.onnx"
    VOICE_URL_BASE="https://huggingface.co/jgkawell/jarvis/resolve/main/en/en_GB/jarvis/medium"
else
    VOICE_FILE="jarvis-high.onnx"
    VOICE_URL_BASE="https://huggingface.co/jgkawell/jarvis/resolve/main/en/en_GB/jarvis/high"
fi

if [[ -f "$HOME/piper-voices/$VOICE_FILE" ]]; then
    ok "JARVIS voice already exists, skipping."
else
    info "Downloading JARVIS voice..."
    wget -q --show-progress "$VOICE_URL_BASE/$VOICE_FILE" -O ~/piper-voices/$VOICE_FILE \
        && wget -q "$VOICE_URL_BASE/$VOICE_FILE.json" -O ~/piper-voices/$VOICE_FILE.json \
        && ok "JARVIS voice installed." \
        || fail "Failed to download voice model."
fi

# ── Install jarvis.py ─────────────────────────────────────────────────────────
echo ""
echo -e "  ${BOLD}Step 6 — Installing JARVIS${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -f "$SCRIPT_DIR/jarvis.py" ]]; then
    fail "jarvis.py not found in $SCRIPT_DIR — make sure install.sh is in the same folder."
fi

cp "$SCRIPT_DIR/jarvis.py" ~/jarvis.py
sed -i "s|YOUR_KEY_HERE|$GEMINI_KEY|g" ~/jarvis.py
sed -i "s|vosk-model-small-en-us-0.15|$MODEL_NAME|g" ~/jarvis.py
sed -i "s|jarvis-high.onnx|$VOICE_FILE|g" ~/jarvis.py
ok "jarvis.py configured and installed to ~/jarvis.py"

# ── Autostart ─────────────────────────────────────────────────────────────────
echo ""
echo -e "  ${BOLD}Step 7 — Autostart on login${NC}"
echo ""
echo -e "  ${YELLOW}Choose autostart method:${NC}"
echo "    1) KDE autostart     (KDE Plasma)"
echo "    2) GNOME autostart   (GNOME / Ubuntu)"
echo "    3) systemd service   (any desktop, most reliable)"
echo "    4) Skip"
echo ""
ask "Enter choice [1/2/3/4]:" AUTOSTART_CHOICE

case "$AUTOSTART_CHOICE" in
    1)
        mkdir -p ~/.config/autostart
        cat > ~/.config/autostart/jarvis.desktop << DESKTOP
[Desktop Entry]
Type=Application
Name=JARVIS
Comment=JARVIS Voice Assistant
Exec=bash -c 'sleep 5 && python3 /home/$USER/jarvis.py'
Icon=utilities-terminal
Terminal=false
X-KDE-AutostartEnabled=true
DESKTOP
        ok "KDE autostart configured."
        ;;
    2)
        mkdir -p ~/.config/autostart
        cat > ~/.config/autostart/jarvis.desktop << DESKTOP
[Desktop Entry]
Type=Application
Name=JARVIS
Comment=JARVIS Voice Assistant
Exec=bash -c 'sleep 5 && python3 /home/$USER/jarvis.py'
Icon=utilities-terminal
Terminal=false
X-GNOME-Autostart-enabled=true
DESKTOP
        ok "GNOME autostart configured."
        ;;
    3)
        mkdir -p ~/.config/systemd/user
        cat > ~/.config/systemd/user/jarvis.service << SERVICE
[Unit]
Description=JARVIS Voice Assistant
After=graphical-session.target sound.target
Wants=sound.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /home/$USER/jarvis.py
Restart=on-failure
RestartSec=5
Environment=DISPLAY=:0
Environment=PULSE_RUNTIME_PATH=/run/user/$(id -u)/pulse

[Install]
WantedBy=default.target
SERVICE
        systemctl --user daemon-reload
        systemctl --user enable jarvis.service
        ok "systemd service configured and enabled."
        ;;
    *)
        info "Skipping autostart. Run manually with: python3 ~/jarvis.py"
        ;;
esac

# ── IPv6 fix ──────────────────────────────────────────────────────────────────
echo ""
echo -e "  ${BOLD}Step 8 — Network optimization${NC}"
ask "Disable IPv6? (fixes Gemini API timeouts on some networks) [y/N]:" IPV6_CHOICE
if [[ "$IPV6_CHOICE" =~ ^[Yy]$ ]]; then
    echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf &>/dev/null
    sudo sysctl -p &>/dev/null
    ok "IPv6 disabled."
else
    info "Skipping IPv6 fix."
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "  ${BLUE}──────────────────────────────────────────${NC}"
echo -e "  ${GREEN}${BOLD}Installation complete!${NC}"
echo ""
echo -e "  Run JARVIS with:"
echo -e "  ${CYAN}python3 ~/jarvis.py${NC}"
echo ""
echo -e "  Try saying: ${BOLD}\"JARVIS, check system health\"${NC}"
echo -e "  ${BLUE}──────────────────────────────────────────${NC}"
echo ""
