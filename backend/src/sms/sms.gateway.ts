import {
  WebSocketGateway,
  SubscribeMessage,
  MessageBody,
  WebSocketServer,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
} from "@nestjs/websockets";
import { Logger } from "@nestjs/common";
import { Server, Socket } from "socket.io";
import { EventEmitter2 } from "@nestjs/event-emitter";

/**
 * SMS send request payload
 */
export interface SmsSendRequest {
  /** Unique correlation ID for tracking */
  correlationId: string;
  /** Phone number in E.164 format */
  phone: string;
  /** Message text */
  text: string;
  /** Region for SMS routing */
  region?: string;
  /** OTP request ID (for status updates) */
  otpRequestId?: string;
}

/**
 * SMS acknowledgment from the device
 */
export interface SmsAck {
  /** Correlation ID from the request */
  correlationId: string;
  /** Delivery status */
  status: "sent" | "delivered" | "failed";
  /** Error message if failed */
  error?: string;
  /** Timestamp */
  timestamp?: Date;
}

/**
 * SMS Gateway Server
 *
 * Accepts connections from physical SMS devices (mobile phones).
 * The SMS device connects to this gateway and listens for SMS requests.
 *
 * Architecture:
 * - Backend runs Socket.IO server on port 3091
 * - Physical phone connects as a client
 * - Backend emits 'sms:send' when OTP needs to be sent
 * - Phone sends the actual SMS via its cellular network
 * - Phone emits 'sms:ack' with delivery status
 *
 * Socket Events:
 * - Client → Server: 'sms:register' - Device registration with auth token
 * - Client → Server: 'sms:ack' - SMS delivery acknowledgment
 * - Client → Server: 'sms:status' - Device status update
 * - Server → Client: 'sms:send' - Request to send SMS
 * - Server → Client: 'sms:ping' - Keep-alive ping
 */
