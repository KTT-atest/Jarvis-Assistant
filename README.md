<div align="center">
 ██╗ █████╗ ██████╗ ██╗   ██╗██╗███████╗
 ██║██╔══██╗██╔══██╗██║   ██║██║██╔════╝
 ██║███████║██████╔╝██║   ██║██║███████╗

██ ██║██╔══██║██╔══██╗╚██╗ ██╔╝██║╚════██║
╚█████╔╝██║ ██║██║ ██║ ╚████╔╝ ██║███████║
╚════╝ ╚═╝ ╚═╝╚═╝ ╚═╝ ╚═══╝ ╚═╝╚══════╝


**A JARVIS-style offline voice assistant for Linux**

![Linux](https://img.shields.io/badge/Linux-Universal-blue?logo=linux)
![Python](https://img.shields.io/badge/Python-3.8+-green?logo=python)
![Gemini](https://img.shields.io/badge/AI-Google%20Gemini-orange?logo=google)
![License](https://img.shields.io/badge/License-MIT-purple)

</div>

---

## What is this?

JARVIS is a fully offline-capable voice assistant for Linux, inspired by the AI from Iron Man. It listens for a wake word, recognizes your command, executes it locally if possible, and falls back to Google Gemini AI for anything it doesn't know — including real system awareness.

---

## Features

- 🎙️ **Wake word detection** — say "JARVIS" to activate
- 🧠 **Offline speech recognition** via Vosk — no cloud STT
- 🔊 **JARVIS voice** — neural TTS trained on the actual Iron Man JARVIS voice
- 🤖 **AI fallback** — Google Gemini handles unknown commands
- 💻 **Full system awareness** — JARVIS knows your CPU, RAM, battery, disk, running processes
- 🧵 **Conversation memory** — remembers context across commands in a session
- ⚡ **Instant local commands** — shutdown, reboot, volume, lock, open apps
- 📧 **Email support** — opens Gmail compose window, supports contacts
- 🌐 **Smart web actions** — opens URLs, checks website status
- 🔒 **Private** — speech recognition runs fully offline

---

## Supported Distros

| Distro | Status |
|--------|--------|
| Fedora / RHEL / CentOS | ✅ Fully supported |
| Ubuntu / Debian / Mint | ✅ Fully supported |
| Arch / Manjaro | ✅ Fully supported |
| openSUSE | ✅ Fully supported |
| Other Linux | ⚠️ May work, manual dependency install needed |

---

## Quick Install

```bash
git clone https://github.com/YOUR_USERNAME/jarvis-assistant
cd jarvis-assistant
bash install.sh
```

The installer will:
1. Detect your Linux distro automatically
2. Ask for your Gemini API key
3. Install all system and Python dependencies
4. Let you choose Vosk model size (small 40MB or large 1.8GB)
5. Let you choose JARVIS voice quality (medium 64MB or high 114MB)
6. Configure autostart (KDE, GNOME, or systemd)
7. Optionally fix IPv6 issues for Gemini API

---

## Requirements

### Get a free Gemini API key
Go to https://aistudio.google.com/app/apikey — free tier gives 1,500 requests/day.

### Manual install (if you prefer)
```bash
# Fedora
sudo dnf install python3 python3-pip portaudio-devel espeak-ng wget unzip curl

# Ubuntu / Debian
sudo apt install python3 python3-pip portaudio19-dev espeak-ng wget unzip curl

# Arch
sudo pacman -S python python-pip portaudio espeak-ng wget unzip curl

# Python packages (all distros)
pip install vosk sounddevice requests piper-tts --break-system-packages
```

---

## Voice Commands

### System
| Say | Action |
|-----|--------|
| JARVIS, shutdown | Powers off the machine |
| JARVIS, reboot | Reboots the machine |
| JARVIS, sleep | Suspends the machine |
| JARVIS, lock | Locks the screen |
| JARVIS, volume up / down | Adjusts volume by 10% |
| JARVIS, mute | Toggles mute |

### Apps & Web
| Say | Action |
|-----|--------|
| JARVIS, open browser | Opens browser |
| JARVIS, open terminal | Opens terminal |
| JARVIS, open gmail | Opens Gmail inbox |
| JARVIS, compose email | Opens Gmail compose |
| JARVIS, open YouTube | Opens YouTube |
| JARVIS, check status of roblox.com | Pings the site |

### System Awareness
| Say | Action |
|-----|--------|
| JARVIS, check system health | Reads CPU, RAM, disk |
| JARVIS, what is using my RAM | Lists top memory processes |
| JARVIS, how is my battery | Reports battery level |
| JARVIS, what is my CPU usage | Reports CPU load |
| JARVIS, kill firefox | Kills a process |

### AI (anything else)
Anything JARVIS doesn't recognize locally gets sent to Gemini AI:
- "JARVIS, what is the capital of Japan"
- "JARVIS, explain quantum computing"
- "JARVIS, what time is it in Tokyo"
- "JARVIS, tell me a joke"

---

## Project Structure

jarvis-assistant/
├── jarvis.py # Main assistant script
├── install.sh # Universal Linux installer
└── README.md # This file


> **Note:** Voice models and Vosk models are not included in the repo due to size.
> The installer downloads them automatically.

---

## Configuration

Edit `~/jarvis.py` to customize:

```python
# Add contacts for email commands
CONTACTS = {
    "john": "john@example.com",
    "mom":  "mom@example.com",
}

# Add custom local commands
COMMANDS = {
    "open spotify": "spotify &",
    "open files":   "dolphin &",
}

# Change wake word
WAKE_WORDS = ["jarvis", "hey jarvis"]

# Change speech speed (0.85 = 15% faster, 1.0 = normal)
# --length-scale 0.85 in the speak() function
```

---

## Credits

| Component | Source |
|-----------|--------|
| JARVIS voice model | [jgkawell/jarvis](https://huggingface.co/jgkawell/jarvis) on HuggingFace |
| Speech recognition | [Vosk](https://alphacephei.com/vosk) by Alpha Cephei |
| Text to speech | [Piper](https://github.com/rhasspy/piper) by rhasspy |
| AI fallback | [Google Gemini API](https://aistudio.google.com) |

---

## License

MIT — do whatever you want with it.

---

<div align="center">
<i>"Shall I activate the suit, sir?"</i>
</div>
