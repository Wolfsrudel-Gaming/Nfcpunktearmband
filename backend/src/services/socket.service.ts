import { Server as SocketServer } from 'socket.io';
import jwt from 'jsonwebtoken';
import { getEnv } from '../config/env.js';
import { logger } from '../utils/logger.js';
import { JwtPayload } from '../types/index.js';

let _io: SocketServer | null = null;

export function getIO(): SocketServer {
  if (!_io) throw new Error('Socket.IO not initialized');
  return _io;
}

export function setupSocketHandlers(io: SocketServer) {
  _io = io;

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

    socket.on('join:event', (eventId: string) => {
      socket.join(`event:${eventId}`);
      logger.debug('Socket joined event room', { userId: user.userId, eventId });
    });

    socket.on('leave:event', (eventId: string) => {
      socket.leave(`event:${eventId}`);
      logger.debug('Socket left event room', { userId: user.userId, eventId });
    });

    socket.on('disconnect', () => {
      logger.debug('Socket disconnected', { userId: user.userId });
    });
  });

  return io;
}

export function emitPointsUpdate(eventId: string, participantId: string, balance: number) {
  if (!_io) return;
  _io.to(`event:${eventId}`).emit('points:update', { participantId, balance });
}
