# J.A.R.V.I.S. Voice Assistant

A JARVIS-style voice assistant for Linux.

## Features
- Wake word detection ("JARVIS")
- Offline speech recognition (Vosk)
- JARVIS voice (Piper TTS)
- AI fallback for unknown commands (Google Gemini)
- Real-time system awareness (CPU, RAM, battery, disk)
- Conversation memory
- Email, browser, system commands

## Requirements
```bash
sudo dnf install python3 python3-pip portaudio-devel espeak-ng
pip install vosk sounddevice requests piper-tts
```

## Setup
1. Download Vosk model: https://alphacephei.com/vosk/models
2. Download JARVIS voice: https://huggingface.co/jgkawell/jarvis
3. Get a free Gemini API key: https://aistudio.google.com/app/apikey
4. Add your key to `jarvis.py`
5. Run: `python3 jarvis.py`

## Voice Commands
- "JARVIS, shutdown / reboot / sleep"
- "JARVIS, volume up / down / mute"
- "JARVIS, open browser / terminal / gmail"
- "JARVIS, check system health"
- "JARVIS, what is using my RAM"
- "JARVIS, check status of [website]"
- Any question → answered by Gemini AI

## Credits
- Voice model: [jgkawell/jarvis](https://huggingface.co/jgkawell/jarvis)
- STT: [Vosk](https://alphacephei.com/vosk)
- TTS: [Piper](https://github.com/rhasspy/piper)
