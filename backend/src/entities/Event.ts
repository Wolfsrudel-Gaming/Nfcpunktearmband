import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn,
  OneToMany, ManyToMany,
} from 'typeorm';
import { EventStatus } from '../types/index.js';
import { Participant } from './Participant.js';
import { Reward } from './Reward.js';
import { User } from './User.js';

@Entity('events')
export class Event {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 200 })
  name: string;

  @Column({ type: 'text', nullable: true })
  description: string | null;

  @Column({ type: 'enum', enum: EventStatus, default: EventStatus.DRAFT })
  status: EventStatus;

  @Column({ type: 'date', nullable: true })
  startDate: string | null;

  @Column({ type: 'date', nullable: true })
  endDate: string | null;

  @Column({ length: 200, nullable: true })
  location: string | null;

  @Column({ type: 'jsonb', default: {} })
  config: EventConfig;

  @Column({ length: 10, unique: true })
  joinCode: string;

  @ManyToMany(() => User, (u) => u.events)
  betreuer: User[];

  @OneToMany(() => Participant, (p) => p.event)
  participants: Participant[];

  @OneToMany(() => Reward, (r) => r.event)
  rewards: Reward[];

  @Column('uuid')
  createdBy: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

export interface EventConfig {
  pointTypes?: { name: string; icon?: string }[];
  quickSelectValues?: number[];
  allowP2P?: boolean;
  p2pLimit?: number;
  pointDecay?: { enabled: boolean; rate?: number; intervalDays?: number };
  gamification?: { levels?: boolean; badges?: boolean; leaderboard?: boolean };
  penaltySystem?: { enabled: boolean; cards?: boolean; points?: boolean; traffic?: boolean };
}
