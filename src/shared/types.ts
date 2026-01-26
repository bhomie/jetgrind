import { z } from 'zod';

// ============================================
// User & Gamification Types
// ============================================

export const UserSchema = z.object({
  id: z.string(),
  xp: z.number().min(0),
  level: z.number().min(1).max(100),
  coins: z.number().min(0),
  streak: z.number().min(0),
  lastActiveDate: z.string().nullable(),
  settings: z.record(z.unknown()).optional(),
  createdAt: z.date(),
  updatedAt: z.date(),
});

export type User = z.infer<typeof UserSchema>;

// ============================================
// Task Types
// ============================================

export const TaskPrioritySchema = z.enum(['low', 'medium', 'high']);
export type TaskPriority = z.infer<typeof TaskPrioritySchema>;

export const TaskStatusSchema = z.enum(['pending', 'in_progress', 'completed']);
export type TaskStatus = z.infer<typeof TaskStatusSchema>;

export const TaskSizeSchema = z.enum(['small', 'medium', 'large']);
export type TaskSize = z.infer<typeof TaskSizeSchema>;

export const TaskSchema = z.object({
  id: z.string(),
  title: z.string().min(1),
  description: z.string().optional(),
  status: TaskStatusSchema,
  priority: TaskPrioritySchema,
  size: TaskSizeSchema,
  parentId: z.string().nullable(),
  dueDate: z.date().nullable(),
  completedAt: z.date().nullable(),
  xpReward: z.number().min(0),
  coinReward: z.number().min(0),
  createdAt: z.date(),
  updatedAt: z.date(),
});

export type Task = z.infer<typeof TaskSchema>;

export const CreateTaskSchema = TaskSchema.omit({
  id: true,
  createdAt: true,
  updatedAt: true,
  completedAt: true,
}).partial({
  status: true,
  priority: true,
  size: true,
  parentId: true,
  dueDate: true,
  xpReward: true,
  coinReward: true,
  description: true,
});

export type CreateTask = z.infer<typeof CreateTaskSchema>;

export const UpdateTaskSchema = CreateTaskSchema.partial();
export type UpdateTask = z.infer<typeof UpdateTaskSchema>;

// ============================================
// Pomodoro Types
// ============================================

export const PomodoroPhaseSchema = z.enum(['work', 'short_break', 'long_break']);
export type PomodoroPhase = z.infer<typeof PomodoroPhaseSchema>;

export const TimerStateSchema = z.enum(['idle', 'running', 'paused', 'completed']);
export type TimerState = z.infer<typeof TimerStateSchema>;

export const PomodoroSessionSchema = z.object({
  id: z.string(),
  taskId: z.string().nullable(),
  phase: PomodoroPhaseSchema,
  duration: z.number().positive(),
  startedAt: z.date(),
  completedAt: z.date().nullable(),
  interrupted: z.boolean(),
  xpEarned: z.number().min(0),
  createdAt: z.date(),
});

export type PomodoroSession = z.infer<typeof PomodoroSessionSchema>;

export const TimerSettingsSchema = z.object({
  workDuration: z.number().min(1).max(120).default(25),
  shortBreakDuration: z.number().min(1).max(60).default(5),
  longBreakDuration: z.number().min(1).max(60).default(15),
  longBreakInterval: z.number().min(1).max(10).default(4),
  autoStartBreaks: z.boolean().default(false),
  autoStartPomodoros: z.boolean().default(false),
  soundEnabled: z.boolean().default(true),
  notificationsEnabled: z.boolean().default(true),
});

export type TimerSettings = z.infer<typeof TimerSettingsSchema>;

// ============================================
// Shop & Inventory Types
// ============================================

export const CosmeticTypeSchema = z.enum(['hat', 'accessory', 'background', 'outfit', 'effect']);
export type CosmeticType = z.infer<typeof CosmeticTypeSchema>;

export const RaritySchema = z.enum(['common', 'uncommon', 'rare', 'epic', 'legendary']);
export type Rarity = z.infer<typeof RaritySchema>;

export const ShopItemSchema = z.object({
  id: z.string(),
  name: z.string(),
  description: z.string(),
  type: CosmeticTypeSchema,
  rarity: RaritySchema,
  price: z.number().min(0),
  isPremium: z.boolean(),
  requiredLevel: z.number().min(1).max(100),
  imageUrl: z.string(),
  createdAt: z.date(),
});

export type ShopItem = z.infer<typeof ShopItemSchema>;

export const InventoryItemSchema = z.object({
  id: z.string(),
  userId: z.string(),
  shopItemId: z.string(),
  acquiredAt: z.date(),
});

export type InventoryItem = z.infer<typeof InventoryItemSchema>;

export const EquippedCosmeticSchema = z.object({
  id: z.string(),
  userId: z.string(),
  shopItemId: z.string(),
  slot: CosmeticTypeSchema,
  equippedAt: z.date(),
});

export type EquippedCosmetic = z.infer<typeof EquippedCosmeticSchema>;

// ============================================
// Pet & Mood Types
// ============================================

export const MoodStateSchema = z.enum(['ecstatic', 'happy', 'content', 'neutral', 'sad', 'worried']);
export type MoodState = z.infer<typeof MoodStateSchema>;

export const PetStateSchema = z.object({
  mood: MoodStateSchema,
  moodScore: z.number(),
  animation: z.string(),
  equippedCosmetics: z.array(z.string()),
});

