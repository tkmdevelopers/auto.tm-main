import { Request } from "express";

export interface AuthenticatedRequest extends Request {
  uuid?: string;
  user?: any;
  // Add other properties that might be attached to the request, like user role, etc.
  [key: string]: any;
}
