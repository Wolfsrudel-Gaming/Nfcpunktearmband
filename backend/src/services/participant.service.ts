import { AppDataSource } from '../config/database.js';
import { Participant, EmergencyData } from '../entities/Participant.js';
import { NfcTag } from '../entities/NfcTag.js';
import { AppError } from '../middleware/error.js';

const participantRepo = () => AppDataSource.getRepository(Participant);
const nfcRepo = () => AppDataSource.getRepository(NfcTag);

export async function registerParticipant(data: {
  eventId: string;
  displayName: string;
  firstName?: string;
  lastName?: string;
  age?: number;
  group?: string;
  emergencyData?: Partial<EmergencyData>;
  customFields?: Record<string, unknown>;
}) {
  const participant = participantRepo().create({
    eventId: data.eventId,
    displayName: data.displayName,
    firstName: data.firstName ?? null,
    lastName: data.lastName ?? null,
    age: data.age ?? null,
    group: data.group ?? null,
    emergencyData: data.emergencyData ?? {},
    customFields: data.customFields ?? {},
  });
  return participantRepo().save(participant);
}

export async function getParticipant(id: string) {
  const p = await participantRepo().findOne({
    where: { id },
    relations: ['nfcTag', 'transactions'],
  });
  if (!p) throw new AppError(404, 'Participant not found', 'NOT_FOUND');
  return p;
}

export async function listParticipants(eventId: string, search?: string) {
  const qb = participantRepo()
    .createQueryBuilder('p')
    .leftJoinAndSelect('p.nfcTag', 'nfc')
    .where('p.eventId = :eventId', { eventId });

  if (search) {
    qb.andWhere(
      '(p.displayName ILIKE :s OR p.firstName ILIKE :s OR p.lastName ILIKE :s)',
      { s: `%${search}%` },
    );
  }

  qb.orderBy('p.displayName', 'ASC');
  return qb.getMany();
}

export async function updateParticipant(id: string, data: {
  displayName?: string;
  firstName?: string;
  lastName?: string;
  age?: number;
  group?: string;
  emergencyData?: Partial<EmergencyData>;
  customFields?: Record<string, unknown>;
  active?: boolean;
}) {
  const p = await participantRepo().findOne({ where: { id } });
  if (!p) throw new AppError(404, 'Participant not found', 'NOT_FOUND');

  Object.assign(p, {
    ...data,
    emergencyData: data.emergencyData ? { ...p.emergencyData, ...data.emergencyData } : p.emergencyData,
    customFields: data.customFields ? { ...p.customFields, ...data.customFields } : p.customFields,
  });

  return participantRepo().save(p);
}

export async function assignNfcTag(participantId: string, tagUid: string, eventId: string) {
  const participant = await participantRepo().findOne({ where: { id: participantId } });
  if (!participant) throw new AppError(404, 'Participant not found', 'NOT_FOUND');

  const existingTag = await nfcRepo().findOne({ where: { tagUid } });
  if (existingTag?.participantId && existingTag.participantId !== participantId) {
    throw new AppError(409, 'Tag already assigned', 'TAG_IN_USE');
  }

  if (existingTag) {
    existingTag.participantId = participantId;
    existingTag.active = true;
    return nfcRepo().save(existingTag);
  }

  const tag = nfcRepo().create({
    tagUid,
    participantId,
    eventId,
    active: true,
  });
  return nfcRepo().save(tag);
}

export async function getParticipantByTag(tagUid: string) {
  const tag = await nfcRepo().findOne({
    where: { tagUid, active: true },
    relations: ['participant'],
  });
  if (!tag?.participant) throw new AppError(404, 'No participant for this tag', 'NOT_FOUND');
  return tag.participant;
}
