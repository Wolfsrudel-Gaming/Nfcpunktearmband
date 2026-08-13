import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn,
  ManyToOne, JoinColumn,
} from 'typeorm';
import { Participant } from './Participant.js';
import { Reward } from './Reward.js';

@Entity('redemptions')
export class Redemption {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'int' })
  cost: number;

  @Column('uuid', { nullable: true })
  processedBy: string | null;

  @ManyToOne(() => Participant, (p) => p.redemptions, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'participantId' })
  participant: Participant;

  @Column('uuid')
  participantId: string;

  @ManyToOne(() => Reward, (r) => r.redemptions, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'rewardId' })
  reward: Reward;

  @Column('uuid')
  rewardId: string;

  @Column('uuid')
  eventId: string;

  @CreateDateColumn()
  createdAt: Date;
}
