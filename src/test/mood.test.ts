import { describe, it, expect } from 'vitest';
import { calculateMoodScore, getMoodFromScore, type MoodFactors } from '../shared/types';

describe('Mood System', () => {
  const baseFactors: MoodFactors = {
    tasksCompletedToday: 0,
    pomodorosCompletedToday: 0,
    currentStreak: 0,
    overdueTaskCount: 0,
    minutesSinceLastActivity: 0,
    timerActive: false,
  };

  describe('calculateMoodScore', () => {
    it('should start with neutral score of 50', () => {
      const score = calculateMoodScore(baseFactors);
      expect(score).toBe(50);
    });

    it('should add 8 points per completed task', () => {
      const score = calculateMoodScore({
        ...baseFactors,
        tasksCompletedToday: 3,
      });
      expect(score).toBe(50 + 24); // 50 + (3 * 8)
    });

    it('should add 5 points per completed pomodoro', () => {
      const score = calculateMoodScore({
        ...baseFactors,
        pomodorosCompletedToday: 4,
      });
      expect(score).toBe(50 + 20); // 50 + (4 * 5)
    });

    it('should add streak bonus capped at 15', () => {
      // 5 day streak = 15 points (5 * 3)
      expect(
        calculateMoodScore({ ...baseFactors, currentStreak: 5 })
      ).toBe(65);

      // 10 day streak = still 15 points (capped)
      expect(
        calculateMoodScore({ ...baseFactors, currentStreak: 10 })
      ).toBe(65);
    });

    it('should subtract 10 points per overdue task', () => {
      const score = calculateMoodScore({
        ...baseFactors,
        overdueTaskCount: 2,
      });
      expect(score).toBe(50 - 20);
    });

    it('should apply inactivity penalty after 2 hours', () => {
      // 150 minutes = 30 minutes over threshold = -1 point
      const score1 = calculateMoodScore({
        ...baseFactors,
        minutesSinceLastActivity: 150,
      });
      expect(score1).toBe(49);

      // 240 minutes = 4 30-minute periods over threshold = -4 points
      const score2 = calculateMoodScore({
        ...baseFactors,
        minutesSinceLastActivity: 240,
      });
      expect(score2).toBe(46);
    });

    it('should not apply inactivity penalty under 2 hours', () => {
      const score = calculateMoodScore({
        ...baseFactors,
        minutesSinceLastActivity: 100,
      });
      expect(score).toBe(50);
    });

    it('should add 10 points for active timer', () => {
      const score = calculateMoodScore({
        ...baseFactors,
        timerActive: true,
      });
      expect(score).toBe(60);
    });

    it('should clamp score to minimum 0', () => {
      const score = calculateMoodScore({
        ...baseFactors,
        overdueTaskCount: 10,
      });
      expect(score).toBe(0);
    });

    it('should clamp score to maximum 100', () => {
      const score = calculateMoodScore({
        ...baseFactors,
        tasksCompletedToday: 10,
        pomodorosCompletedToday: 10,
        currentStreak: 10,
        timerActive: true,
      });
      expect(score).toBe(100);
    });

    it('should combine multiple factors correctly', () => {
      const score = calculateMoodScore({
        tasksCompletedToday: 2,    // +16
        pomodorosCompletedToday: 3, // +15
        currentStreak: 2,          // +6
        overdueTaskCount: 1,       // -10
        minutesSinceLastActivity: 30,
        timerActive: true,         // +10
      });
      expect(score).toBe(50 + 16 + 15 + 6 - 10 + 10);
    });
  });

  describe('getMoodFromScore', () => {
    it('should return ecstatic for score >= 85', () => {
      expect(getMoodFromScore(85)).toBe('ecstatic');
      expect(getMoodFromScore(100)).toBe('ecstatic');
    });

    it('should return happy for score 70-84', () => {
      expect(getMoodFromScore(70)).toBe('happy');
      expect(getMoodFromScore(84)).toBe('happy');
    });

    it('should return content for score 55-69', () => {
      expect(getMoodFromScore(55)).toBe('content');
      expect(getMoodFromScore(69)).toBe('content');
    });

    it('should return neutral for score 40-54', () => {
      expect(getMoodFromScore(40)).toBe('neutral');
      expect(getMoodFromScore(54)).toBe('neutral');
    });

    it('should return sad for score 25-39', () => {
      expect(getMoodFromScore(25)).toBe('sad');
      expect(getMoodFromScore(39)).toBe('sad');
    });

    it('should return worried for score < 25', () => {
      expect(getMoodFromScore(24)).toBe('worried');
      expect(getMoodFromScore(0)).toBe('worried');
    });
  });
});
