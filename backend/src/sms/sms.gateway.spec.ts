import { Test, TestingModule } from "@nestjs/testing";
import { SmsGateway } from "./sms.gateway";
import { EventEmitter2 } from "@nestjs/event-emitter";
import { Socket } from "socket.io";

describe("SmsGateway", () => {
  let gateway: SmsGateway;
  let eventEmitter: EventEmitter2;

  // Mock Socket Object
  const mockSocket = {
    id: "socket_123",
    disconnect: jest.fn(),
    emit: jest.fn(),
    handshake: { headers: {} },
  } as unknown as Socket;

  // Mock Server Object
  const mockServer = {
    to: jest.fn().mockReturnThis(),
    emit: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SmsGateway,
        {
          provide: EventEmitter2,
          useValue: { emit: jest.fn() },
        },
      ],
    }).compile();

    gateway = module.get<SmsGateway>(SmsGateway);
    eventEmitter = module.get<EventEmitter2>(EventEmitter2);
    gateway.server = mockServer as any; // Inject mock server
    (gateway as any).devices.clear(); // Reset state
    (gateway as any).pendingRequests.clear();
  });

  it("should be defined", () => {
    expect(gateway).toBeDefined();
  });

  describe("Device Registration", () => {
    it("should register a device successfully", () => {
      const payload = { region: "tm", deviceId: "android_1" };
      const result = gateway.handleRegister(mockSocket, payload);

      expect(result.success).toBe(true);
      expect(gateway.hasConnectedDevice("tm")).toBe(true);
      expect((gateway as any).devices.get("android_1")).toBeDefined();
    });

    it("should fail registration with invalid auth token (if configured)", () => {
      process.env.SMS_DEVICE_AUTH_TOKEN = "secret_token";
      
      const payload = { authToken: "wrong_token" };
      const result = gateway.handleRegister(mockSocket, payload);

      expect(result.success).toBe(false);
      expect(result.message).toContain("Invalid auth token");
      expect(gateway.hasConnectedDevice()).toBe(false);

      delete process.env.SMS_DEVICE_AUTH_TOKEN; // Cleanup
    });
  });

  describe("Sending SMS", () => {
    it("should queue request and emit event to device", async () => {
      // 1. Register a device first
      gateway.handleRegister(mockSocket, { region: "tm", deviceId: "dev1" });

      // 2. Send SMS request
      const request = {
        correlationId: "req_1",
        phone: "+99365000000",
        text: "Your code is 12345",
        region: "tm"
      };

      const result = await gateway.sendSms(request);

      // 3. Assertions
      expect(result).toBe(true);
      // Expect server to emit to specific socket
      expect(mockServer.to).toHaveBeenCalledWith("socket_123");
      expect(mockServer.emit).toHaveBeenCalledWith("sms:send", expect.objectContaining({
        correlationId: "req_1",
        phone: "+99365000000"
      }));
    });

    it("should fail if no device is connected for region", async () => {
      const request = {
        correlationId: "req_2",
        phone: "+99365000000",
        text: "Hello",
        region: "tm"
      };

      const result = await gateway.sendSms(request);

      expect(result).toBe(false);
      // Should emit failure event internally
      expect(eventEmitter.emit).toHaveBeenCalledWith("sms.ack", expect.objectContaining({
        status: "failed",
        error: expect.stringContaining("No SMS device available")
      }));
    });
  });

  describe("Handling ACKs", () => {
    it("should process success ack and clean up pending request", async () => {
      // Setup: register and queue request
      gateway.handleRegister(mockSocket, { region: "tm" });
      const request = { correlationId: "req_1", phone: "123", text: "msg", otpRequestId: "otp_1" };
      await gateway.sendSms(request);

      // Verify pending request exists
      expect((gateway as any).pendingRequests.has("req_1")).toBe(true);

      // Act: Receive ACK
      gateway.handleAck(mockSocket, {
        correlationId: "req_1",
        status: "sent"
      });

      // Assert
      expect((gateway as any).pendingRequests.has("req_1")).toBe(false);
      expect(eventEmitter.emit).toHaveBeenCalledWith("sms.ack", expect.objectContaining({
        correlationId: "req_1",
        status: "sent",
        otpRequestId: "otp_1"
      }));
    });
  });
});
