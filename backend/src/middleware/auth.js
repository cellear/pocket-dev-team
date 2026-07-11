export function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;
  const expectedToken = process.env.AUTH_TOKEN;

  if (!expectedToken) {
    console.warn('Warning: AUTH_TOKEN not set, authentication disabled');
    return next();
  }

  if (!authHeader) {
    return res.status(401).json({ error: 'Authorization header required' });
  }

  const [scheme, token] = authHeader.split(' ');

  if (scheme !== 'Bearer' || !token) {
    return res.status(401).json({ error: 'Invalid authorization format. Use: Bearer <token>' });
  }

  if (token !== expectedToken) {
    return res.status(403).json({ error: 'Invalid token' });
  }

  next();
}
