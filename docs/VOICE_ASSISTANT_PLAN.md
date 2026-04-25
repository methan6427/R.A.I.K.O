# R.A.I.K.O Voice Assistant Implementation Plan

**Status:** Planning phase  
**Voice Model:** en_US-ryan-high (Piper TTS)  
**Offline LLM:** Gemma 3 1B via MediaPipe AI Edge  
**Activation:** Always-listening wake word "Raiko" + manual tap  
**Scope:** Device control only (lock, sleep, restart, shutdown, open_app)

---

## Architecture Overview

```
┌─ Mobile (Flutter) ────────────────────────────────────────────┐
│                                                               │
│  Porcupine Wake Word Detector (always on, ~1% CPU)          │
│    ↓ hears "Raiko" OR user taps orb                         │
│  Whisper Tiny STT (on-device, 39MB)                         │
│    ↓ "lock the laptop"                                       │
│  Gemma 3 1B LLM (on-device, 600MB)                          │
│    ↓ intent parsing                                          │
│  Extract: {command: "lock", target: "laptop"}               │
│    ↓                                                          │
│  RaikoWsClient.sendCommand() → agent executes               │
│    ↓                                                          │
│  Generate response text (if confirm_before_execute = true)   │
│    ↓                                                          │
│  POST /tts with response → Backend                           │
│                                                               │
└───────────────────────────────────────────────────────────────┘
                            ↓
┌─ Backend (Node) ──────────────────────────────────────────────┐
│                                                               │
│  POST /tts endpoint                                          │
│    ↓ receive text (e.g. "Locking the laptop, Sir")          │
│  Piper TTS (en_US-ryan-high) generates MP3 audio            │
│    ↓                                                          │
│  Stream audio back to mobile                                │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Core Voice Engine

### 1.1 Mobile — Wake Word & Tap Detection

**File:** `apps/mobile/lib/src/core/voice/raiko_wake_word_detector.dart`

```dart
class RaikoWakeWordDetector {
  // Porcupine access key from picovoice.ai console (free tier)
  final String porcupineAccessKey;
  
  // Porcupine detects "Raiko" at 0.5s latency, ~1% CPU
  // User taps RaikoVoiceOrb → manual activation
  
  Future<void> startListening() async;
  Future<void> stopListening() async;
  
  // Callbacks
  Stream<bool> get onWakeWordDetected; // true = "Raiko" heard
  Stream<bool> get onManualActivation;  // true = orb tapped
}
```

**Package:** `porcupine_flutter` (pub.dev)
- Access key: generated free from picovoice.ai console
- Custom "Raiko" wake word model: trained once on their console (upload audio samples of you saying "Raiko", they return a .ppn model file)

### 1.2 Mobile — Speech-to-Text

**File:** `apps/mobile/lib/src/core/voice/raiko_speech_to_text.dart`

```dart
class RaikoSpeechToText {
  // Whisper tiny model (39MB, downloads on first run)
  Future<String> transcribe() async {
    // Records 5 seconds of audio (timeout configurable in settings)
    // Returns: "lock the laptop"
  }
}
```

**Package:** `whisper_flutter` (pub.dev)
- Model size: tiny (39MB, good for device control accuracy)
- Download happens on first use, cached locally

### 1.3 Mobile — Intent Parser (LLM)

**File:** `apps/mobile/lib/src/core/voice/raiko_intent_parser.dart`

```dart
class RaikoIntentParser {
  // Gemma 3 1B loaded in memory (600MB, downloads on first run)
  Future<RaikoIntent> parse(
    String transcribedText,
    List<RaikoAgentInfo> connectedAgents,
    String userName,
  ) async {
    // Send to Gemma 3 1B with locked system prompt
    // Returns: {command: "lock", targetAgent: "laptop-01", confidence: 0.95}
  }
}

