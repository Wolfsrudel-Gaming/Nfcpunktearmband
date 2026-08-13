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
import { logger } from './utils/logger.js';

export const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '1mb' }));

app.use((req, _res, next) => {
  logger.debug(`${req.method} ${req.path}`);
  next();
});

app.use('/health', healthRouter);
app.use('/api/auth', authRouter);
app.use('/api/events', eventRouter);
app.use('/api/participants', participantRouter);
app.use('/api/points', pointsRouter);
app.use('/api/rewards', rewardRouter);

app.use(errorHandler);
