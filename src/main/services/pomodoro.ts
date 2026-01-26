import { getPrisma } from './storage';
import { addXp, addCoins } from './storage';
import { XP_REWARDS, COIN_REWARDS } from '../../shared/types';

export async function getTodayPomodoroCount(): Promise<number> {
  const prisma = getPrisma();
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const count = await prisma.pomodoroSession.count({
    where: {
      phase: 'work',
      completedAt: {
        not: null,
        gte: today,
      },
      interrupted: false,
    },
  });

  return count;
}

export async function savePomodoroSession(session: {
  taskId: string | null;
  phase: string;
  duration: number;
  startedAt: Date;
  completedAt: Date;
  interrupted: boolean;
}) {
  const prisma = getPrisma();

  // Only award XP for completed work sessions
  const xpEarned = !session.interrupted && session.phase === 'work' ? XP_REWARDS.pomodoro : 0;
  const coinsEarned = !session.interrupted && session.phase === 'work' ? COIN_REWARDS.pomodoro : 0;

  const pomodoroSession = await prisma.pomodoroSession.create({
    data: {
      taskId: session.taskId,
      phase: session.phase,
      duration: session.duration,
      startedAt: session.startedAt,
      completedAt: session.completedAt,
      interrupted: session.interrupted,
      xpEarned,
    },
  });

  // Award XP and coins
  let leveledUp = false;
  let newLevel: number | undefined;

  if (xpEarned > 0) {
    const result = await addXp(xpEarned);
    leveledUp = result?.leveledUp || false;
    newLevel = result?.newLevel;
  }

  if (coinsEarned > 0) {
    await addCoins(coinsEarned);
  }

  return {
    session: pomodoroSession,
    xpEarned,
    coinsEarned,
    leveledUp,
    newLevel,
  };
}

export async function getPomodoroSessions(limit: number = 50) {
  const prisma = getPrisma();
  return await prisma.pomodoroSession.findMany({
    take: limit,
    orderBy: {
      createdAt: 'desc',
    },
    include: {
      task: true,
    },
  });
}