class RaikoIntent {
  String command;      // lock | sleep | restart | shutdown | open_app
  String targetAgent;  // which agent to target
  double confidence;   // 0.0-1.0
  String? args;        // for open_app, the app name
}
```

**Package:** MediaPipe/Google AI Edge Flutter SDK (google_generative_ai or media_pipe_core)
- Model: Gemma 3 1B (600MB)
- System prompt (locked, user cannot modify):
  ```
  You are R.A.I.K.O, an AI operations assistant.
  
  Connected agents: {agent_list}
  User name: {user_name}
  
  Your role: Parse device control commands.
  Available commands: lock, sleep, restart, shutdown, open_app
  
  When the user says a command, respond ONLY with:
  COMMAND: <command>
  TARGET: <agent_name or "all">
  CONFIDENCE: <0.0-1.0>
  
  If confidence < 0.7 or unclear, respond:
  COMMAND: ask_clarification
  
  Examples:
  "lock the laptop" → COMMAND: lock / TARGET: laptop-01 / CONFIDENCE: 0.95
  "put all devices to sleep" → COMMAND: sleep / TARGET: all / CONFIDENCE: 0.9
  "restart my desktop" → COMMAND: restart / TARGET: desktop-windows-01 / CONFIDENCE: 0.92
  "open spotify on the desktop" → COMMAND: open_app / TARGET: desktop-windows-01 / CONFIDENCE: 0.88
  "what time is it" → COMMAND: ask_clarification / (not a device control command)
  ```

### 1.4 Mobile — Voice Engine Orchestration

**File:** `apps/mobile/lib/src/core/voice/raiko_voice_engine.dart`

```dart
class RaikoVoiceEngine extends ChangeNotifier {
  // Orchestrates the full flow
  
  RaikoVoiceState state; // idle | listening | processing | speaking | error
  
  Future<void> activate() async {
    // 1. Start wake word listener (always on in background)
    // 2. When triggered, record audio
    // 3. Transcribe with Whisper
    // 4. Parse intent with Gemma 3 1B
    // 5. If valid command: show confirmation (if enabled in settings)
    // 6. Send command to agent
    // 7. Get response text
    // 8. Call /tts backend endpoint
    // 9. Play audio
  }
  
  Stream<RaikoVoiceState> get stateStream;
  Stream<String> get responsesStream;
}

enum RaikoVoiceState {
  idle,           // waiting for wake word
  listening,      // recording user audio
  processing,     // transcribing + parsing
  confirming,     // waiting for user to approve (if confirm enabled)
  executing,      // sending command to agent
  speaking,       // playing response audio
  error,          // something went wrong
}
```

### 1.5 Mobile — Settings for Voice Assistant

**File:** `apps/mobile/lib/src/features/voice/voice_settings.dart`

New settings screen with:

| Setting | Type | Default | Notes |
|---------|------|---------|-------|
| `confirmBeforeExecute` | bool | `true` | If true: "Locking the laptop, Sir." then execute. If false: silent execute + haptic |
| `userName` | String | "Sir" | Learned via voice command "Raiko, my name is Adam" or manual entry |
| `voiceVolume` | double | 0.8 | TTS volume |
| `listeningTimeout` | int | 10 | seconds to listen before auto-stop |
| `wakeWordSensitivity` | double | 0.5 | Porcupine threshold (0.0-1.0) |
| `enableWakeWord` | bool | `true` | Toggle always-listening |

**Learning the user name:**
- Voice command: User says "Raiko, my name is Adam" → parsed by LLM
- LLM responds with: `COMMAND: set_name / VALUE: adam`
- App saves to `RaikoSettingsStore`
- Subsequent responses use this name

---

## Phase 2: Backend TTS Endpoint

### 2.1 Backend — Piper TTS Route

**File:** `apps/backend/src/modules/tts/tts.controller.ts`

```typescript
@Post('/tts')
async textToSpeech(@Body() body: { text: string }) {
  // 1. Run: piper --model en_US-ryan-high.onnx --output_file=/tmp/out.wav <<< "{text}"
  // 2. Read /tmp/out.wav
  // 3. Return: { audio: base64, mimeType: 'audio/wav' }
  // Response time: ~500ms for typical sentence
}
```

**Docker changes:**
```dockerfile
# Add Piper to runtime stage
RUN apk add --no-cache piper \
 && wget -q https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/ryan/high/en_US-ryan-high.onnx \
      -O /opt/piper/voices/en_US-ryan-high.onnx
