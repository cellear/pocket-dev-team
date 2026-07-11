// Simple token-based authentication
// For production, consider OAuth or JWT

import { randomUUID } from 'node:crypto';

export function validateToken(token, config) {
  if (!config.auth.enabled) return true;
  if (!token) return false;
  
  // Check against configured tokens
  return config.auth.tokens.includes(token);
}

export function generateToken() {
  return randomUUID();
}
