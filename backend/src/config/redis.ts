import Redis from 'ioredis';
import { getEnv } from './env.js';
import { logger } from '../utils/logger.js';

let _redis: Redis | undefined;

export function getRedis(): Redis {
  if (!_redis) {
    _redis = new Redis(getEnv().REDIS_URL, {
      maxRetriesPerRequest: null,
      lazyConnect: true,
    });

    _redis.on('error', (err) => {
      logger.error('Redis connection error', { error: err.message });
    });

    _redis.on('connect', () => {
      logger.info('Redis connected');
    });
  }
  return _redis;
}
