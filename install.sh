#!/bin/bash

# ─────────────────────────────────────────
#  J.A.R.V.I.S. Installer for Fedora KDE
# ─────────────────────────────────────────

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
    echo -e "${BOLD}  Voice Assistant Installer for Fedora KDE${NC}"
    echo -e "  ${BLUE}────────────────────────────────────────${NC}"
    echo ""
}

ok()   { echo -e "  ${GREEN}✔${NC} $1"; }
info() { echo -e "  ${BLUE}→${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; }
fail() { echo -e "  ${RED}✘${NC} $1"; exit 1; }

ask() {
    echo -e "  ${YELLOW}?${NC} $1"
    read -r "$2"
}

print_banner

# ── Check Fedora ──────────────────────────────────────────────────────────────
if ! command -v dnf &>/dev/null; then
    fail "This installer is for Fedora Linux only."
fi
ok "Fedora detected."

# ── Ask for Gemini API key ────────────────────────────────────────────────────
echo ""
echo -e "  ${BOLD}Step 1 — Gemini API Key${NC}"
echo -e "  Get a free key at: ${CYAN}https://aistudio.google.com/app/apikey${NC}"
echo ""
ask "Paste your Gemini API key:" GEMINI_KEY
if [[ -z "$GEMINI_KEY" ]]; then
    warn "No key entered. You can add it later in ~/jarvis.py"
    GEMINI_KEY="YOUR_KEY_HERE"
fi

# ── System dependencies ───────────────────────────────────────────────────────
echo ""
echo -e "  ${BOLD}Step 2 — Installing system dependencies${NC}"
info "Running dnf install..."
sudo dnf install -y python3 python3-pip portaudio-devel espeak-ng wget unzip curl \
    &>/dev/null && ok "System packages installed." || fail "dnf install failed."

# ── Python packages ───────────────────────────────────────────────────────────
echo ""
echo -e "  ${BOLD}Step 3 — Installing Python packages${NC}"
pip install vosk sounddevice requests piper-tts --break-system-packages -q \
    && ok "Python packages installed." || fail "pip install failed."

# ── Vosk model ────────────────────────────────────────────────────────────────
echo ""
echo -e "  ${BOLD}Step 4 — Downloading Vosk speech recognition model${NC}"
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
    info "Downloading large model (~1.8 GB) — this will take a while..."
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
echo -e "  ${BOLD}Step 5 — Downloading JARVIS voice model${NC}"
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
    fail "jarvis.py not found in $SCRIPT_DIR — make sure install.sh is in the same folder as jarvis.py"
fi

cp "$SCRIPT_DIR/jarvis.py" ~/jarvis.py

# Inject API key and model paths
sed -i "s|YOUR_KEY_HERE|$GEMINI_KEY|g" ~/jarvis.py
sed -i "s|vosk-model-small-en-us-0.15|$MODEL_NAME|g" ~/jarvis.py
sed -i "s|jarvis-high.onnx|$VOICE_FILE|g" ~/jarvis.py

ok "jarvis.py installed to ~/jarvis.py"

# ── Autostart ─────────────────────────────────────────────────────────────────
echo ""
echo -e "  ${BOLD}Step 7 — Autostart on login${NC}"
ask "Start JARVIS automatically on login? [y/N]:" AUTOSTART

if [[ "$AUTOSTART" =~ ^[Yy]$ ]]; then
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
    ok "Autostart configured."
else
    info "Skipping autostart. Run manually with: python3 ~/jarvis.py"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "  ${BLUE}────────────────────────────────────────${NC}"
echo -e "  ${GREEN}${BOLD}Installation complete!${NC}"
echo ""
echo -e "  Run JARVIS with:"
echo -e "  ${CYAN}python3 ~/jarvis.py${NC}"
echo ""
echo -e "  Say ${BOLD}\"JARVIS, what is my RAM usage\"${NC} to test."
echo -e "  ${BLUE}────────────────────────────────────────${NC}"
echo ""
