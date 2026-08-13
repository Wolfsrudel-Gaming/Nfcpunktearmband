import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { AppDataSource } from '../config/database.js';
import { User } from '../entities/User.js';
import { Device } from '../entities/Device.js';
import { getEnv } from '../config/env.js';
import { AppError } from '../middleware/error.js';
import { JwtPayload, UserRole } from '../types/index.js';

const userRepo = () => AppDataSource.getRepository(User);
const deviceRepo = () => AppDataSource.getRepository(Device);

const SALT_ROUNDS = 12;

export async function registerUser(data: {
  name: string;
  pin: string;
  role: UserRole;
  email?: string;
  deviceFingerprint?: string;
  deviceName?: string;
  platform?: string;
}) {
  const pinHash = await bcrypt.hash(data.pin, SALT_ROUNDS);

  const user = userRepo().create({
    name: data.name,
    email: data.email ?? null,
    pinHash,
    role: data.role,
  });
  await userRepo().save(user);

  if (data.deviceFingerprint) {
    const device = deviceRepo().create({
      fingerprint: data.deviceFingerprint,
      deviceName: data.deviceName ?? null,
      platform: data.platform ?? null,
      userId: user.id,
    });
    await deviceRepo().save(device);
  }

  return user;
}

export async function login(data: {
  email?: string;
  userId?: string;
  pin: string;
  deviceFingerprint?: string;
  eventId?: string;
}) {
  let user: User | null = null;

  if (data.email) {
    user = await userRepo().findOne({ where: { email: data.email } });
  } else if (data.userId) {
    user = await userRepo().findOne({ where: { id: data.userId } });
  }

  if (!user || !user.active) {
    throw new AppError(401, 'Invalid credentials', 'AUTH_FAILED');
  }

  const valid = await bcrypt.compare(data.pin, user.pinHash);
  if (!valid) {
    throw new AppError(401, 'Invalid credentials', 'AUTH_FAILED');
  }

  if (data.deviceFingerprint) {
    const device = await deviceRepo().findOne({
      where: { userId: user.id, fingerprint: data.deviceFingerprint },
    });
    if (!device) {
      throw new AppError(403, 'Device not registered', 'DEVICE_NOT_BOUND');
    }
    if (!device.trusted) {
      throw new AppError(403, 'Device not trusted', 'DEVICE_NOT_TRUSTED');
    }
  }

  const payload: JwtPayload = {
    userId: user.id,
    role: user.role,
    eventId: data.eventId,
    deviceId: data.deviceFingerprint,
  };

  const token = jwt.sign(payload, getEnv().JWT_SECRET, {
    expiresIn: getEnv().JWT_EXPIRES_IN as string & jwt.SignOptions['expiresIn'],
  } satisfies jwt.SignOptions);

  return { token, user: { id: user.id, name: user.name, role: user.role } };
}

export async function bindDevice(userId: string, fingerprint: string, deviceName?: string, platform?: string) {
  const existing = await deviceRepo().findOne({ where: { userId, fingerprint } });
  if (existing) return existing;

  const device = deviceRepo().create({
    fingerprint,
    deviceName: deviceName ?? null,
    platform: platform ?? null,
    userId,
  });
  return deviceRepo().save(device);
}
