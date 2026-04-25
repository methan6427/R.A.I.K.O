import { spawn } from "node:child_process";
import { existsSync } from "node:fs";
import { randomBytes } from "crypto";
import { join } from "path";
import { tmpdir, homedir } from "os";


export interface TTSOptions {
  voice?: string | undefined;
  speed?: number | undefined;
}

export class VoiceModule {
  private piperPath = join(homedir(), "AppData", "Local", "Piper", "piper.exe");
  private voiceModelDir = join(homedir(), ".local", "share", "piper", "voices");
  private defaultVoice = "en_US-ryan-high";

  constructor() {}

  /**
   * Convert text to speech using Piper
   * Returns path to generated WAV file
   */
  async textToSpeech(text: string, options: TTSOptions = {}): Promise<string> {
    try {
      if (!text || text.trim().length === 0) {
        throw new Error("Text cannot be empty");
      }

      // Voice selection (defaults to high-quality Ryan voice)
      const voice = options.voice ?? this.defaultVoice;
      const voiceModelPath = join(this.voiceModelDir, `${voice}.onnx`);

      if (!existsSync(voiceModelPath)) {
        throw new Error(
          `Voice model not found: ${voiceModelPath}. Download voice models to: ${this.voiceModelDir}`,
        );
      }

      // Generate output file path
      const filename = `raiko-tts-${randomBytes(8).toString("hex")}.wav`;
      const filepath = join(tmpdir(), filename);

      // Speed control: Piper uses --length-scale (1.0 = normal, <1.0 = faster, >1.0 = slower)
      const speed = options.speed ?? 1.0;
      const lengthScale = (2.0 - speed).toString(); // Invert: speed 0.5 -> scale 1.5 (slower)

      // Execute Piper to generate WAV file
      await new Promise<void>((resolve, reject) => {
        const child = spawn(this.piperPath, [
          "--model",
          voiceModelPath,
          "--output-file",
          filepath,
          "--length-scale",
          lengthScale,
        ]);

        child.stdin.write(text);
        child.stdin.end();

        child.on("error", reject);
        child.on("close", (code) => {
          if (code === 0) {
            resolve();
          } else {
            reject(new Error(`Piper exited with code ${code}`));
          }
        });
      });

      if (!existsSync(filepath)) {
        throw new Error("Failed to generate audio file");
      }

      return filepath;
    } catch (e) {
      throw new Error(`Text-to-speech failed: ${e instanceof Error ? e.message : String(e)}`);
    }
  }

  /**
   * Get available voices (Piper voices)
   */
  async getAvailableVoices(): Promise<string[]> {
    return [
      "en_US-ryan-high",
      "en_US-ryan-medium",
      "en_US-ryan-low",
      "en_GB-alan-medium",
      "en_GB-jenny_dioco-medium",
    ];
  }
}
