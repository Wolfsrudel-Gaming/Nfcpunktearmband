import 'reflect-metadata';
import { createServer } from 'http';
import { Server as SocketServer } from 'socket.io';
import { app } from './app.js';
import { AppDataSource } from './config/database.js';
import { getRedis } from './config/redis.js';
import { getEnv } from './config/env.js';
import { logger } from './utils/logger.js';
import { setupSocketHandlers } from './services/socket.service.js';

async function bootstrap() {
  const env = getEnv();

  await AppDataSource.initialize();
  logger.info('Database connected');

  await getRedis().connect();

  const server = createServer(app);

  const io = new SocketServer(server, {
    cors: { origin: '*', methods: ['GET', 'POST'] },
  });
  setupSocketHandlers(io);

  server.listen(env.PORT, () => {
    logger.info(`QuestBand API running on port ${env.PORT}`);
  });

  const shutdown = async () => {
    logger.info('Shutting down...');
    server.close();
    await getRedis().quit();
    await AppDataSource.destroy();
    process.exit(0);
  };

  process.on('SIGTERM', shutdown);
  process.on('SIGINT', shutdown);
}

bootstrap().catch((err) => {
  logger.error('Failed to start', { error: err.message });
  process.exit(1);
});
