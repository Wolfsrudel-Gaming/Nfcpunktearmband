import { Router } from 'express';
import { z } from 'zod';
import * as eventService from '../services/event.service.js';
import { authenticate, requireRole } from '../middleware/auth.js';
import { UserRole, EventStatus } from '../types/index.js';

export const eventRouter = Router();

eventRouter.use(authenticate);

const createSchema = z.object({
  name: z.string().min(1).max(200),
  description: z.string().optional(),
  startDate: z.string().optional(),
  endDate: z.string().optional(),
  location: z.string().optional(),
  config: z.record(z.unknown()).optional(),
});

const updateSchema = z.object({
  name: z.string().min(1).max(200).optional(),
  description: z.string().optional(),
  startDate: z.string().optional(),
  endDate: z.string().optional(),
  location: z.string().optional(),
  status: z.nativeEnum(EventStatus).optional(),
  config: z.record(z.unknown()).optional(),
});

eventRouter.post('/', requireRole(UserRole.ADMIN), async (req, res, next) => {
  try {
    const data = createSchema.parse(req.body);
    const event = await eventService.createEvent({ ...data, createdBy: req.user!.userId });
    res.status(201).json(event);
  } catch (err) {
    next(err);
  }
});

eventRouter.get('/', async (req, res, next) => {
  try {
    const status = typeof req.query.status === 'string' ? req.query.status as EventStatus : undefined;
    const events = await eventService.listEvents({ status });
    res.json(events);
  } catch (err) {
    next(err);
  }
});

eventRouter.get('/join/:code', async (req, res, next) => {
  try {
    const event = await eventService.getEventByJoinCode(req.params.code);
    res.json(event);
  } catch (err) {
    next(err);
  }
});

eventRouter.get('/:id', async (req, res, next) => {
  try {
    const event = await eventService.getEvent(req.params.id);
    res.json(event);
  } catch (err) {
    next(err);
  }
});

eventRouter.patch('/:id', requireRole(UserRole.ADMIN), async (req, res, next) => {
  try {
    const data = updateSchema.parse(req.body);
    const event = await eventService.updateEvent(req.params.id, data);
    res.json(event);
  } catch (err) {
    next(err);
  }
});

eventRouter.post('/:id/archive', requireRole(UserRole.ADMIN), async (req, res, next) => {
  try {
    const event = await eventService.archiveEvent(req.params.id);
    res.json(event);
  } catch (err) {
    next(err);
  }
});
