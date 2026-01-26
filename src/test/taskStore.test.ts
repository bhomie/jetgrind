import { describe, it, expect, beforeEach, vi } from 'vitest';
import { useTaskStore } from '../renderer/stores/taskStore';

describe('Task Store', () => {
  beforeEach(() => {
    // Reset the store state
    useTaskStore.setState({
      tasks: [],
      selectedTaskId: null,
      loading: false,
      error: null,
    });

    // Reset mocks
    vi.clearAllMocks();
  });

  describe('selectTask', () => {
    it('should select a task by id', () => {
      const { selectTask } = useTaskStore.getState();

      selectTask('task-1');

      expect(useTaskStore.getState().selectedTaskId).toBe('task-1');
    });

    it('should deselect task when null is passed', () => {
      useTaskStore.setState({ selectedTaskId: 'task-1' });

      const { selectTask } = useTaskStore.getState();
      selectTask(null);

      expect(useTaskStore.getState().selectedTaskId).toBeNull();
    });
  });

  describe('init', () => {
    it('should set loading state during initialization', async () => {
      window.electronAPI.getAllTasks = vi.fn().mockImplementation(
        () => new Promise((resolve) => setTimeout(() => resolve([]), 100))
      );

      const { init } = useTaskStore.getState();
      const initPromise = init();

      expect(useTaskStore.getState().loading).toBe(true);

      await initPromise;

      expect(useTaskStore.getState().loading).toBe(false);
    });

    it('should set error on failure', async () => {
      window.electronAPI.getAllTasks = vi.fn().mockRejectedValue(new Error('Failed'));

      const { init } = useTaskStore.getState();
      await init();

      expect(useTaskStore.getState().error).toBe('Failed to load tasks');
      expect(useTaskStore.getState().loading).toBe(false);
    });
  });

  describe('createTask', () => {
    it('should call electronAPI.createTask', async () => {
      const mockTask = {
        id: 'new-task',
        title: 'New Task',
        status: 'pending',
        priority: 'medium',
        size: 'medium',
        xpReward: 25,
        coinReward: 15,
        parentId: null,
        dueDate: null,
        completedAt: null,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      window.electronAPI.createTask = vi.fn().mockResolvedValue(mockTask);
      window.electronAPI.getAllTasks = vi.fn().mockResolvedValue([mockTask]);

      const { createTask } = useTaskStore.getState();
      const result = await createTask({ title: 'New Task' });

      expect(window.electronAPI.createTask).toHaveBeenCalledWith({ title: 'New Task' });
      expect(result).toEqual(mockTask);
    });
  });

  describe('completeTask', () => {
    it('should return completion rewards', async () => {
      const mockResult = { xpEarned: 25, coinsEarned: 15, leveledUp: false };
      window.electronAPI.completeTask = vi.fn().mockResolvedValue(mockResult);
      window.electronAPI.getAllTasks = vi.fn().mockResolvedValue([]);

      const { completeTask } = useTaskStore.getState();
      const result = await completeTask('task-1');

      expect(window.electronAPI.completeTask).toHaveBeenCalledWith('task-1');
      expect(result).toEqual(mockResult);
    });

    it('should return leveledUp info when user levels up', async () => {
      const mockResult = { xpEarned: 50, coinsEarned: 30, leveledUp: true, newLevel: 5 };
      window.electronAPI.completeTask = vi.fn().mockResolvedValue(mockResult);
      window.electronAPI.getAllTasks = vi.fn().mockResolvedValue([]);

      const { completeTask } = useTaskStore.getState();
      const result = await completeTask('task-1');

      expect(result?.leveledUp).toBe(true);
      expect(result?.newLevel).toBe(5);
    });

    it('should handle errors gracefully', async () => {
      window.electronAPI.completeTask = vi.fn().mockRejectedValue(new Error('Failed'));

      const { completeTask } = useTaskStore.getState();
      const result = await completeTask('task-1');

      expect(result).toBeNull();
    });
  });

  describe('deleteTask', () => {
    it('should deselect task if deleted task was selected', async () => {
      useTaskStore.setState({ selectedTaskId: 'task-to-delete' });
      window.electronAPI.deleteTask = vi.fn().mockResolvedValue({});
      window.electronAPI.getAllTasks = vi.fn().mockResolvedValue([]);

      const { deleteTask } = useTaskStore.getState();
      await deleteTask('task-to-delete');

      expect(useTaskStore.getState().selectedTaskId).toBeNull();
    });

    it('should not deselect if different task was deleted', async () => {
      useTaskStore.setState({ selectedTaskId: 'other-task' });
      window.electronAPI.deleteTask = vi.fn().mockResolvedValue({});
      window.electronAPI.getAllTasks = vi.fn().mockResolvedValue([]);

      const { deleteTask } = useTaskStore.getState();
      await deleteTask('task-to-delete');

      expect(useTaskStore.getState().selectedTaskId).toBe('other-task');
    });
  });

  describe('updateTask', () => {
    it('should call electronAPI.updateTask with correct params', async () => {
      window.electronAPI.updateTask = vi.fn().mockResolvedValue({});
      window.electronAPI.getAllTasks = vi.fn().mockResolvedValue([]);

      const { updateTask } = useTaskStore.getState();
      await updateTask('task-1', { title: 'Updated Title', priority: 'high' });

      expect(window.electronAPI.updateTask).toHaveBeenCalledWith('task-1', {
        title: 'Updated Title',
        priority: 'high',
      });
    });
  });
});
