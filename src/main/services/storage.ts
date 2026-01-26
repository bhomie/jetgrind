import { PrismaClient } from '@prisma/client';
import { app } from 'electron';
import { join } from 'path';
import { calculateLevelFromXp } from '../../shared/types';

let prisma: PrismaClient;

export async function initDatabase(): Promise<void> {
  const isDev = process.env.NODE_ENV === 'development' || !app.isPackaged;

  // In production, use userData path for database
  const dbPath = isDev
    ? join(process.cwd(), 'prisma', 'jetgrind.db')
    : join(app.getPath('userData'), 'jetgrind.db');

  prisma = new PrismaClient({
    datasources: {
      db: {
        url: `file:${dbPath}`,
      },
    },
  });

  await prisma.$connect();

  // Ensure user exists
  const userCount = await prisma.user.count();
  if (userCount === 0) {
    await prisma.user.create({
      data: {
        coins: 100,
        xp: 0,
        level: 1,
        streak: 0,
      },
    });
  }
}

export function getPrisma(): PrismaClient {
  return prisma;
}

export async function getUser() {
  const user = await prisma.user.findFirst();
  return user;
}

export async function updateUser(data: Partial<{ settings: string }>) {
  const user = await prisma.user.findFirst();
  if (!user) return null;

  return await prisma.user.update({
    where: { id: user.id },
    data: {
      ...data,
      updatedAt: new Date(),
    },
  });
}

export async function addXp(amount: number) {
  const user = await prisma.user.findFirst();
  if (!user) return null;

  const newXp = user.xp + amount;
  const newLevel = calculateLevelFromXp(newXp);
  const leveledUp = newLevel > user.level;

  const updatedUser = await prisma.user.update({
    where: { id: user.id },
    data: {
      xp: newXp,
      level: newLevel,
      updatedAt: new Date(),
    },
  });

  return { user: updatedUser, leveledUp, newLevel };
}

export async function addCoins(amount: number) {
  const user = await prisma.user.findFirst();
  if (!user) return null;

  return await prisma.user.update({
    where: { id: user.id },
    data: {
      coins: user.coins + amount,
      updatedAt: new Date(),
    },
  });
}

export async function updateStreak() {
  const user = await prisma.user.findFirst();
  if (!user) return null;

  const today = new Date().toISOString().split('T')[0];
  const lastActive = user.lastActiveDate;

  let newStreak = user.streak;

  if (!lastActive) {
    newStreak = 1;
  } else {
    const lastDate = new Date(lastActive);
    const todayDate = new Date(today);
    const diffDays = Math.floor((todayDate.getTime() - lastDate.getTime()) / (1000 * 60 * 60 * 24));

    if (diffDays === 1) {
      newStreak = user.streak + 1;
    } else if (diffDays > 1) {
      newStreak = 1;
    }
  }

  return await prisma.user.update({
    where: { id: user.id },
    data: {
      streak: newStreak,
      lastActiveDate: today,
      updatedAt: new Date(),
    },
  });
}
