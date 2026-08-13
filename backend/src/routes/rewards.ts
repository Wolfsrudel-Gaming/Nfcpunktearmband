import { Router } from 'express';
import { z } from 'zod';
import * as rewardService from '../services/reward.service.js';
import { authenticate, requireRole } from '../middleware/auth.js';
import { UserRole } from '../types/index.js';

export const rewardRouter = Router();

rewardRouter.use(authenticate);

const createSchema = z.object({
  eventId: z.string().uuid(),
  name: z.string().min(1).max(200),
  description: z.string().optional(),
  cost: z.number().int().min(0),
  stock: z.number().int().min(0).optional(),
  category: z.string().max(100).optional(),
  limitPerParticipant: z.number().int().min(1).optional(),
  sortOrder: z.number().int().optional(),
});

const redeemSchema = z.object({
  rewardId: z.string().uuid(),
  participantId: z.string().uuid(),
  eventId: z.string().uuid(),
});

rewardRouter.post('/', requireRole(UserRole.ADMIN), async (req, res, next) => {
  try {
    const data = createSchema.parse(req.body);
    const reward = await rewardService.createReward(data);
    res.status(201).json(reward);
  } catch (err) {
    next(err);
  }
});

rewardRouter.get('/event/:eventId', async (req, res, next) => {
  try {
    const rewards = await rewardService.listRewards(req.params.eventId);
    res.json(rewards);
  } catch (err) {
    next(err);
  }
});

rewardRouter.get('/:id', async (req, res, next) => {
  try {
    const reward = await rewardService.getReward(req.params.id);
    res.json(reward);
  } catch (err) {
    next(err);
  }
});

rewardRouter.patch('/:id', requireRole(UserRole.ADMIN), async (req, res, next) => {
  try {
    const reward = await rewardService.updateReward(req.params.id, req.body);
    res.json(reward);
  } catch (err) {
    next(err);
  }
});

rewardRouter.post('/redeem', requireRole(UserRole.ADMIN, UserRole.BETREUER), async (req, res, next) => {
  try {
    const data = redeemSchema.parse(req.body);
    const result = await rewardService.redeemReward({
      ...data,
      processedBy: req.user!.userId,
    });
    res.status(201).json(result);
  } catch (err) {
    next(err);
  }
});
