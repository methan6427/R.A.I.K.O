# R.A.I.K.O Complete Issues & Concrete Fix Plan

**Date:** 2026-04-25  
**Status:** CRITICAL - System needs architectural fixes before feature continuation

---

## CRITICAL ISSUES IDENTIFIED

### 1. API Key Security Issue ⚠️ SEVERE
**Problem:** Gemini API key stored in mobile app UI via SharedPreferences
- Exposes secrets in app memory
- Could be extracted from APK
- Not a production pattern

**Impact:** Security vulnerability

**Fix:** 
```
- Remove API key input from mobile UI entirely
- Create backend endpoint `/api/intent-parse` that accepts text
- Store API keys on backend server (in .env)
- Mobile calls backend instead of Gemini directly
- No secrets in app
```

---

### 2. Free Tier Quota Limitation ❌ DESIGN FLAW
**Problem:** Using Google Gemini free tier with strict quota limits
- User explicitly asked for "free options with no limit"
- Google API has daily quota resets
- Not suitable for production/testing

**Impact:** System unusable after quota exhaustion

**Solution:** Use LOCAL/SELF-HOSTED intent parser
- **Option A:** Ollama (local LLM) - completely free, no limits, no API keys
- **Option B:** Open-source intent parser library
- **Option C:** Simple regex-based command parser for MVP (command="lock|shutdown|restart|sleep|open_remote_desktop")

**Recommended:** Ollama + local LLM (llama2 or mistral)
- Download once: ~4GB
- Run locally: unlimited free requests
- Zero latency, zero quota issues
- Perfect for development

---

### 3. UI Doesn't Match Design ❌ MAJOR
**Problem:** Mobile app UI built from scratch, ignoring user's Claude Design file
- User created full design in Claude Design tool
- We implemented different UI
- All visual, layout, and component choices ignored

**Impact:** Product doesn't match user's vision

**Fix:**
- Export design from Claude Design as screenshots or specs
- Rebuild Flutter UI to match design exactly
- Use design system colors, typography, spacing from design
- Recreate all screens according to design file

---

### 4. STT (Speech-to-Text) is Placeholder ❌ BROKEN
**Problem:** `raiko_speech_to_text.dart` always returns empty string
- User can't speak commands
- Workaround: added text input field (band-aid, not real fix)

**Impact:** Voice feature doesn't work as intended

**Fix:**
- **Option A:** Use `speech_to_text` package with proper setup (address Kotlin compilation errors)
- **Option B:** Whisper.cpp (local speech recognition, no API key needed)
- **Option C:** For MVP: Text-only input (acceptable if user approves)

---

### 5. WebSocket Connection Issues 🔴 INTERMITTENT
**Problem:** Mobile app sometimes doesn't connect to backend
- Connection indicator shows "1 agent linked" but voice fails
- Possible causes:
  - Backend not running
  - Port 8080 conflicts
  - Mobile not reaching localhost:8080 from emulator

**Impact:** Voice commands fail silently

**Fix:**
```
1. Verify emulator network:
   - adb shell: curl http://10.0.2.2:8080/api/overview (10.0.2.2 is host from emulator)
   
2. Update mobile: Connect to actual IP, not localhost
   - Get backend host IP: ipconfig getifaddr en0 (or Windows equivalent)
   - Update connection settings to use backend IP
   
3. Add connection status display in UI
   - Show real-time WebSocket status
   - Show backend URL being used
   - Show last error/disconnect reason
```

---

### 6. Backend Voice Endpoint Issues 🔴
**Problem:** TTS endpoint works but no intent parsing on backend
- `/api/tts` - generates audio (working)
- `/api/intent-parse` - MISSING
- Mobile has to call Gemini directly (security issue)

**Fix:**
```
Create backend endpoint:
POST /api/intent-parse
{
  "text": "Lock the office PC",
  "agents": ["Office PC", "Workstation"],
  "userName": "Adam"
}

Response:
{
  "command": "lock",
  "targetAgent": "Office PC",
  "confidence": 0.95
}

Use: Ollama or local parser
```

---

### 7. Agent Connection Issues 🔴
**Problem:** Windows agent connectivity status unclear
- "1 agent linked" appears but agent might not actually be running
- No heartbeat verification visible
- No error messages about agent failures

**Fix:**
```
Backend needs:
- Agent heartbeat tracking with timestamp
- Agent health status endpoint
- Clear "online" vs "offline" state
- Last seen time for each agent

Mobile UI needs:
- Real-time agent status display
- Show agent as "online", "offline", "stale"
- Show last command results per agent
```

---

### 8. Piper TTS Setup is Manual 🟡
**Problem:** User had to manually install Piper to C:\Users\methan\AppData\Local\Piper
- Installation path hardcoded in code
- Won't work for other users/machines
- No error handling if Piper not found

**Fix:**
```
Option A: Docker container
- Wrap backend + Piper in Docker
- Single docker run command
- Works anywhere

Option B: Autodetect + fallback
- Check multiple common paths for piper.exe
- If not found, provide clear instructions
- Fallback to eSpeak with warning

Option C: Web service
- Deploy Piper as separate microservice
- Backend calls via HTTP
```

