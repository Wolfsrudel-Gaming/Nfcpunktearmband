import 'reflect-metadata';
import bcrypt from 'bcrypt';
import { AppDataSource } from './config/database.js';
import { User } from './entities/User.js';
import { Event } from './entities/Event.js';
import { Participant } from './entities/Participant.js';
import { Reward } from './entities/Reward.js';
import { UserRole, EventStatus } from './types/index.js';
import { logger } from './utils/logger.js';

async function seed() {
  await AppDataSource.initialize();
  logger.info('Seeding database...');

  const userRepo = AppDataSource.getRepository(User);
  const eventRepo = AppDataSource.getRepository(Event);
  const participantRepo = AppDataSource.getRepository(Participant);
  const rewardRepo = AppDataSource.getRepository(Reward);

  const pinHash = await bcrypt.hash('1234', 12);

  const admin = await userRepo.save(
    userRepo.create({ name: 'Admin', email: 'admin@questband.local', pinHash, role: UserRole.ADMIN }),
  );

  const betreuer1 = await userRepo.save(
    userRepo.create({ name: 'Max Betreuer', email: 'max@questband.local', pinHash, role: UserRole.BETREUER }),
  );

  const betreuer2 = await userRepo.save(
    userRepo.create({ name: 'Lisa Betreuer', email: 'lisa@questband.local', pinHash, role: UserRole.BETREUER }),
  );

  const event = await eventRepo.save(
    eventRepo.create({
      name: 'Sommercamp 2026',
      description: 'Das grosse Sommercamp im Schwarzwald',
      status: EventStatus.ACTIVE,
      startDate: '2026-08-15',
      endDate: '2026-08-22',
      location: 'Schwarzwald, Deutschland',
      joinCode: 'CAMP26',
      createdBy: admin.id,
      config: {
        quickSelectValues: [1, 2, 5, 10],
        allowP2P: true,
        p2pLimit: 20,
        gamification: { levels: true, badges: true, leaderboard: true },
      },
    }),
  );

  const names = [
    'Anna Schmidt', 'Ben Mueller', 'Clara Fischer', 'David Weber',
    'Emma Braun', 'Felix Schulz', 'Greta Hoffmann', 'Hugo Koch',
    'Ida Wagner', 'Jan Becker', 'Klara Schaefer', 'Leon Bauer',
    'Mia Klein', 'Nico Wolf', 'Olivia Richter',
  ];

  const groups = ['Adler', 'Baeren', 'Delfine'];

  const participants = [];
  for (const [i, fullName] of names.entries()) {
    const [firstName, lastName] = fullName.split(' ');
    const p = await participantRepo.save(
      participantRepo.create({
        displayName: firstName,
        firstName,
        lastName,
        age: 10 + Math.floor(Math.random() * 6),
        group: groups[i % groups.length],
        eventId: event.id,
        balance: Math.floor(Math.random() * 50),
        emergencyData: {
          emergencyContact: { name: `Eltern ${lastName}`, phone: '+49 170 1234567' },
        },
      }),
    );
    participants.push(p);
  }

  const rewards = [
    { name: 'Eis', cost: 5, stock: 50, category: 'Snacks' },
    { name: 'Extra Freizeit', cost: 15, stock: null, category: 'Privilegien' },
    { name: 'Lagerfeuer-DJ', cost: 25, stock: 3, category: 'Privilegien' },
    { name: 'Mystery-Box', cost: 30, stock: 10, category: 'Specials' },
    { name: 'Nachtspiel-Teilnahme', cost: 10, stock: 20, category: 'Aktivitaeten' },
    { name: 'Camp-T-Shirt', cost: 50, stock: 15, category: 'Merch', limitPerParticipant: 1 },
  ];

  for (const [i, r] of rewards.entries()) {
    await rewardRepo.save(
      rewardRepo.create({ ...r, eventId: event.id, sortOrder: i }),
    );
  }

  logger.info('Seed complete', {
    users: 3,
    events: 1,
    participants: participants.length,
    rewards: rewards.length,
  });

  logger.info('Demo-Login: admin@questband.local / PIN: 1234');

  await AppDataSource.destroy();
}

seed().catch((err) => {
  logger.error('Seed failed', { error: err.message });
  process.exit(1);
});