```

**Text handling for TTS:**
- Write "Raiko" not "R.A.I.K.O" (no dots, so TTS reads it as a word not letters)
- Responses: `"Raiko online. All systems nominal, Sir."` → spoken fluently

---

## Phase 3: UI Integration

### 3.1 Voice Console (Existing RaikoVoiceOrb)

Update the `RaikoVoiceOrb` widget to show voice assistant state:

```dart
RaikoVoiceOrb(
  isActive: client.isConnected,
  state: voiceEngine.state,  // idle | listening | processing | speaking
  onPressed: () => voiceEngine.activate(), // Manual tap
)
```

Visual feedback:
- **Idle:** Pulsing blue glow (already exists)
- **Listening:** Animated waveform, red outline
- **Processing:** Spinner, yellow outline
- **Speaking:** Audio waveform animating in real-time
- **Error:** Red X, shows error message in snackbar

### 3.2 Voice Response Widget

```dart
// Shows the flow to user:
// 1. "You said: 'lock the laptop'"
// 2. "Parsed: lock [laptop-01]"
// 3. "Confirming... Locking the laptop, Sir."  ← audio plays
// 4. Success visual feedback
```

### 3.3 Settings Tab — Voice Settings

Add a **Voice Assistant** section below Device Identity:

```
┌─ Voice Assistant ──────────────────────────────┐
│ ✓ Enable wake word "Raiko"                    │
│ ✓ Confirm before executing commands           │
│ 🎙️ Your name: "Adam"  [Edit]                  │
│ 🎚️ Listening timeout: 10s                      │
│ 🎚️ Wake word sensitivity: ●─────              │
│                                                │
│ [Test Voice] [Clear Settings]                 │
└────────────────────────────────────────────────┘
```

---

## System Prompts & Responses

### Startup Message

**Text:** `"Raiko online. All systems nominal, Sir."`  
**Pronunciation:** Raiko (word, not letters)  
**Timing:** Played once when app launches and backend connects  

### Confirmation Responses (if enabled)

| Command | Response |
|---------|----------|
| lock [agent] | "Locking the [agent name], Sir." |
| sleep [agent] | "Putting [agent name] to sleep, Sir." |
| restart [agent] | "Restarting [agent name], Sir." |
| shutdown [agent] | "Shutting down [agent name], Sir." |
| open_app [app] on [agent] | "Opening [app] on [agent name], Sir." |

If user name is "Adam":
- Replace "Sir" with "Adam" in responses
- Example: `"Locking the laptop, Adam."` instead of `"Locking the laptop, Sir."`

### Error Responses

| Error | Response |
|-------|----------|
| No agents connected | "No agents are currently online, Sir." |
| Agent not found | "I couldn't find [agent name]. Which agent did you mean?" |
| Low confidence parse | "Could you please repeat that? I didn't quite understand." |
| Command failed | "The command failed. The [agent name] may be offline." |

---

## Build Phases & Timeline

### Phase 1: Core Voice (Weeks 1-2)
- [ ] Porcupine wake word setup (picovoice.ai account, train "Raiko")
- [ ] Whisper Tiny integration
- [ ] Gemma 3 1B MediaPipe integration
- [ ] Basic voice engine orchestration
- [ ] Manual tap-to-talk only (no wake word yet)
- [ ] Test with device control commands

### Phase 2: Backend TTS (Week 2)
- [ ] Piper TTS endpoint
- [ ] Docker Piper + voice model
- [ ] Audio streaming to mobile

### Phase 3: UI & Settings (Week 3)
- [ ] Voice state indicators on RaikoVoiceOrb
- [ ] Voice settings screen
- [ ] User name learning via voice command
- [ ] Confirmation toggle

### Phase 4: Polish (Week 4)
- [ ] Wake word detection enabled
- [ ] Haptic feedback
- [ ] Error handling & recovery
- [ ] Performance optimization (memory, battery)
- [ ] User testing

### Phase 5: Remote Desktop Control (Week 5)
- [ ] RustDesk daemon setup on each agent device
- [ ] Flutter VNC client integration
- [ ] Embedded remote desktop viewer in app
- [ ] Agent config support for RustDesk ID
- [ ] Backend agent registration with RustDesk ID
- [ ] "Remote Control" button on agent cards
- [ ] Full-screen remote control UI

---

## Phase 5: Remote Desktop Control via RustDesk

### 5.1 Architecture

```
Windows/Mac/Linux Agent
  ↓
Runs RustDesk daemon (headless, unattended access enabled)
  ↓
config.json stores: rustDeskId: "123456789"
  ↓
Agent registers with backend: 
    {agentId: "...", rustDeskId: "123456789", ...}
  ↓
Backend stores rustDeskId in agent record
  ↓
Mobile app displays agent card with "Remote Control" button
  ↓
User taps → Flutter VNC client connects to agent
  ↓
