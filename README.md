# JARVIS Assistant

<div align="center">



<div align="center">
<pre>
     ██╗ █████╗ ██████╗ ██╗   ██╗██╗███████╗
     ██║██╔══██╗██╔══██╗██║   ██║██║██╔════╝
     ██║███████║██████╔╝██║   ██║██║███████╗
     A JARVIS-style offline voice assistant for Linux
██   ██║██╔══██║██╔══██╗╚██╗ ██╔╝██║╚════██║
╚█████╔╝██║  ██║██║  ██║ ╚████╔╝ ██║███████║
 ╚════╝ ╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚══════╝
</pre>

![Linux](https://img.shields.io/badge/Linux-Universal-blue?logo=linux)
![Python](https://img.shields.io/badge/Python-3.8+-green?logo=python)
![Gemini](https://img.shields.io/badge/AI-Google%20Gemini-orange?logo=google)
![License](https://img.shields.io/badge/License-MIT-purple)

</div>




  ---

## What is this?

JARVIS is an offline-capable voice assistant for Linux, inspired by the AI from Iron Man.

It listens for a wake word, recognizes your command, executes it locally whenever possible, and falls back to Google Gemini AI for commands it doesn't recognize — including queries requiring real system awareness.

---

## Features

- 🎙️ **Wake word detection** — Say "JARVIS" to activate.
- 🧠 **Offline speech recognition** via Vosk — no cloud speech-to-text.
- 🔊 **JARVIS voice** — Neural TTS trained on the actual Iron Man JARVIS voice.
- 🤖 **AI fallback** — Google Gemini handles unknown commands.
- 💻 **Full system awareness** — JARVIS knows your CPU, RAM, battery, disk, and running processes.
- 🧵 **Conversation memory** — Remembers context across commands in a session.
- ⚡ **Instant local commands** — Shutdown, reboot, volume, lock, and open apps.
- 📧 **Email support** — Opens Gmail compose and supports contacts.
- 🌐 **Smart web actions** — Opens URLs and checks website status.
- 🔒 **Private** — Speech recognition runs fully offline.

---

## Supported Linux Distributions

| Distribution | Status |
|---|---|
| Fedora / RHEL / CentOS | ✅ Fully supported |
| Ubuntu / Debian / Linux Mint | ✅ Fully supported |
| Arch Linux / Manjaro | ✅ Fully supported |
| openSUSE | ✅ Fully supported |
| Other Linux distributions | ⚠️ May work; manual dependency installation required |

---

## Quick Install

```bash
git clone https://github.com/KTT-atest/jarvis-assistant.git
cd jarvis-assistant
bash install.sh
```

The installer will:

1. Detect your Linux distribution automatically.
2. Ask for your Gemini API key.
3. Install system and Python dependencies.
4. Let you choose the Vosk model size (small: 40 MB or large: 1.8 GB).
5. Let you choose JARVIS voice quality (medium: 64 MB or high: 114 MB).
6. Configure autostart (KDE, GNOME, or systemd).
7. Optionally fix IPv6 issues for the Gemini API.


---

## Requirements

### Google Gemini API Key

Get a free Gemini API key from [Google AI Studio](https://aistudio.google.com/app/apikey).

The free tier provides up to 1,500 requests per day, subject to Google's current model-specific limits and usage policies.

### Manual Installation

If you prefer to install the dependencies manually:

**Fedora / RHEL / CentOS**

```bash
sudo dnf install python3 python3-pip portaudio-devel espeak-ng wget unzip curl
```

**Ubuntu / Debian / Linux Mint**

```bash
sudo apt install python3 python3-pip portaudio19-dev espeak-ng wget unzip curl
```

**Arch Linux / Manjaro**

```bash
sudo pacman -S python python-pip portaudio espeak-ng wget unzip curl
```

**Python packages (all distributions)**

```bash
pip install vosk sounddevice requests piper-tts --break-system-packages
```

---

## Voice Commands

### System Commands

| Voice command | Action |
|---|---|
| JARVIS, shutdown | Powers off the machine |
| JARVIS, reboot | Reboots the machine |
| JARVIS, sleep | Suspends the machine |
| JARVIS, lock | Locks the screen |
| JARVIS, volume up / down | Adjusts volume by 10% |
| JARVIS, mute | Toggles mute |

### Applications and Web

| Voice command | Action |
|---|---|
| JARVIS, open browser | Opens the browser |
| JARVIS, open terminal | Opens the terminal |
| JARVIS, open Gmail | Opens the Gmail inbox |
| JARVIS, compose email | Opens Gmail compose |
| JARVIS, open YouTube | Opens YouTube |
| JARVIS, check status of example.com | Checks the website's status |

### System Awareness

| Voice command | Action |
|---|---|
| JARVIS, check system health | Reads CPU, RAM, and disk usage |
| JARVIS, what is using my RAM | Lists top memory-consuming processes |
| JARVIS, how is my battery | Reports battery level |
| JARVIS, what is my CPU usage | Reports CPU load |
| JARVIS, kill Firefox | Terminates a process |

### AI Commands

Anything JARVIS doesn't recognize locally gets sent to Gemini AI.

Examples:

- "JARVIS, what is the capital of Japan?"
- "JARVIS, explain quantum computing."
- "JARVIS, what time is it in Tokyo?"
- "JARVIS, tell me a joke."

---

## Project Structure

```text
jarvis-assistant/
├── jarvis.py        # Main assistant script
├── install.sh        # Universal Linux installer
└── README.md         # Project documentation
```

> **Note:** Voice models and Vosk models are not included in the repository due to their size. The installer downloads them automatically.

---

## Configuration

Edit `jarvis.py` to customize JARVIS.

### Add Contacts for Email Commands

```python
CONTACTS = {
    "john": "john@example.com",
    "mom": "mom@example.com",
}
```

### Add Custom Local Commands

```python
COMMANDS = {
    "open spotify": "spotify &",
    "open files": "dolphin &",
}
```

### Change the Wake Word

```python
WAKE_WORDS = ["jarvis", "hey jarvis"]
 #For Technical reasons, it''s recommanded that you add; John, journalist, dumbass (yes unfortunatlly), because the small local model can confuse some Speech recognition commands
```

### Change Speech Speed

Adjust the `--length-scale` parameter in the `speak()` function.

```bash
--length-scale 0.85
```

A value of `0.85` makes speech approximately 15% faster than normal, while `1.0` is the default speed.

---

## Credits

| Component | Source |
|---|---|
| JARVIS voice model | [jgkawell/jarvis](https://huggingface.co/jgkawell/jarvis) on Hugging Face |
| Speech recognition | [Vosk](https://alphacephei.com/vosk) by Alpha Cephei |
| Text-to-speech | [Piper](https://github.com/rhasspy/piper) by Rhasspy |
| AI fallback | [Google Gemini API](https://aistudio.google.com) |

---

## License

This project is licensed under the MIT License.

---

<div align="center">

*"Shall I activate the suit, sir?"*

</div>
