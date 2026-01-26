import { describe, it, expect } from 'vitest';
import {
  calculateXpForLevel,
  calculateLevelFromXp,
  calculateXpProgress,
  XP_REWARDS,
  COIN_REWARDS,
} from '../shared/types';

describe('XP System', () => {
  describe('calculateXpForLevel', () => {
    it('should calculate XP required for level 1', () => {
      expect(calculateXpForLevel(1)).toBe(50);
    });

    it('should calculate XP required for level 10', () => {
      expect(calculateXpForLevel(10)).toBe(5000);
    });

    it('should calculate XP required for level 50', () => {
      expect(calculateXpForLevel(50)).toBe(125000);
    });

    it('should calculate XP required for level 100', () => {
      expect(calculateXpForLevel(100)).toBe(500000);
    });
  });

  describe('calculateLevelFromXp', () => {
    it('should return level 1 for 0 XP', () => {
      expect(calculateLevelFromXp(0)).toBe(1);
    });

    it('should return level 1 for 49 XP', () => {
      expect(calculateLevelFromXp(49)).toBe(1);
    });

    it('should return level 2 for 50 XP', () => {
      expect(calculateLevelFromXp(50)).toBe(2);
    });

    it('should return level 10 for 5000 XP', () => {
      expect(calculateLevelFromXp(5000)).toBe(11);
    });

    it('should handle large XP values', () => {
      expect(calculateLevelFromXp(500000)).toBe(101);
    });
  });

  describe('calculateXpProgress', () => {
    it('should calculate progress for level 1 with 0 XP', () => {
      const progress = calculateXpProgress(0);
      expect(progress.current).toBe(0);
      expect(progress.required).toBe(50);
      expect(progress.percentage).toBe(0);
    });

    it('should calculate progress for level 1 with 25 XP', () => {
      const progress = calculateXpProgress(25);
      expect(progress.current).toBe(25);
      expect(progress.required).toBe(50);
      expect(progress.percentage).toBe(50);
    });

    it('should reset progress when leveling up', () => {
      const progress = calculateXpProgress(50);
      expect(progress.current).toBe(0);
      expect(progress.percentage).toBe(0);
    });
  });

  describe('XP Rewards', () => {
    it('should have correct small task reward', () => {
      expect(XP_REWARDS.small).toBe(10);
    });

    it('should have correct medium task reward', () => {
      expect(XP_REWARDS.medium).toBe(25);
    });

    it('should have correct large task reward', () => {
      expect(XP_REWARDS.large).toBe(50);
    });

    it('should have correct pomodoro reward', () => {
      expect(XP_REWARDS.pomodoro).toBe(25);
    });

    it('should have correct daily streak reward', () => {
      expect(XP_REWARDS.dailyStreak).toBe(50);
    });
  });

  describe('Coin Rewards', () => {
    it('should have correct small task coin reward', () => {
      expect(COIN_REWARDS.small).toBe(5);
    });

    it('should have correct medium task coin reward', () => {
      expect(COIN_REWARDS.medium).toBe(15);
    });

    it('should have correct large task coin reward', () => {
      expect(COIN_REWARDS.large).toBe(30);
    });

    it('should have correct pomodoro coin reward', () => {
      expect(COIN_REWARDS.pomodoro).toBe(10);
    });
  });
});
