import {
  WebSocketGateway,
  SubscribeMessage,
  MessageBody,
  WebSocketServer,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
} from "@nestjs/websockets";
import { Server, Socket } from "socket.io";

/**
 * WebSocket Gateway for real-time features
 *
 * Features:
 * - Chat messaging (broadcast)
 * - Notifications
 * - Phone-to-socket mapping for targeted messages
 *
 * Note: OTP generation has been moved to OtpService.
 * SMS dispatch is handled by SmsGatewayClient (separate module).
 */
@WebSocketGateway(3090, { cors: { origin: "*" } })
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  // Map phone numbers to socket IDs for targeted messages
  private phoneToSocket: Map<string, string> = new Map();
  private socketToPhone: Map<string, string> = new Map();

  /**
   * Handle new socket connection
   */
  handleConnection(client: Socket) {
    console.log("[ChatGateway] Client connected:", client.id);

    // Extract phone from handshake if provided
    const phone = client.handshake.auth?.phone || client.handshake.query?.phone;
    if (phone) {
      const normalizedPhone = this.normalizePhone(phone as string);
      this.registerPhone(client.id, normalizedPhone);
    }
  }

  /**
   * Handle socket disconnection
   */
  handleDisconnect(client: Socket) {
    console.log("[ChatGateway] Client disconnected:", client.id);
    this.unregisterSocket(client.id);
  }

  /**
   * Register a phone number with a socket ID
   */
  @SubscribeMessage("register")
  handleRegister(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { phone: string },
  ): void {
    if (data?.phone) {
      const normalizedPhone = this.normalizePhone(data.phone);
      this.registerPhone(client.id, normalizedPhone);
      client.emit("registered", { phone: normalizedPhone });
    }
  }

  /**
   * Handle chat messages (broadcast to all)
   */
  @SubscribeMessage("chat message")
  handleChatMessage(@MessageBody() data: any): void {
    console.log("[ChatGateway] Chat message received:", data);
    this.server.emit("chat message", data);
  }

  /**
   * Send a notification to all connected clients
   */
  sendNotification(notification: any): void {
    this.server.emit("notification", notification);
  }

  /**
   * Send a message to a specific phone number
   */
  sendToPhone(phone: string, event: string, data: any): boolean {
    const normalizedPhone = this.normalizePhone(phone);
    const socketId = this.phoneToSocket.get(normalizedPhone);

    if (socketId && this.server.sockets.sockets.has(socketId)) {
      this.server.to(socketId).emit(event, data);
      return true;
    }
    return false;
  }

  /**
   * Send OTP to a specific phone (called from SMS service after dispatch)
   * This is for real-time delivery to connected clients
   */
  sendOtpToClient(phone: string, requestId: string): boolean {
    return this.sendToPhone(phone, "otp:delivered", { requestId, phone });
  }

  // ============================================================
  // Private helpers
  // ============================================================

  private normalizePhone(phone: string): string {
    if (!phone) return phone;
    const normalized = phone.replace(/[^\d+]/g, "");
    return normalized.startsWith("+") ? normalized : `+${normalized}`;
  }

  private registerPhone(socketId: string, phone: string): void {
    // Remove old registration if exists
    const oldSocketId = this.phoneToSocket.get(phone);
    if (oldSocketId && oldSocketId !== socketId) {
      this.socketToPhone.delete(oldSocketId);
    }

    this.phoneToSocket.set(phone, socketId);
    this.socketToPhone.set(socketId, phone);
    console.log("[ChatGateway] Registered phone:", { phone, socketId });
  }

  private unregisterSocket(socketId: string): void {
    const phone = this.socketToPhone.get(socketId);
    if (phone) {
      this.phoneToSocket.delete(phone);
      this.socketToPhone.delete(socketId);
      console.log("[ChatGateway] Unregistered phone:", { phone, socketId });
    }
  }

  /**
   * Check if a phone is connected
   */
  isPhoneConnected(phone: string): boolean {
    const normalizedPhone = this.normalizePhone(phone);
    const socketId = this.phoneToSocket.get(normalizedPhone);
    return socketId ? this.server.sockets.sockets.has(socketId) : false;
  }

  /**
   * Get connected clients count
   */
  getConnectedCount(): number {
    return this.server.sockets.sockets.size;
  }
}