Full remote desktop control (mouse, keyboard, screen view)
```

### 5.2 Agent Setup (Windows/Mac/Linux)

**RustDesk Configuration:**

1. Install RustDesk on the device (free download)
2. Enable unattended access:
   - RustDesk settings → Enable permanent password
   - Note the RustDesk ID (e.g., 123456789)

3. Update agent config.json:
   ```json
   {
     "backendWsUrl": "ws://...",
     "authToken": "...",
     "agentName": "Adam's Laptop",
     "rustDeskId": "123456789",
     "rustDeskPassword": "permanent_password_set_in_rustdesk"
   }
   ```

4. Agent sends RustDesk ID on registration:
   ```typescript
   // backend receives:
   {
     agentId: "agent-adams-laptop",
     name: "Adam's Laptop",
     rustDeskId: "123456789",
     ...
   }
   ```

### 5.3 Backend — Store RustDesk ID

**Agent Model Update:**

```typescript
interface Agent {
  id: string;
  name: string;
  platform: string;
  status: 'online' | 'offline';
  rustDeskId?: string;  // NEW
  rustDeskPassword?: string;  // NEW (encrypted)
  lastSeen: Date;
}
```

**Agent Registration Endpoint** (existing, add fields):
```typescript
POST /api/agents/register
{
  agentId: "...",
  name: "...",
  platform: "windows",
  rustDeskId: "123456789",      // NEW
  rustDeskPassword: "xyz123",   // NEW (should be encrypted)
  ...
}
```

### 5.4 Mobile — VNC Client Integration

**File:** `apps/mobile/lib/src/features/remote_desktop/remote_desktop_viewer.dart`

```dart
class RemoteDesktopViewer extends StatefulWidget {
  final RaikoAgentInfo agent;
  final String rustDeskId;
  final String rustDeskPassword;

  @override
  State<RemoteDesktopViewer> createState() => _RemoteDesktopViewerState();
}

class _RemoteDesktopViewerState extends State<RemoteDesktopViewer> {
  late VncViewerController vncController;
  
  @override
  void initState() {
    super.initState();
    // Connect to RustDesk VNC server
    // RustDesk runs VNC on port 5900 by default
    vncController.connect(
      host: widget.rustDeskId,  // RustDesk ID acts as hostname
      port: 5900,
      password: widget.rustDeskPassword,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.agent.name} — Remote Control')),
      body: VncViewer(
        controller: vncController,
        // Supports mouse, keyboard, gestures
      ),
    );
  }
}
```

**Flutter Packages:**
- `flutter_vnc` or `vnc_client_flutter` (pub.dev) — pure Dart VNC client
- Supports mouse movement, clicks, keyboard input
- Real-time screen updates

### 5.5 Mobile — Agent Card UI

**Update DevicesTab:**

```dart
// Existing card with new button
Row(
  children: [
    Expanded(
      child: RaikoButton(
        label: 'Lock',
        onPressed: () => client.sendCommand('lock', agentId),
      ),
    ),
    SizedBox(width: 12),
    Expanded(
      child: RaikoButton(
        label: agent.rustDeskId != null ? 'Remote Control' : 'No RD',
        icon: Icons.desktop_mac_rounded,
        isSecondary: true,
        onPressed: agent.rustDeskId != null
            ? () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RemoteDesktopViewer(
                  agent: agent,
                  rustDeskId: agent.rustDeskId!,
                  rustDeskPassword: agent.rustDeskPassword,
                ),
              ),
            )
            : null,  // Disabled if no RustDesk ID
      ),
    ),
  ],
)
```

### 5.6 Full-Screen Remote Control UI

**File:** `apps/mobile/lib/src/features/remote_desktop/remote_desktop_screen.dart`

```dart
class RemoteDesktopScreen extends StatefulWidget {
  final RaikoAgentInfo agent;

  @override
  State<RemoteDesktopScreen> createState() => _RemoteDesktopScreenState();
}

