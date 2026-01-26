import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';
import { useToastStore } from '../renderer/stores/toastStore';

describe('Toast Store', () => {
  beforeEach(() => {
    // Reset the store state
    useToastStore.setState({ toasts: [] });
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('should add a toast', () => {
    const { addToast } = useToastStore.getState();

    addToast({
      type: 'success',
      title: 'Test Toast',
      message: 'This is a test message',
    });

    const { toasts } = useToastStore.getState();
    expect(toasts).toHaveLength(1);
    expect(toasts[0].title).toBe('Test Toast');
    expect(toasts[0].type).toBe('success');
  });

  it('should remove a toast by id', () => {
    const { addToast, removeToast } = useToastStore.getState();

    addToast({
      type: 'info',
      title: 'Toast to Remove',
    });

    const { toasts: before } = useToastStore.getState();
    expect(before).toHaveLength(1);

    removeToast(before[0].id);

    const { toasts: after } = useToastStore.getState();
    expect(after).toHaveLength(0);
  });

  it('should auto-remove toast after duration', () => {
    const { addToast } = useToastStore.getState();

    addToast({
      type: 'success',
      title: 'Auto Remove',
      duration: 1000,
    });

    expect(useToastStore.getState().toasts).toHaveLength(1);

    vi.advanceTimersByTime(1000);

    expect(useToastStore.getState().toasts).toHaveLength(0);
  });

  it('should show reward toast with XP and coins', () => {
    const { showReward } = useToastStore.getState();

    showReward(25, 15, 'Task Complete!');

    const { toasts } = useToastStore.getState();
    expect(toasts).toHaveLength(1);
    expect(toasts[0].type).toBe('reward');
    expect(toasts[0].xp).toBe(25);
    expect(toasts[0].coins).toBe(15);
    expect(toasts[0].title).toBe('Task Complete!');
  });

  it('should show level up toast', () => {
    const { showLevelUp } = useToastStore.getState();

    showLevelUp(5);

    const { toasts } = useToastStore.getState();
    expect(toasts).toHaveLength(1);
    expect(toasts[0].type).toBe('reward');
    expect(toasts[0].title).toContain('Level Up');
    expect(toasts[0].message).toContain('5');
  });

  it('should show success toast', () => {
    const { showSuccess } = useToastStore.getState();

    showSuccess('Success!', 'Operation completed');

    const { toasts } = useToastStore.getState();
    expect(toasts).toHaveLength(1);
    expect(toasts[0].type).toBe('success');
    expect(toasts[0].title).toBe('Success!');
    expect(toasts[0].message).toBe('Operation completed');
  });

  it('should show error toast', () => {
    const { showError } = useToastStore.getState();

    showError('Error!', 'Something went wrong');

    const { toasts } = useToastStore.getState();
    expect(toasts).toHaveLength(1);
    expect(toasts[0].type).toBe('error');
    expect(toasts[0].title).toBe('Error!');
    expect(toasts[0].message).toBe('Something went wrong');
  });

  it('should handle multiple toasts', () => {
    const { showSuccess, showError, showReward } = useToastStore.getState();

    showSuccess('First', 'Message 1');
    showError('Second', 'Message 2');
    showReward(10, 5);

    const { toasts } = useToastStore.getState();
    expect(toasts).toHaveLength(3);
  });
});
