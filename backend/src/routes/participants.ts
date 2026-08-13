import { Router } from 'express';
import { z } from 'zod';
import * as participantService from '../services/participant.service.js';
import { authenticate, requireRole } from '../middleware/auth.js';
import { UserRole } from '../types/index.js';

export const participantRouter = Router();

participantRouter.use(authenticate);

const registerSchema = z.object({
  eventId: z.string().uuid(),
  displayName: z.string().min(1).max(100),
  firstName: z.string().max(100).optional(),
  lastName: z.string().max(100).optional(),
  age: z.number().int().min(0).max(150).optional(),
  group: z.string().max(100).optional(),
  emergencyData: z.record(z.unknown()).optional(),
  customFields: z.record(z.unknown()).optional(),
});

participantRouter.post('/', requireRole(UserRole.ADMIN, UserRole.BETREUER), async (req, res, next) => {
  try {
    const data = registerSchema.parse(req.body);
    const participant = await participantService.registerParticipant(data);
    res.status(201).json(participant);
  } catch (err) {
    next(err);
  }
});

participantRouter.get('/event/:eventId', async (req, res, next) => {
  try {
    const search = req.query.search as string | undefined;
    const participants = await participantService.listParticipants(req.params.eventId, search);
    res.json(participants);
  } catch (err) {
    next(err);
  }
});

participantRouter.get('/tag/:tagUid', async (req, res, next) => {
  try {
    const participant = await participantService.getParticipantByTag(req.params.tagUid);
    res.json(participant);
  } catch (err) {
    next(err);
  }
});

participantRouter.get('/:id', async (req, res, next) => {
  try {
    const participant = await participantService.getParticipant(req.params.id);
    res.json(participant);
  } catch (err) {
    next(err);
  }
});

participantRouter.patch('/:id', requireRole(UserRole.ADMIN, UserRole.BETREUER), async (req, res, next) => {
  try {
    const participant = await participantService.updateParticipant(req.params.id, req.body);
    res.json(participant);
  } catch (err) {
    next(err);
  }
});

participantRouter.post('/:id/nfc', requireRole(UserRole.ADMIN, UserRole.BETREUER), async (req, res, next) => {
  try {
    const { tagUid, eventId } = req.body;
    const tag = await participantService.assignNfcTag(req.params.id, tagUid, eventId);
    res.status(201).json(tag);
  } catch (err) {
    next(err);
  }
});
