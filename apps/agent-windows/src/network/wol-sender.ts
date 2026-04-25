import { createSocket } from "node:dgram";

/**
 * Wake-on-LAN (WOL) packet sender
 * Sends magic packets to wake up computers on the network
 */
export class WolSender {
  /**
   * Generate a magic packet for Wake-on-LAN
   * Magic packet format: 6 bytes of 0xFF followed by 16 repetitions of the target MAC address
   */
  private static generateMagicPacket(macAddress: string): Buffer {
    // Validate and parse MAC address (format: AA:BB:CC:DD:EE:FF or AABBCCDDEEFF)
    const macBytes = this.parseMacAddress(macAddress);
    if (!macBytes) {
      throw new Error(`Invalid MAC address: ${macAddress}`);
    }

    // Create the magic packet: 6 bytes of 0xFF + 16 repetitions of MAC (16 * 6 = 96 bytes)
    const magicPacket = Buffer.alloc(102);

    // First 6 bytes are all 0xFF
    for (let i = 0; i < 6; i++) {
      magicPacket[i] = 0xff;
    }

    // Repeat MAC address 16 times
    for (let i = 0; i < 16; i++) {
      for (let j = 0; j < 6; j++) {
        const offset = 6 + i * 6 + j;
        magicPacket[offset] = macBytes[j]!;
      }
    }

    return magicPacket;
  }

  /**
   * Parse MAC address string into bytes
   * Supports formats: AA:BB:CC:DD:EE:FF or AABBCCDDEEFF
   */
  private static parseMacAddress(mac: string): Buffer | null {
    // Remove colons and hyphens
    const cleanMac = mac.replace(/[:|-]/g, "").toUpperCase();

    // Should be 12 hex characters (6 bytes)
    if (!/^[0-9A-F]{12}$/.test(cleanMac)) {
      return null;
    }

    const bytes = Buffer.alloc(6);
    for (let i = 0; i < 6; i++) {
      bytes[i] = parseInt(cleanMac.substr(i * 2, 2), 16);
    }

    return bytes;
  }

  /**
   * Send a magic packet to wake up a device
   * @param macAddress MAC address of the device (format: AA:BB:CC:DD:EE:FF)
   * @param broadcastAddress Broadcast address (default: 255.255.255.255)
   * @param port UDP port (default: 9 - standard WOL port)
   */
  static async send(
    macAddress: string,
    broadcastAddress: string = "255.255.255.255",
    port: number = 9,
  ): Promise<void> {
    return new Promise((resolve, reject) => {
      try {
        const magicPacket = this.generateMagicPacket(macAddress);

        const socket = createSocket("udp4");

        socket.on("error", (error: Error) => {
          socket.close();
          reject(new Error(`WOL send failed: ${error.message}`));
        });

        // Enable broadcast
        socket.setBroadcast(true);

        // Send the magic packet
        socket.send(magicPacket, 0, magicPacket.length, port, broadcastAddress, (error) => {
          socket.close();

          if (error) {
            reject(new Error(`Failed to send WOL packet: ${error.message}`));
          } else {
            resolve();
          }
        });

        // Timeout after 2 seconds
        setTimeout(() => {
          socket.close();
          resolve();
        }, 2000);
      } catch (error) {
        reject(error);
      }
    });
  }
}