export type PetState = z.infer<typeof PetStateSchema>;

// ============================================
// AI Types
// ============================================

export const AIProviderSchema = z.enum(['openai', 'anthropic', 'ollama']);
export type AIProvider = z.infer<typeof AIProviderSchema>;

export const ChunkedTaskSchema = z.object({
  title: z.string(),
  estimatedMinutes: z.number().min(1).max(30),
  order: z.number(),
});

export type ChunkedTask = z.infer<typeof ChunkedTaskSchema>;

export const ChunkingResultSchema = z.object({
  originalTask: z.string(),
  chunks: z.array(ChunkedTaskSchema),
  totalEstimatedMinutes: z.number(),
});

export type ChunkingResult = z.infer<typeof ChunkingResultSchema>;

// ============================================
// XP & Level Calculations
// ============================================

export const XP_REWARDS = {
  small: 10,
  medium: 25,
  large: 50,
  pomodoro: 25,
  dailyStreak: 50,
} as const;

export const COIN_REWARDS = {
  small: 5,
  medium: 15,
  large: 30,
  pomodoro: 10,
  dailyStreak: 25,
} as const;

export function calculateXpForLevel(level: number): number {
  return 50 * Math.pow(level, 2);
}

export function calculateLevelFromXp(xp: number): number {
  return Math.floor(Math.sqrt(xp / 50)) + 1;
}

export function calculateXpProgress(xp: number): { current: number; required: number; percentage: number } {
  const level = calculateLevelFromXp(xp);
  const currentLevelXp = calculateXpForLevel(level - 1);
  const nextLevelXp = calculateXpForLevel(level);
  const current = xp - currentLevelXp;
  const required = nextLevelXp - currentLevelXp;
  const percentage = Math.min((current / required) * 100, 100);
  return { current, required, percentage };
}

// ============================================
// Mood Calculation
// ============================================

export interface MoodFactors {
  tasksCompletedToday: number;
  pomodorosCompletedToday: number;
  currentStreak: number;
  overdueTaskCount: number;
  minutesSinceLastActivity: number;
  timerActive: boolean;
}

export function calculateMoodScore(factors: MoodFactors): number {
  let score = 50; // Start neutral

  // Tasks completed (+8 per task)
  score += factors.tasksCompletedToday * 8;

  // Pomodoros completed (+5 each)
  score += factors.pomodorosCompletedToday * 5;

  // Streak bonus (+3 per day, max +15)
  score += Math.min(factors.currentStreak * 3, 15);

  // Overdue tasks (-10 each)
  score -= factors.overdueTaskCount * 10;

  // Inactivity penalty (-1 per 30min after 2 hours)
  if (factors.minutesSinceLastActivity > 120) {
    const inactivityPenalty = Math.floor((factors.minutesSinceLastActivity - 120) / 30);
    score -= inactivityPenalty;
  }

  // Active timer bonus (+10)
  if (factors.timerActive) {
    score += 10;
  }

  return Math.max(0, Math.min(100, score));
}

export function getMoodFromScore(score: number): MoodState {
  if (score >= 85) return 'ecstatic';
  if (score >= 70) return 'happy';
  if (score >= 55) return 'content';
  if (score >= 40) return 'neutral';
  if (score >= 25) return 'sad';
  return 'worried';
}

// ============================================
// IPC Channel Types
// ============================================

export const IPC_CHANNELS = {
  // User
  USER_GET: 'user:get',
  USER_UPDATE: 'user:update',
  USER_ADD_XP: 'user:addXp',
  USER_ADD_COINS: 'user:addCoins',

  // Tasks
  TASK_GET_ALL: 'task:getAll',
  TASK_GET: 'task:get',
  TASK_CREATE: 'task:create',
  TASK_UPDATE: 'task:update',
  TASK_DELETE: 'task:delete',
  TASK_COMPLETE: 'task:complete',

  // Timer
  TIMER_START: 'timer:start',
  TIMER_PAUSE: 'timer:pause',
  TIMER_RESUME: 'timer:resume',
  TIMER_STOP: 'timer:stop',
  TIMER_TICK: 'timer:tick',
  TIMER_COMPLETE: 'timer:complete',
  TIMER_GET_SETTINGS: 'timer:getSettings',
  TIMER_UPDATE_SETTINGS: 'timer:updateSettings',

  // Pomodoro Sessions
  POMODORO_GET_SESSIONS: 'pomodoro:getSessions',
  POMODORO_GET_TODAY_COUNT: 'pomodoro:getTodayCount',

  // Shop
  SHOP_GET_ITEMS: 'shop:getItems',
  SHOP_PURCHASE: 'shop:purchase',

  // Inventory
  INVENTORY_GET: 'inventory:get',
  INVENTORY_EQUIP: 'inventory:equip',
  INVENTORY_UNEQUIP: 'inventory:unequip',

  // AI
  AI_CHUNK_TASK: 'ai:chunkTask',
  AI_GET_PROVIDER: 'ai:getProvider',
  AI_SET_PROVIDER: 'ai:setProvider',

  // Window
  WINDOW_MINIMIZE: 'window:minimize',
  WINDOW_MAXIMIZE: 'window:maximize',
  WINDOW_CLOSE: 'window:close',

  // Notifications
  NOTIFICATION_SHOW: 'notification:show',
} as const;

export type IPCChannel = (typeof IPC_CHANNELS)[keyof typeof IPC_CHANNELS];
