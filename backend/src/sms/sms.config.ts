import { registerAs } from "@nestjs/config";

/**
 * SMS Gateway Configuration
 *
 * Environment Variables:
 * - SMS_GATEWAY_URL: WebSocket URL of the SMS microservice (default: ws://localhost:3091)
 * - SMS_GATEWAY_AUTH_TOKEN: Authentication token for the SMS service (optional)
 * - SMS_GATEWAY_NAMESPACE: Socket.IO namespace (default: /sms)
 * - SMS_GATEWAY_RECONNECT: Auto-reconnect on disconnect (default: true)
 * - SMS_GATEWAY_TIMEOUT: Connection timeout in ms (default: 5000)
 */
export const smsConfig = registerAs("sms", () => ({
  // SMS Gateway WebSocket URL
  gatewayUrl: process.env.SMS_GATEWAY_URL || "ws://localhost:3091",

  // Authentication token for SMS service
  authToken: process.env.SMS_GATEWAY_AUTH_TOKEN || "",

  // Socket.IO namespace
  namespace: process.env.SMS_GATEWAY_NAMESPACE || "/sms",

  // Auto-reconnect settings
  reconnect: process.env.SMS_GATEWAY_RECONNECT !== "false",
  reconnectAttempts: parseInt(
    process.env.SMS_GATEWAY_RECONNECT_ATTEMPTS || "10",
    10,
  ),
  reconnectDelay: parseInt(
    process.env.SMS_GATEWAY_RECONNECT_DELAY || "1000",
    10,
  ),

  // Connection timeout
  timeout: parseInt(process.env.SMS_GATEWAY_TIMEOUT || "5000", 10),

  // Default region for SMS routing
  defaultRegion: process.env.SMS_DEFAULT_REGION || "tm",

  // OTP message template
  otpMessageTemplate:
    process.env.SMS_OTP_TEMPLATE ||
    "Your verification code is: {code}. Valid for {ttl} minutes.",

  // OTP TTL in minutes (for message template)
  otpTtlMinutes: parseInt(process.env.OTP_TTL_SECONDS || "300", 10) / 60,
}));

export type SmsConfig = ReturnType<typeof smsConfig>;
