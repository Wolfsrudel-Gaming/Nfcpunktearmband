import { AppDataSource } from '../config/database.js';
import { PointTransaction } from '../entities/PointTransaction.js';
import { Participant } from '../entities/Participant.js';
import { AppError } from '../middleware/error.js';
import { PointReason } from '../types/index.js';
import crypto from 'crypto';

const txRepo = () => AppDataSource.getRepository(PointTransaction);
const participantRepo = () => AppDataSource.getRepository(Participant);

function signTransaction(tx: { participantId: string; amount: number; balanceAfter: number; createdAt: Date }): string {
  const data = `${tx.participantId}:${tx.amount}:${tx.balanceAfter}:${tx.createdAt.toISOString()}`;
  return crypto.createHash('sha256').update(data).digest('hex');
}

export async function bookPoints(data: {
  participantId: string;
  eventId: string;
  amount: number;
  reason: PointReason;
  note?: string;
  pointType?: string;
  givenBy?: string;
}) {
  return AppDataSource.transaction(async (manager) => {
    const participant = await manager.findOne(Participant, {
      where: { id: data.participantId },
      lock: { mode: 'pessimistic_write' },
    });
    if (!participant) throw new AppError(404, 'Participant not found', 'NOT_FOUND');

    const newBalance = participant.balance + data.amount;

    const tx = manager.create(PointTransaction, {
      participantId: data.participantId,
      eventId: data.eventId,
      amount: data.amount,
      balanceAfter: newBalance,
      reason: data.reason,
      note: data.note ?? null,
      pointType: data.pointType ?? null,
      givenBy: data.givenBy ?? null,
    });

    const savedTx = await manager.save(PointTransaction, tx);
    savedTx.signature = signTransaction(savedTx);
    await manager.save(PointTransaction, savedTx);

    participant.balance = newBalance;
    await manager.save(Participant, participant);

    return { transaction: savedTx, balance: newBalance };
  });
}

export async function bookBatch(entries: Array<{
  participantId: string;
  eventId: string;
  amount: number;
  reason: PointReason;
  note?: string;
  pointType?: string;
  givenBy?: string;
}>) {
  const results = [];
  for (const entry of entries) {
    results.push(await bookPoints(entry));
  }
  return results;
}

export async function getTransactions(participantId: string, limit = 50, offset = 0) {
  return txRepo().find({
    where: { participantId },
    order: { createdAt: 'DESC' },
    take: limit,
    skip: offset,
  });
}

export async function getEventTransactions(eventId: string, limit = 100, offset = 0) {
  return txRepo().find({
    where: { eventId },
    order: { createdAt: 'DESC' },
    take: limit,
    skip: offset,
    relations: ['participant'],
  });
}

export async function getLeaderboard(eventId: string, limit = 50) {
  return participantRepo()
    .createQueryBuilder('p')
    .where('p.eventId = :eventId', { eventId })
    .andWhere('p.active = true')
    .orderBy('p.balance', 'DESC')
    .limit(limit)
    .select(['p.id', 'p.displayName', 'p.group', 'p.balance'])
    .getMany();
}
