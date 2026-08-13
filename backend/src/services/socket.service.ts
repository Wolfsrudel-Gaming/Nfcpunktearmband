import { Server as SocketServer } from 'socket.io';
import jwt from 'jsonwebtoken';
import { getEnv } from '../config/env.js';
import { logger } from '../utils/logger.js';
import { JwtPayload } from '../types/index.js';

export function setupSocketHandlers(io: SocketServer) {
  io.use((socket, next) => {
    const token = socket.handshake.auth.token as string | undefined;
    if (!token) return next(new Error('Authentication required'));

    try {
      const payload = jwt.verify(token, getEnv().JWT_SECRET) as JwtPayload;
      socket.data.user = payload;
      next();
    } catch {
      next(new Error('Invalid token'));
    }
  });

  io.on('connection', (socket) => {
    const user = socket.data.user as JwtPayload;
    logger.debug('Socket connected', { userId: user.userId });

    if (user.eventId) {
      socket.join(`event:${user.eventId}`);
    }

    socket.on('disconnect', () => {
      logger.debug('Socket disconnected', { userId: user.userId });
    });
  });

  return io;
}

export function emitPointsUpdate(io: SocketServer, eventId: string, participantId: string, balance: number) {
  io.to(`event:${eventId}`).emit('points:update', { participantId, balance });
}
