import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn,
  OneToOne, JoinColumn, ManyToOne,
} from 'typeorm';
import { Participant } from './Participant.js';
import { Event } from './Event.js';

@Entity('nfc_tags')
export class NfcTag {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 100, unique: true })
  tagUid: string;

  @Column({ type: 'text', nullable: true })
  serverToken: string | null;

  @Column({ default: true })
  active: boolean;

  @Column({ length: 50, nullable: true })
  color: string | null;

  @OneToOne(() => Participant, (p) => p.nfcTag, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'participantId' })
  participant: Participant | null;

  @Column('uuid', { nullable: true })
  participantId: string | null;

  @ManyToOne(() => Event, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'eventId' })
  event: Event;

  @Column('uuid')
  eventId: string;

  @CreateDateColumn()
  createdAt: Date;
}