---

### 9. No Error Recovery ❌
**Problem:** When any component fails, system stops working
- Voice button becomes disabled
- Error messages not user-friendly
- No "retry" or "reconnect" options visible

**Fix:**
```
Add to mobile UI:
- "Retry" button when voice fails
- "Reconnect" button for WebSocket issues
- "Test connection" button in Settings
- Real error messages explaining what failed
```

---

### 10. Repeated Bugs & Syntax Errors 🔴
**Problem:** My changes introduce bugs:
- Missing method implementation
- Syntax errors in Dart
- Logic errors in state management

**Fix:**
- Build & analyze before claiming complete
- Run `flutter analyze` on every change
- Test on emulator before saying "done"
- Review code changes for correctness first

---

## CONCRETE FIX PLAN (PRIORITY ORDER)

### PHASE 1: ARCHITECTURE FIX (Today)
**Goal:** Remove secrets from mobile, add backend intent parsing

1. **Remove Gemini key from mobile app**
   ```
   - Delete API key input from Settings UI
   - Delete geminiApiKey from RaikoSettingsStore
   - Remove SharedPreferences storage for API keys
   ```

2. **Create backend intent parser endpoint**
   ```
   - Install Ollama locally
   - Add `/api/intent-parse` endpoint
   - Move intent parsing from mobile to backend
   - Backend stores all API keys securely (in .env)
   ```

3. **Update mobile voice engine**
   ```
   - Call backend endpoint instead of Gemini
   - Remove all API key handling
   - Simplified voice flow
   ```

4. **Test voice flow end-to-end**
   - Type command in text field
   - Mobile calls backend
   - Backend parses intent (Ollama)
   - Backend generates TTS (Piper)
   - Audio returns to mobile
   - Verify audio plays

---

### PHASE 2: UI REDESIGN (2-3 hours)
**Goal:** Implement actual design from Claude Design file

1. **Get design specifications**
   - Screenshot or export from Claude Design
   - Understand layout, colors, typography
   - Identify all screens and components

2. **Rebuild mobile UI**
   - Home/Dashboard screen
   - Devices screen
   - Activity screen
   - Settings screen (no API key input)
   - Voice console (match design)

3. **Rebuild desktop UI**
   - Same design consistency

---

### PHASE 3: FEATURE FIXES (4-5 hours)
**Goal:** Fix core functionality issues

1. **WebSocket connection reliability**
   - Fix emulator localhost issue (use 10.0.2.2)
   - Add connection status UI
   - Add reconnect logic

2. **Agent status tracking**
   - Implement agent heartbeat on backend
   - Track online/offline status
   - Display in UI

3. **STT solution**
   - Decide: speech_to_text package vs text-only for MVP
   - Fix compilation errors if using package
   - Or accept text-only input

4. **Error handling & recovery**
   - Add Retry buttons
   - Add Reconnect buttons
   - Better error messages
   - Graceful degradation

---

### PHASE 4: DEPLOYMENT (2 hours)
**Goal:** Make it deployable

1. **Docker containerization**
   ```
   - Dockerfile for backend (Node + Ollama + Piper)
   - Single docker-compose up to run everything
   - No manual installation needed
   ```

2. **Environment configuration**
   ```
   - All hardcoded paths removed
   - All config from .env
   - Ready for different machines/users
   ```

3. **Documentation**
   ```
   - Setup instructions
   - Architecture diagram
   - Troubleshooting guide
   ```

---

## REQUIRED USER INPUT

To proceed, please provide:

1. **Design specifications**
   - Screenshot of Claude Design
   - Or description of layout/colors/components
   - Or export from Claude Design tool

2. **Feature priorities**
   - Is speech-to-text required or text-only acceptable?
   - Ollama for local intent parsing - acceptable?
   - Docker deployment acceptable?

3. **Scope confirmation**
   - Just fix existing system or redesign?
   - How much time available?

---

## ESTIMATED TIMELINE

| Phase | Time | Status |
|-------|------|--------|
| Phase 1: Architecture | 2-3 hours | CAN START NOW |
| Phase 2: UI Redesign | 2-3 hours | BLOCKED: Need design |
| Phase 3: Feature Fixes | 4-5 hours | CAN START AFTER PHASE 1 |
| Phase 4: Deployment | 2 hours | FINAL |
| **TOTAL** | **10-13 hours** | |

---

## WHAT YOU SHOULD PROVIDE

1. Screenshots or specs from your Claude Design
2. Confirmation of tech choices (Ollama, Docker, etc.)
3. Timeline/deadline

Once I have these, I will:
- NOT introduce bugs
- Test changes thoroughly before reporting done
- Follow design exactly
- Solve root causes, not band-aids
- Document everything clearly

---

## CURRENT WORKING STATE

✅ Backend server (Fastify)
✅ Piper TTS (generating 600KB+ audio files)
✅ Windows agent (command execution)
✅ Mobile app (basic UI and voice framework)
✅ WebSocket connection (mostly stable)

❌ Gemini API (quota exhausted)
❌ UI design (doesn't match user's design)
❌ Intent parsing on backend (missing)
❌ STT (placeholder)
❌ Error handling (minimal)

