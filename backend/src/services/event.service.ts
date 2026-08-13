import { AppDataSource } from '../config/database.js';
import { Event, EventConfig } from '../entities/Event.js';
import { AppError } from '../middleware/error.js';
import { EventStatus } from '../types/index.js';

const repo = () => AppDataSource.getRepository(Event);

function generateJoinCode(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }
  return code;
}

export async function createEvent(data: {
  name: string;
  description?: string;
  startDate?: string;
  endDate?: string;
  location?: string;
  config?: Partial<EventConfig>;
  createdBy: string;
}) {
  let joinCode: string;
  do {
    joinCode = generateJoinCode();
  } while (await repo().findOne({ where: { joinCode } }));

  const event = repo().create({
    name: data.name,
    description: data.description ?? null,
    startDate: data.startDate ?? null,
    endDate: data.endDate ?? null,
    location: data.location ?? null,
    config: data.config ?? {},
    joinCode,
    createdBy: data.createdBy,
  });

  return repo().save(event);
}

export async function getEvent(id: string) {
  const event = await repo().findOne({ where: { id }, relations: ['participants', 'rewards'] });
  if (!event) throw new AppError(404, 'Event not found', 'NOT_FOUND');
  return event;
}

export async function listEvents(filters?: { status?: EventStatus; createdBy?: string }) {
  const qb = repo().createQueryBuilder('event');
  if (filters?.status) qb.andWhere('event.status = :status', { status: filters.status });
  if (filters?.createdBy) qb.andWhere('event.createdBy = :createdBy', { createdBy: filters.createdBy });
  qb.orderBy('event.createdAt', 'DESC');
  return qb.getMany();
}

export async function updateEvent(id: string, data: {
  name?: string;
  description?: string;
  startDate?: string;
  endDate?: string;
  location?: string;
  status?: EventStatus;
  config?: Partial<EventConfig>;
}) {
  const event = await repo().findOne({ where: { id } });
  if (!event) throw new AppError(404, 'Event not found', 'NOT_FOUND');

  if (data.name !== undefined) event.name = data.name;
  if (data.description !== undefined) event.description = data.description;
  if (data.startDate !== undefined) event.startDate = data.startDate;
  if (data.endDate !== undefined) event.endDate = data.endDate;
  if (data.location !== undefined) event.location = data.location;
  if (data.status !== undefined) event.status = data.status;
  if (data.config !== undefined) event.config = { ...event.config, ...data.config };

  return repo().save(event);
}

export async function archiveEvent(id: string) {
  return updateEvent(id, { status: EventStatus.ARCHIVED });
}

export async function getEventByJoinCode(joinCode: string) {
  const event = await repo().findOne({ where: { joinCode } });
  if (!event) throw new AppError(404, 'Event not found', 'NOT_FOUND');
  return event;
}
