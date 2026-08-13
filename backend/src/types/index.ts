export enum UserRole {
  ADMIN = 'admin',
  BETREUER = 'betreuer',
  TEILNEHMER = 'teilnehmer',
  ELTERN = 'eltern',
}

export enum EventStatus {
  DRAFT = 'draft',
  ACTIVE = 'active',
  PAUSED = 'paused',
  ARCHIVED = 'archived',
}

export enum PointReason {
  MANUAL = 'manual',
  QUICK_SELECT = 'quick_select',
  TERMINAL = 'terminal',
  P2P = 'p2p',
  QUEST = 'quest',
  BADGE = 'badge',
  REDEMPTION = 'redemption',
}

export interface JwtPayload {
  userId: string;
  role: UserRole;
  eventId?: string;
  deviceId?: string;
}
