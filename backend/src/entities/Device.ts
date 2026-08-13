import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, JoinColumn,
} from 'typeorm';
import { User } from './User.js';

@Entity('devices')
export class Device {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 255 })
  fingerprint: string;

  @Column({ length: 100, nullable: true })
  deviceName: string | null;

  @Column({ length: 50, nullable: true })
  platform: string | null;

  @Column({ default: true })
  trusted: boolean;

  @ManyToOne(() => User, (u) => u.devices, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column('uuid')
  userId: string;

  @CreateDateColumn()
  createdAt: Date;
}
