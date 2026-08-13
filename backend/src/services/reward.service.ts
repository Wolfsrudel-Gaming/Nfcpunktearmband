import { AppDataSource } from '../config/database.js';
import { Reward } from '../entities/Reward.js';
import { Redemption } from '../entities/Redemption.js';
import { Participant } from '../entities/Participant.js';
import { PointTransaction } from '../entities/PointTransaction.js';
import { AppError } from '../middleware/error.js';
import { PointReason } from '../types/index.js';

const rewardRepo = () => AppDataSource.getRepository(Reward);
const redemptionRepo = () => AppDataSource.getRepository(Redemption);

export async function createReward(data: {
  eventId: string;
  name: string;
  description?: string;
  cost: number;
  stock?: number;
  category?: string;
  limitPerParticipant?: number;
  sortOrder?: number;
}) {
  const reward = rewardRepo().create({
    eventId: data.eventId,
    name: data.name,
    description: data.description ?? null,
    cost: data.cost,
    stock: data.stock ?? null,
    category: data.category ?? null,
    limitPerParticipant: data.limitPerParticipant ?? null,
    sortOrder: data.sortOrder ?? 0,
  });
  return rewardRepo().save(reward);
}

export async function listRewards(eventId: string) {
  return rewardRepo().find({
    where: { eventId },
    order: { sortOrder: 'ASC', name: 'ASC' },
  });
}

export async function getReward(id: string) {
  const reward = await rewardRepo().findOne({ where: { id } });
  if (!reward) throw new AppError(404, 'Reward not found', 'NOT_FOUND');
  return reward;
}

export async function updateReward(id: string, data: Partial<{
  name: string;
  description: string;
  cost: number;
  stock: number;
  category: string;
  limitPerParticipant: number;
  available: boolean;
  sortOrder: number;
}>) {
  const reward = await rewardRepo().findOne({ where: { id } });
  if (!reward) throw new AppError(404, 'Reward not found', 'NOT_FOUND');
  Object.assign(reward, data);
  return rewardRepo().save(reward);
}

export async function redeemReward(data: {
  rewardId: string;
  participantId: string;
  eventId: string;
  processedBy?: string;
}) {
  return AppDataSource.transaction(async (manager) => {
    const reward = await manager.findOne(Reward, {
      where: { id: data.rewardId },
      lock: { mode: 'pessimistic_write' },
    });
    if (!reward) throw new AppError(404, 'Reward not found', 'NOT_FOUND');
    if (!reward.available) throw new AppError(400, 'Reward not available', 'REWARD_UNAVAILABLE');
    if (reward.stock !== null && reward.redeemed >= reward.stock) {
      throw new AppError(400, 'Reward out of stock', 'REWARD_OUT_OF_STOCK');
    }

    const participant = await manager.findOne(Participant, {
      where: { id: data.participantId },
      lock: { mode: 'pessimistic_write' },
    });
    if (!participant) throw new AppError(404, 'Participant not found', 'NOT_FOUND');
    if (participant.balance < reward.cost) {
      throw new AppError(400, 'Insufficient points', 'INSUFFICIENT_POINTS');
    }

    if (reward.limitPerParticipant !== null) {
      const count = await manager.count(Redemption, {
        where: { rewardId: data.rewardId, participantId: data.participantId },
      });
      if (count >= reward.limitPerParticipant) {
        throw new AppError(400, 'Redemption limit reached', 'LIMIT_REACHED');
      }
    }

    participant.balance -= reward.cost;
    reward.redeemed += 1;

    const tx = manager.create(PointTransaction, {
      participantId: data.participantId,
      eventId: data.eventId,
      amount: -reward.cost,
      balanceAfter: participant.balance,
      reason: PointReason.REDEMPTION,
      note: `Reward: ${reward.name}`,
      givenBy: data.processedBy ?? null,
    });

    const redemption = manager.create(Redemption, {
      rewardId: data.rewardId,
      participantId: data.participantId,
      eventId: data.eventId,
      cost: reward.cost,
      processedBy: data.processedBy ?? null,
    });

    await manager.save(Participant, participant);
    await manager.save(Reward, reward);
    await manager.save(PointTransaction, tx);
    const saved = await manager.save(Redemption, redemption);

    return { redemption: saved, balance: participant.balance };
  });
}
