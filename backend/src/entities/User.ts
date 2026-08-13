import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn,
  OneToMany, ManyToMany, JoinTable,
} from 'typeorm';
import { UserRole } from '../types/index.js';
import { Device } from './Device.js';
import { Event } from './Event.js';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 100 })
  name: string;

  @Column({ length: 255, unique: true, nullable: true })
  email: string | null;

  @Column({ length: 255 })
  pinHash: string;

  @Column({ type: 'enum', enum: UserRole })
  role: UserRole;

  @Column({ default: true })
  active: boolean;

  @OneToMany(() => Device, (d) => d.user)
  devices: Device[];

  @ManyToMany(() => Event, (e) => e.betreuer)
  @JoinTable({ name: 'event_betreuer' })
  events: Event[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
