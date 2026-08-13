import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn,
  ManyToOne, OneToMany, JoinColumn,
} from 'typeorm';
import { Event } from './Event.js';
import { Redemption } from './Redemption.js';

@Entity('rewards')
export class Reward {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 200 })
  name: string;

  @Column({ type: 'text', nullable: true })
  description: string | null;

  @Column({ type: 'int' })
  cost: number;

  @Column({ type: 'int', nullable: true })
  stock: number | null;

  @Column({ type: 'int', default: 0 })
  redeemed: number;

  @Column({ length: 100, nullable: true })
  category: string | null;

  @Column({ type: 'int', nullable: true })
  limitPerParticipant: number | null;

  @Column({ default: true })
  available: boolean;

  @Column({ type: 'int', default: 0 })
  sortOrder: number;

  @ManyToOne(() => Event, (e) => e.rewards, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'eventId' })
  event: Event;

  @Column('uuid')
  eventId: string;

  @OneToMany(() => Redemption, (r) => r.reward)
  redemptions: Redemption[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