@WebSocketGateway(3091, {
  cors: { origin: "*" },
  namespace: "/sms",
})
export class SmsGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(SmsGateway.name);

  // Connected SMS devices by region
  private devices: Map<
    string,
    {
      socketId: string;
      region: string;
      connectedAt: Date;
      lastActivity: Date;
    }
  > = new Map();

  // Pending SMS requests awaiting acknowledgment
  private pendingRequests: Map<string, SmsSendRequest & { sentAt: Date }> =
    new Map();

  // Default region when no specific region requested
  private defaultRegion = process.env.SMS_DEFAULT_REGION || "tm";

  constructor(private eventEmitter: EventEmitter2) {}

  /**
   * Handle new device connection
   */
  handleConnection(client: Socket) {
    this.logger.log(`SMS device connecting: ${client.id}`);

    // Device must register within 10 seconds or be disconnected
    setTimeout(() => {
      if (!this.isDeviceRegistered(client.id)) {
        this.logger.warn(`Device ${client.id} did not register, disconnecting`);
        client.disconnect();
      }
    }, 10000);
  }

  /**
   * Handle device disconnection
   */
  handleDisconnect(client: Socket) {
    this.logger.log(`SMS device disconnected: ${client.id}`);
    this.unregisterDevice(client.id);
  }

  /**
   * Device registration
   * The physical phone must call this after connecting
   */
  @SubscribeMessage("sms:register")
  handleRegister(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    data: {
      authToken?: string;
      region?: string;
      deviceId?: string;
    },
  ): { success: boolean; message: string } {
    // Validate auth token if configured
    const expectedToken = process.env.SMS_DEVICE_AUTH_TOKEN;
    if (expectedToken && data.authToken !== expectedToken) {
      this.logger.warn(`Device ${client.id} failed authentication`);
      return { success: false, message: "Invalid auth token" };
    }

    const region = data.region || this.defaultRegion;
    const deviceKey = data.deviceId || `device-${region}`;

    // Register the device
    this.devices.set(deviceKey, {
      socketId: client.id,
      region,
      connectedAt: new Date(),
      lastActivity: new Date(),
    });

    this.logger.log(`SMS device registered: ${deviceKey} (${region})`);

    // Emit event for monitoring
    this.eventEmitter.emit("sms.device.connected", {
      deviceKey,
      region,
      socketId: client.id,
    });

    return {
      success: true,
      message: `Registered as ${deviceKey} for region ${region}`,
    };
  }

  /**
   * SMS delivery acknowledgment from device
   */
  @SubscribeMessage("sms:ack")
  handleAck(
    @ConnectedSocket() client: Socket,
    @MessageBody() ack: SmsAck,
  ): void {
    const pending = this.pendingRequests.get(ack.correlationId);

    if (!pending) {
      this.logger.warn(
        `Received ack for unknown request: ${ack.correlationId}`,
      );
      return;
    }

    this.logger.log(`SMS ack received`, {
      correlationId: ack.correlationId,
      status: ack.status,
      phone: pending.phone.slice(0, -4) + "****",
    });

    // Clean up pending request
    this.pendingRequests.delete(ack.correlationId);

    // Update device activity
    this.updateDeviceActivity(client.id);

    // Emit event for OtpService to update dispatch status
    this.eventEmitter.emit("sms.ack", {
      ...ack,
      otpRequestId: pending.otpRequestId,
      timestamp: new Date(),
    });
  }

  /**
   * Device status update (heartbeat)
   */
  @SubscribeMessage("sms:status")
  handleStatus(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    data: {
      batteryLevel?: number;
      signalStrength?: number;
      pendingSms?: number;
    },
  ): void {
    this.updateDeviceActivity(client.id);
    this.logger.debug(`Device status from ${client.id}:`, data);
  }

  /**
   * Send SMS request to a connected device
   */
  async sendSms(request: SmsSendRequest): Promise<boolean> {
    const region = request.region || this.defaultRegion;
    const device = this.findDeviceForRegion(region);

    if (!device) {
      this.logger.warn(`No SMS device available for region: ${region}`);

      // Emit failure event
      this.eventEmitter.emit("sms.ack", {
        correlationId: request.correlationId,
        status: "failed",
        error: `No SMS device available for region: ${region}`,
        otpRequestId: request.otpRequestId,
        timestamp: new Date(),
      });

      return false;
    }

    // Store pending request
    this.pendingRequests.set(request.correlationId, {
      ...request,
      sentAt: new Date(),
    });

    // Send to device
    this.server.to(device.socketId).emit("sms:send", {
      correlationId: request.correlationId,
      phone: request.phone,
      text: request.text,
    });

    this.logger.log(`SMS queued for device`, {
      correlationId: request.correlationId,
      phone: request.phone.slice(0, -4) + "****",
      region,
      deviceSocket: device.socketId,
    });

    // Set timeout for acknowledgment (30 seconds)
    setTimeout(() => {
      const pending = this.pendingRequests.get(request.correlationId);
      if (pending) {
        this.logger.warn(`SMS ack timeout: ${request.correlationId}`);
        this.pendingRequests.delete(request.correlationId);

        this.eventEmitter.emit("sms.ack", {
          correlationId: request.correlationId,
          status: "failed",
          error: "SMS device did not acknowledge within timeout",
          otpRequestId: request.otpRequestId,
          timestamp: new Date(),
        });
      }
    }, 30000);

    return true;
  }

  /**
   * Check if any SMS device is connected
   */
  hasConnectedDevice(region?: string): boolean {
    if (region) {
      return this.findDeviceForRegion(region) !== null;
    }
    return this.devices.size > 0;
  }

  /**
   * Get connected devices info
   */
  getConnectedDevices(): Array<{
    deviceKey: string;
    region: string;
    connectedAt: Date;
  }> {
    return Array.from(this.devices.entries()).map(([key, device]) => ({
      deviceKey: key,
      region: device.region,
      connectedAt: device.connectedAt,
    }));
  }

  /**
   * Send ping to all devices (call periodically to detect stale connections)
   */
  pingDevices(): void {
    this.server.emit("sms:ping", { timestamp: Date.now() });
  }

  // ============================================================
  // Private helpers
  // ============================================================

  private isDeviceRegistered(socketId: string): boolean {
    for (const device of this.devices.values()) {
      if (device.socketId === socketId) {
        return true;
      }
    }
    return false;
  }

  private unregisterDevice(socketId: string): void {
    for (const [key, device] of this.devices.entries()) {
      if (device.socketId === socketId) {
        this.devices.delete(key);
        this.logger.log(`Device unregistered: ${key}`);
        this.eventEmitter.emit("sms.device.disconnected", {
          deviceKey: key,
          region: device.region,
        });
        break;
      }
    }
  }

  private findDeviceForRegion(
    region: string,
  ): { socketId: string; region: string } | null {
    // First try exact region match
    for (const device of this.devices.values()) {
      if (device.region === region) {
        return device;
      }
    }

    // Fallback to any available device
    const firstDevice = this.devices.values().next();
    if (!firstDevice.done) {
      return firstDevice.value;
    }

    return null;
  }

  private updateDeviceActivity(socketId: string): void {
    for (const device of this.devices.values()) {
      if (device.socketId === socketId) {
        device.lastActivity = new Date();
        break;
      }
    }
  }
}
