import sounddevice as sd
import queue, json, subprocess, os, socket

# Force IPv4
_orig_getaddrinfo = socket.getaddrinfo
def _ipv4_only(host, port, family=0, *a, **kw):
    return _orig_getaddrinfo(host, port, socket.AF_INET, *a, **kw)
socket.getaddrinfo = _ipv4_only

from vosk import Model, KaldiRecognizer

WAKE_WORDS     = ["jarvis", "jonas", "davis", "travis", "friday"]
MODEL_PATH     = os.path.expanduser("~/vosk-model/vosk-model-small-en-us-0.15")
PIPER_MODEL    = os.path.expanduser("~/piper-voices/jarvis-high.onnx")
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "YOUR_KEY_HERE")
GEMINI_MODEL   = os.environ.get("GEMINI_MODEL", "gemini-3.5-flash-lite")

model = Model(MODEL_PATH)
rec   = KaldiRecognizer(model, 16000)
q     = queue.Queue()
is_speaking  = False
conversation = []  # memory: last 6 exchanges

COMMANDS = {
    "shutdown":      "systemctl poweroff",
    "shut down":     "systemctl poweroff",
    "reboot":        "systemctl reboot",
    "restart":       "systemctl reboot",
    "sleep":         "systemctl suspend",
    "lock":          "loginctl lock-session",
    "lock screen":   "loginctl lock-session",
    "volume up":     "wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%+",
    "volume down":   "wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%-",
    "mute":          "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
    "open browser":  "xdg-open https://google.com",
    "open terminal": "konsole",
    "open gmail":    "xdg-open https://mail.google.com",
    "compose email": "xdg-open 'https://mail.google.com/mail/?view=cm&fs=1'",
}

CONTACTS = {
    # "john": "john@example.com",
    # "mom":  "mom@example.com",
}

GEMINI_SYSTEM = """You are JARVIS, Tony Stark's AI assistant running on a Fedora Linux KDE laptop.
You are calm, professional and intelligent. Occasional dry wit is acceptable but keep it rare and subtle.
Prioritize being helpful, accurate and concise over being funny.
You have full awareness of the user's system via the context injected with each message.
When given a voice command, respond ONLY with a valid JSON object — no markdown, no extra text, no code fences.

JSON format:
{
  "action": "speak" | "run" | "open_url" | "run_and_speak",
  "value": "bash command or url (empty string if action is speak)",
  "speech": "what JARVIS says out loud — always 1 sentence, professional and concise"
}

Action types:
- "speak": just say something (facts, answers, information)
- "run": run a bash command silently
- "open_url": open a URL in the browser
- "run_and_speak": run bash command and speak its stdout output

Examples:
"check system health" -> {"action":"run_and_speak","value":"echo CPU: $(top -bn1 | grep 'Cpu(s)' | awk '{print $2}')% && echo RAM: $(free -h | awk '/^Mem/{print $3\"/\"$2}') && echo Disk: $(df -h / | awk 'NR==2{print $5}') used","speech":"Running diagnostics, sir."}
"what is using my ram" -> {"action":"run_and_speak","value":"ps aux --sort=-%mem | awk 'NR>1{print $11, $4\"%\"}' | head -5","speech":"Checking top memory processes, sir."}
"check status of roblox.com" -> {"action":"run_and_speak","value":"curl -s -o /dev/null -w 'HTTP %{http_code}' --max-time 5 https://roblox.com","speech":"Pinging roblox.com, sir."}
"what time is it" -> {"action":"run_and_speak","value":"date '+%H:%M'","speech":"Checking the time, sir."}
"open youtube" -> {"action":"open_url","value":"https://youtube.com","speech":"Opening YouTube, sir."}
"kill firefox" -> {"action":"run","value":"pkill firefox","speech":"Terminating Firefox, sir."}
"what is my battery" -> {"action":"speak","value":"","speech":"Based on system context, your battery is at the level shown above."}
"capital of france" -> {"action":"speak","value":"","speech":"Paris, sir."}"""


def get_system_context():
    try:
        cpu   = subprocess.check_output(
            "top -bn1 | grep 'Cpu(s)' | awk '{print $2}'",
            shell=True).decode().strip()
        ram   = subprocess.check_output(
            "free -h | awk '/^Mem/{print $3\"/\"$2}'",
            shell=True).decode().strip()
        disk  = subprocess.check_output(
            "df -h / | awk 'NR==2{print $4\" free\"}'",
            shell=True).decode().strip()
        batt  = subprocess.check_output(
            "cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo N/A",
            shell=True).decode().strip()
        batt_status = subprocess.check_output(
            "cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo N/A",
            shell=True).decode().strip()
        uptime = subprocess.check_output(
            "uptime -p", shell=True).decode().strip()
        top_cpu = subprocess.check_output(
            "ps aux --sort=-%cpu | awk 'NR>1{print $11}' | head -3 | tr '\\n' ','",
            shell=True).decode().strip()
        top_mem = subprocess.check_output(
            "ps aux --sort=-%mem | awk 'NR>1{print $11}' | head -3 | tr '\\n' ','",
            shell=True).decode().strip()
        net   = subprocess.check_output(
            "ip route get 1 2>/dev/null | grep -oP 'src \\K\\S+' || echo unknown",
            shell=True).decode().strip()
        return (f"CPU: {cpu}% | RAM: {ram} | Disk: {disk} | "
                f"Battery: {batt}% ({batt_status}) | Uptime: {uptime} | "
                f"Top CPU procs: {top_cpu} | Top RAM procs: {top_mem} | IP: {net}")
    except Exception as e:
        return f"System context unavailable: {e}"


