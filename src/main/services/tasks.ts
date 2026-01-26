import { getPrisma } from './storage';
import { addXp, addCoins } from './storage';
import { XP_REWARDS, COIN_REWARDS, type TaskSize } from '../../shared/types';

export async function getAllTasks() {
  const prisma = getPrisma();
  return await prisma.task.findMany({
    where: {
      parentId: null,
    },
    include: {
      subtasks: true,
    },
    orderBy: {
      createdAt: 'desc',
    },
  });
}

export async function getTask(id: string) {
  const prisma = getPrisma();
  return await prisma.task.findUnique({
    where: { id },
    include: {
      subtasks: true,
    },
  });
}

export async function createTask(data: {
  title: string;
  description?: string;
  priority?: string;
  size?: string;
  parentId?: string | null;
  dueDate?: Date | null;
}) {
  const prisma = getPrisma();

  const size = (data.size || 'medium') as TaskSize;
  const xpReward = XP_REWARDS[size];
  const coinReward = COIN_REWARDS[size];

  return await prisma.task.create({
    data: {
      title: data.title,
      description: data.description || null,
      priority: data.priority || 'medium',
      size: size,
      parentId: data.parentId || null,
      dueDate: data.dueDate || null,
      xpReward,
      coinReward,
    },
  });
}

export async function updateTask(
  id: string,
  data: Partial<{
    title: string;
    description: string;
    status: string;
    priority: string;
    size: string;
    dueDate: Date | null;
  }>
) {
  const prisma = getPrisma();

  // Recalculate rewards if size changed
  let xpReward: number | undefined;
  let coinReward: number | undefined;

  if (data.size) {
    const size = data.size as TaskSize;
    xpReward = XP_REWARDS[size];
    coinReward = COIN_REWARDS[size];
  }

  return await prisma.task.update({
    where: { id },
    data: {
      ...data,
      ...(xpReward !== undefined && { xpReward }),
      ...(coinReward !== undefined && { coinReward }),
      updatedAt: new Date(),
    },
  });
}

export async function deleteTask(id: string) {
  const prisma = getPrisma();
  return await prisma.task.delete({
    where: { id },
  });
}

export async function completeTask(id: string) {
  const prisma = getPrisma();

  const task = await prisma.task.findUnique({
    where: { id },
  });

  if (!task) return null;

  // Update task status
  const completedTask = await prisma.task.update({
    where: { id },
    data: {
      status: 'completed',
      completedAt: new Date(),
      updatedAt: new Date(),
    },
  });

  // Award XP and coins
  const xpResult = await addXp(task.xpReward);
  await addCoins(task.coinReward);

  return {
    task: completedTask,
    xpEarned: task.xpReward,
    coinsEarned: task.coinReward,
    leveledUp: xpResult?.leveledUp || false,
    newLevel: xpResult?.newLevel,
  };
}

export async function getTasksCompletedToday(): Promise<number> {
  const prisma = getPrisma();
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const count = await prisma.task.count({
    where: {
      status: 'completed',
      completedAt: {
        gte: today,
      },
    },
  });

  return count;
}

export async function getOverdueTasksCount(): Promise<number> {
  const prisma = getPrisma();
  const now = new Date();

  const count = await prisma.task.count({
    where: {
      status: {
        not: 'completed',
      },
      dueDate: {
        lt: now,
      },
    },
  });

  return count;
}
