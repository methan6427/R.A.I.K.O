import { execSync } from "node:child_process";
import { networkInterfaces } from "node:os";

/**
 * Get the primary MAC address of this machine
 * First tries to use the OS network interfaces, falls back to getmac command
 */
export function getMacAddress(): string | null {
  try {
    // Try using Node.js os.networkInterfaces() first (fastest)
    const interfaces = networkInterfaces();
    for (const iface of Object.values(interfaces)) {
      if (!iface) continue;
      for (const addr of iface) {
        if (addr.family === "IPv4" && !addr.internal) {
          const mac = addr.mac?.toUpperCase();
          if (mac && /^([0-9A-F]{2}[:-]){5}([0-9A-F]{2})$/.test(mac)) {
            return mac;
          }
        }
      }
    }

    // Fallback: use getmac command
    const output = execSync("getmac /fo csv /nh", { encoding: "utf-8" });
    const lines = output.trim().split("\n");
    for (const line of lines) {
      const mac = line.trim().replaceAll('"', "");
      if (/^([0-9A-F]{2}-){5}([0-9A-F]{2})$/.test(mac)) {
        return mac.replaceAll("-", ":");
      }
    }
  } catch {
    // Silently fail
  }

  return null;
}
