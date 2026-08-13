import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn,
  ManyToOne, OneToMany, OneToOne, JoinColumn, Unique,
} from 'typeorm';
import { Event } from './Event.js';
import { NfcTag } from './NfcTag.js';
import { PointTransaction } from './PointTransaction.js';
import { Redemption } from './Redemption.js';

@Entity('participants')
@Unique(['eventId', 'displayName'])
export class Participant {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 100 })
  displayName: string;

  @Column({ length: 100, nullable: true })
  firstName: string | null;

  @Column({ length: 100, nullable: true })
  lastName: string | null;

  @Column({ type: 'int', nullable: true })
  age: number | null;

  @Column({ length: 100, nullable: true })
  group: string | null;

  @Column({ type: 'jsonb', default: {} })
  emergencyData: EmergencyData;

  @Column({ type: 'jsonb', default: {} })
  customFields: Record<string, unknown>;

  @Column({ type: 'int', default: 0 })
  balance: number;

  @Column({ default: true })
  active: boolean;

  @ManyToOne(() => Event, (e) => e.participants, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'eventId' })
  event: Event;

  @Column('uuid')
  eventId: string;

  @OneToOne(() => NfcTag, (t) => t.participant, { nullable: true })
  nfcTag: NfcTag | null;

  @OneToMany(() => PointTransaction, (t) => t.participant)
  transactions: PointTransaction[];

  @OneToMany(() => Redemption, (r) => r.participant)
  redemptions: Redemption[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

export interface EmergencyData {
  bloodType?: string;
  allergies?: string[];
  medications?: string[];
  conditions?: string[];
  emergencyContact?: { name: string; phone: string; relation?: string };
  specialNeeds?: string;
}
