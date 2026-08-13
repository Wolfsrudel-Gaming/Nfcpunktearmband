import { Router } from 'express';
import { AppDataSource } from '../config/database.js';
import { getRedis } from '../config/redis.js';

export const healthRouter = Router();

healthRouter.get('/', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

healthRouter.get('/ready', async (_req, res) => {
  const checks: Record<string, string> = {};

  try {
    await AppDataSource.query('SELECT 1');
    checks.database = 'ok';
  } catch {
    checks.database = 'error';
  }

  try {
    await getRedis().ping();
    checks.redis = 'ok';
  } catch {
    checks.redis = 'error';
  }

  const allOk = Object.values(checks).every((v) => v === 'ok');
  res.status(allOk ? 200 : 503).json({ status: allOk ? 'ready' : 'degraded', checks });
});
