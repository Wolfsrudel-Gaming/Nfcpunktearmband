import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { errorHandler } from './middleware/error.js';
import { healthRouter } from './routes/health.js';
import { authRouter } from './routes/auth.js';
import { eventRouter } from './routes/events.js';
import { participantRouter } from './routes/participants.js';
import { pointsRouter } from './routes/points.js';
import { rewardRouter } from './routes/rewards.js';
import { getEnv } from './config/env.js';
import { logger } from './utils/logger.js';

export const app = express();

const env = getEnv();
const corsOrigin = env.CORS_ORIGIN === '*' ? true : env.CORS_ORIGIN.split(',');
const prefix = env.API_PREFIX;

app.use(helmet());
app.use(cors({ origin: corsOrigin, credentials: true }));
app.use(express.json({ limit: '1mb' }));

app.use((req, _res, next) => {
  logger.debug(`${req.method} ${req.path}`);
  next();
});

app.use(`${prefix}/health`, healthRouter);
app.use(`${prefix}/api/auth`, authRouter);
app.use(`${prefix}/api/events`, eventRouter);
app.use(`${prefix}/api/participants`, participantRouter);
app.use(`${prefix}/api/points`, pointsRouter);
app.use(`${prefix}/api/rewards`, rewardRouter);

app.use(errorHandler);
