import { Router } from 'express';
import { z } from 'zod';
import * as pointsService from '../services/points.service.js';
import { authenticate, requireRole } from '../middleware/auth.js';
import { UserRole, PointReason } from '../types/index.js';

export const pointsRouter = Router();

pointsRouter.use(authenticate);

const bookSchema = z.object({
  participantId: z.string().uuid(),
  eventId: z.string().uuid(),
  amount: z.number().int(),
  reason: z.nativeEnum(PointReason),
  note: z.string().max(255).optional(),
  pointType: z.string().max(100).optional(),
});

const batchSchema = z.object({
  entries: z.array(bookSchema).min(1).max(200),
});

pointsRouter.post('/', requireRole(UserRole.ADMIN, UserRole.BETREUER), async (req, res, next) => {
  try {
    const data = bookSchema.parse(req.body);
    const result = await pointsService.bookPoints({ ...data, givenBy: req.user!.userId });
    res.status(201).json(result);
  } catch (err) {
    next(err);
  }
});

pointsRouter.post('/batch', requireRole(UserRole.ADMIN, UserRole.BETREUER), async (req, res, next) => {
  try {
    const { entries } = batchSchema.parse(req.body);
    const results = await pointsService.bookBatch(
      entries.map((e) => ({ ...e, givenBy: req.user!.userId })),
    );
    res.status(201).json(results);
  } catch (err) {
    next(err);
  }
});

pointsRouter.get('/participant/:participantId', async (req, res, next) => {
  try {
    const limit = parseInt(req.query.limit as string) || 50;
    const offset = parseInt(req.query.offset as string) || 0;
    const transactions = await pointsService.getTransactions(req.params.participantId, limit, offset);
    res.json(transactions);
  } catch (err) {
    next(err);
  }
});

pointsRouter.get('/event/:eventId', requireRole(UserRole.ADMIN, UserRole.BETREUER), async (req, res, next) => {
  try {
    const limit = parseInt(req.query.limit as string) || 100;
    const offset = parseInt(req.query.offset as string) || 0;
    const transactions = await pointsService.getEventTransactions(req.params.eventId, limit, offset);
    res.json(transactions);
  } catch (err) {
    next(err);
  }
});

pointsRouter.get('/leaderboard/:eventId', async (req, res, next) => {
  try {
    const limit = parseInt(req.query.limit as string) || 50;
    const leaderboard = await pointsService.getLeaderboard(req.params.eventId, limit);
    res.json(leaderboard);
  } catch (err) {
    next(err);
  }
});
