import { DataSource } from 'typeorm';
import { getEnv } from './env.js';

const env = getEnv();

export const AppDataSource = new DataSource({
  type: 'postgres',
  host: env.DB_HOST,
  port: env.DB_PORT,
  database: env.DB_NAME,
  username: env.DB_USER,
  password: env.DB_PASSWORD,
  entities: [__dirname + '/../entities/*.{ts,js}'],
  migrations: [__dirname + '/../../migrations/*.{ts,js}'],
  synchronize: env.NODE_ENV === 'development',
  logging: env.NODE_ENV === 'development' ? ['error', 'warn'] : ['error'],
});
