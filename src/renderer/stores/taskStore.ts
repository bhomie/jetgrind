import { create } from 'zustand';
import type { Task, CreateTask, UpdateTask } from '../../shared/types';

interface TaskState {
  tasks: Task[];
  selectedTaskId: string | null;
  loading: boolean;
  error: string | null;

  init: () => Promise<void>;
  refresh: () => Promise<void>;
  createTask: (data: CreateTask) => Promise<Task | null>;
  updateTask: (id: string, data: UpdateTask) => Promise<Task | null>;
  deleteTask: (id: string) => Promise<void>;
  completeTask: (id: string) => Promise<{
    xpEarned: number;
    coinsEarned: number;
    leveledUp: boolean;
    newLevel?: number;
  } | null>;
  selectTask: (id: string | null) => void;
}

export const useTaskStore = create<TaskState>((set, get) => ({
  tasks: [],
  selectedTaskId: null,
  loading: true,
  error: null,

  init: async () => {
    try {
      set({ loading: true, error: null });
      const tasks = await window.electronAPI.getAllTasks();
      set({ tasks, loading: false });
    } catch (err) {
      set({ error: 'Failed to load tasks', loading: false });
    }
  },

  refresh: async () => {
    try {
      const tasks = await window.electronAPI.getAllTasks();
      set({ tasks });
    } catch (err) {
      console.error('Failed to refresh tasks:', err);
    }
  },

  createTask: async (data: CreateTask) => {
    try {
      const task = await window.electronAPI.createTask(data);
      await get().refresh();
      return task;
    } catch (err) {
      console.error('Failed to create task:', err);
      return null;
    }
  },

  updateTask: async (id: string, data: UpdateTask) => {
    try {
      const task = await window.electronAPI.updateTask(id, data);
      await get().refresh();
      return task;
    } catch (err) {
      console.error('Failed to update task:', err);
      return null;
    }
  },

  deleteTask: async (id: string) => {
    try {
      await window.electronAPI.deleteTask(id);
      const { selectedTaskId } = get();
      if (selectedTaskId === id) {
        set({ selectedTaskId: null });
      }
      await get().refresh();
    } catch (err) {
      console.error('Failed to delete task:', err);
    }
  },

  completeTask: async (id: string) => {
    try {
      const result = await window.electronAPI.completeTask(id);
      await get().refresh();
      return result;
    } catch (err) {
      console.error('Failed to complete task:', err);
      return null;
    }
  },

  selectTask: (id: string | null) => {
    set({ selectedTaskId: id });
  },
}));