piper_proc = None

def init_piper():
    global piper_proc
    print("Loading Piper voice model...")
    piper_proc = subprocess.Popen(
        ['piper', '--model', PIPER_MODEL, '--length-scale', '0.85',
         '--output-raw', '--quiet'],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL
    )
    print("Piper ready.")

def speak(text):
    global is_speaking, piper_proc
    is_speaking = True
    print(f"JARVIS: {text}")
    text = text.replace('"', '').replace("'", '').replace('`', '').strip()
    q.queue.clear()
    try:
        piper_proc.stdin.write((text + '\n').encode())
        piper_proc.stdin.flush()
        aplay = subprocess.Popen(
            ['aplay', '-r', '22050', '-f', 'S16_LE', '-t', 'raw', '-q', '-'],
            stdin=subprocess.PIPE
        )
        import time
        start = time.time()
        while True:
            chunk = piper_proc.stdout.read(4096)
            if not chunk:
                break
            aplay.stdin.write(chunk)
            if time.time() - start > 15:
                break
        aplay.stdin.close()
        aplay.wait()
    except Exception as e:
        print(f"Speak error: {e}")
        init_piper()
    q.queue.clear()
    is_speaking = False


def ask_gemini(prompt):
    import requests, json as _json
    global conversation

    # Build system context
    context = get_system_context()
    full_prompt = f"[System context: {context}]\nUser command: {prompt}"

    # Build message history for memory
    messages = conversation[-6:]  # keep last 6 exchanges
    messages.append({"role": "user", "parts": [{"text": full_prompt}]})

    try:
        response = requests.post(
            f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent?key={GEMINI_API_KEY}",
            json={
                "contents": messages,
                "generationConfig": {"maxOutputTokens": 200},
                "systemInstruction": {"parts": [{"text": GEMINI_SYSTEM}]}
            },
            timeout=15
        )
        raw = response.json()["candidates"][0]["content"]["parts"][0]["text"]
        raw = raw.strip().strip("```json").strip("```").strip()
        result = _json.loads(raw)
        print(f"Gemini action: {result}")

        # Save to conversation memory
        conversation.append({"role": "user", "parts": [{"text": full_prompt}]})
        conversation.append({"role": "model", "parts": [{"text": raw}]})
        if len(conversation) > 12:
            conversation = conversation[-12:]

        return result
    except Exception as e:
        print(f"Gemini error: {e}")
        return {"action": "speak", "value": "", "speech": "Reasoning systems unavailable, sir."}


def handle_email(command_text):
    if any(w in command_text for w in ["compose email", "new email", "write email"]):
        subprocess.Popen("xdg-open 'https://mail.google.com/mail/?view=cm&fs=1'", shell=True)
        speak("Opening compose window, sir.")
        return True
    if "email" in command_text:
        for name, address in CONTACTS.items():
            if name in command_text:
                url = f"https://mail.google.com/mail/?view=cm&fs=1&to={address}"
                subprocess.Popen(f"xdg-open '{url}'", shell=True)
                speak(f"Composing email to {name}, sir.")
                return True
        subprocess.Popen("xdg-open 'https://mail.google.com/mail/?view=cm&fs=1'", shell=True)
        speak("Opening compose window, sir.")
        return True
    return False


def execute(result):
    action = result.get("action", "speak")
    value  = result.get("value", "")
    speech = result.get("speech", "Done, sir.")

    if action == "speak":
        speak(speech)

    elif action == "run":
        speak(speech)
        subprocess.Popen(value, shell=True)

    elif action == "open_url":
        speak(speech)
        subprocess.Popen(f"xdg-open '{value}'", shell=True)

    elif action == "run_and_speak":
        speak(speech)
        try:
            output = subprocess.check_output(
                value, shell=True, timeout=10
            ).decode().strip()
            print(f"Output: {output}")
            speak(output)
        except Exception as e:
            speak("Command execution failed, sir.")


def handle(text):
    global is_speaking
    if is_speaking:
        return
    text = text.lower().strip()
    print(f"Heard: {text}")

    wake_found = any(w in text for w in WAKE_WORDS)
    if not wake_found:
        return

    command_text = text
    for w in WAKE_WORDS:
        command_text = command_text.replace(w, "").strip(" ,.")

    if not command_text:
        speak("Yes, sir?")
        return

    # Local commands — instant, no API call
    for keyword, action in COMMANDS.items():
        if keyword in command_text:
            subprocess.Popen(action, shell=True)
            speak("Done, sir.")
            return

    # Email handler
    if handle_email(command_text):
        return

    # Gemini with system context + memory
    print(f"Asking Gemini: {command_text}")
    speak("One moment.")
    result = ask_gemini(command_text)
    execute(result)


def callback(indata, frames, time, status):
    if not is_speaking:
        q.put(bytes(indata))

init_piper()
print("J.A.R.V.I.S. online.")
speak("All systems online. How can I assist you, sir?")

with sd.RawInputStream(samplerate=16000, blocksize=8000,
                        dtype="int16", channels=1, callback=callback):
    while True:
        data = q.get()
        if rec.AcceptWaveform(data):
            result = json.loads(rec.Result())
            text = result.get("text", "")
            if text:
                handle(text)