class _RemoteDesktopScreenState extends State<RemoteDesktopScreen> {
  late VncViewerController _vncController;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _vncController = VncViewerController(
      host: widget.agent.rustDeskId!,
      port: 5900,
      password: widget.agent.rustDeskPassword ?? '',
    );
    _vncController.connect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.agent.name),
        actions: [
          IconButton(
            icon: Icon(_showControls ? Icons.expand : Icons.unfold_more),
            onPressed: () => setState(() => _showControls = !_showControls),
          ),
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Full-screen remote desktop view
          VncViewer(
            controller: _vncController,
            backgroundColor: Colors.black,
            onConnected: () => print('Connected to ${widget.agent.name}'),
            onDisconnected: () => Navigator.of(context).pop(),
          ),
          
          // Floating control panel (if visible)
          if (_showControls)
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                tooltip: 'Show/hide controls',
                child: Icon(Icons.touch_app),
                onPressed: () => setState(() => _showControls = false),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _vncController.disconnect();
    super.dispose();
  }
}
```

### 5.7 Voice Command Integration

Extend the voice intent parser to recognize remote desktop commands:

```dart
// System prompt addition:
"""
ADDITIONAL COMMANDS:
- open_remote: "open remote control on [agent]" → open RemoteDesktopScreen
- Example: "Raiko, open remote control on my laptop" 
  → COMMAND: open_remote / TARGET: laptop-01 / CONFIDENCE: 0.92
"""
```

Handle in voice engine:
```dart
if (intent.command == 'open_remote') {
  if (agent.rustDeskId == null) {
    // Respond: "No remote desktop configured for [agent name]"
  } else {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RemoteDesktopScreen(agent: agent),
      ),
    );
  }
}
```

---

## Dependencies to Add

### Flutter packages
```yaml
porcupine_flutter: ^3.0.0          # Wake word detection
whisper_flutter: ^1.0.0             # Speech-to-text
google_generative_ai: ^0.4.0        # Gemma 3 1B inference (or media_pipe_core)
audioplayers: ^5.0.0                # Play TTS audio
permission_handler: ^11.0.0         # Mic + storage permissions
flutter_vnc: ^0.5.0                 # VNC client for RustDesk remote desktop
```

### Backend packages
```json
{
  "@fastify/multipart": "^8.1.0",   // For audio upload if needed
  "child_process": "built-in"       // For Piper subprocess
}
```

---

## Key Decisions & Assumptions

1. **Gemma 3 1B on mobile:** Trades 600MB download + latency for true offline, 24/7 operation. Accepted.
2. **Confirm before execute:** Default enabled, can toggle off. Safer UX.
3. **Device control only:** No general AI (weather, jokes, etc.). Simpler, faster responses.
4. **Piper TTS on backend:** Mobile TTS would work offline but Piper sounds better. Backend streaming is acceptable.
5. **Name learning via voice:** "Raiko, my name is Adam" is more immersive than a settings form.
6. **No email/cloud sync:** User name and settings stored locally on phone.

---

## Success Criteria

**Voice Assistant:**
- [ ] User says "Raiko, lock the laptop" → laptop locks within 3 seconds
- [ ] Response plays: "Locking the laptop, Sir." (with user name if set)
- [ ] Wake word detection runs 24/7 with <2% average CPU
- [ ] Whisper + Gemma parse latency <2 seconds on modern phones
- [ ] TTS audio plays clearly, ~500ms after request
- [ ] All offline except TTS stream (optional: cache common responses)
- [ ] Voice commands work even if WiFi drops (agent must be local or connect via backup)

**Remote Desktop Control:**
- [ ] Tap "Remote Control" on agent card → opens full-screen remote desktop viewer
- [ ] Mouse movement, clicks, and keyboard input work fluently
- [ ] Screen updates in <500ms latency over local network
- [ ] Agents without RustDesk ID configured show "Remote Control" button as disabled
- [ ] Voice command: "Raiko, open remote control on my laptop" → launches RemoteDesktopScreen
- [ ] Disconnect gracefully when app backgrounded or closed

---

## Open Questions

**Voice Assistant:**
1. **App name in open_app command:** How should the LLM handle app names? (e.g., "open spotify" → exact match, or fuzzy match against installed apps?)
2. **Multiple agents with same type:** How to handle "lock the laptop" when there are 2 laptops? (Priority: connected first, or ask user to specify?)
3. **Confirmation for dangerous commands:** Should shutdown/restart always confirm, regardless of toggle?
4. **Silent execution feedback:** What happens if confirm=false? Just haptic buzz + quick icon flash?
5. **TTS cache:** Should we cache "Locking the laptop, Adam" responses to speed up repeated commands?

**Remote Desktop Control:**
6. **RustDesk password storage:** Should passwords be encrypted in config? (recommended: yes, AES-256)
7. **Multi-monitor support:** If the agent has multiple monitors, should we let user choose which one?
8. **Session timeout:** How long before a remote desktop connection auto-disconnects if idle?
9. **Connection indicators:** Should we show connection status (connected/connecting/disconnected) in the remote desktop UI?
10. **Firewall/NAT:** If agent is behind NAT, should we fall back to a relay server (RustDesk has free public relays)?

