import { Router } from 'express';
import { z } from 'zod';
import * as authService from '../services/auth.service.js';
import { authenticate, requireRole } from '../middleware/auth.js';
import { UserRole } from '../types/index.js';

export const authRouter = Router();

const registerSchema = z.object({
  name: z.string().min(1).max(100),
  pin: z.string().min(4).max(20),
  role: z.nativeEnum(UserRole),
  email: z.string().email().optional(),
  deviceFingerprint: z.string().optional(),
  deviceName: z.string().optional(),
  platform: z.string().optional(),
});

const loginSchema = z.object({
  email: z.string().email().optional(),
  userId: z.string().uuid().optional(),
  pin: z.string().min(4),
  deviceFingerprint: z.string().optional(),
  eventId: z.string().uuid().optional(),
});

authRouter.post('/register', authenticate, requireRole(UserRole.ADMIN), async (req, res, next) => {
  try {
    const data = registerSchema.parse(req.body);
    const user = await authService.registerUser(data);
    res.status(201).json({ id: user.id, name: user.name, role: user.role });
  } catch (err) {
    next(err);
  }
});

authRouter.post('/login', async (req, res, next) => {
  try {
    const data = loginSchema.parse(req.body);
    const result = await authService.login(data);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

authRouter.post('/device', authenticate, async (req, res, next) => {
  try {
    const { fingerprint, deviceName, platform } = req.body;
    const device = await authService.bindDevice(req.user!.userId, fingerprint, deviceName, platform);
    res.status(201).json({ id: device.id, fingerprint: device.fingerprint });
  } catch (err) {
    next(err);
  }
});
