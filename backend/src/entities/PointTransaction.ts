import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn,
  ManyToOne, JoinColumn,
} from 'typeorm';
import { PointReason } from '../types/index.js';
import { Participant } from './Participant.js';
import { Event } from './Event.js';

@Entity('point_transactions')
export class PointTransaction {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'int' })
  amount: number;

  @Column({ type: 'int' })
  balanceAfter: number;

  @Column({ type: 'enum', enum: PointReason })
  reason: PointReason;

  @Column({ length: 255, nullable: true })
  note: string | null;

  @Column({ length: 100, nullable: true })
  pointType: string | null;

  @Column('uuid', { nullable: true })
  givenBy: string | null;

  @Column({ type: 'text', nullable: true })
  signature: string | null;

  @ManyToOne(() => Participant, (p) => p.transactions, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'participantId' })
  participant: Participant;

  @Column('uuid')
  participantId: string;

  @ManyToOne(() => Event, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'eventId' })
  event: Event;

  @Column('uuid')
  eventId: string;

  @CreateDateColumn()
  createdAt: Date;
}
