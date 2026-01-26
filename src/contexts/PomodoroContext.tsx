import React, { createContext, useContext, useState, useEffect } from 'react';

interface PomodoroContextType {
  isRunning: boolean;
  timeLeft: number;
  workDuration: number;
  breakDuration: number;
  isWorkTime: boolean;
  startTimer: () => void;
  pauseTimer: () => void;
  resetTimer: () => void;
  setWorkDuration: (duration: number) => void;
  setBreakDuration: (duration: number) => void;
}

const PomodoroContext = createContext<PomodoroContextType | undefined>(undefined);

export const PomodoroProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [isRunning, setIsRunning] = useState(false);
  const [timeLeft, setTimeLeft] = useState(25 * 60); // 25 minutes in seconds
  const [workDuration, setWorkDuration] = useState(25 * 60);
  const [breakDuration, setBreakDuration] = useState(5 * 60);
  const [isWorkTime, setIsWorkTime] = useState(true);

  useEffect(() => {
    let interval: NodeJS.Timeout;

    if (isRunning && timeLeft > 0) {
      interval = setInterval(() => {
        setTimeLeft((prev) => {
          if (prev <= 1) {
            setIsRunning(false);
            setIsWorkTime(!isWorkTime);
            return isWorkTime ? breakDuration : workDuration;
          }
          return prev - 1;
        });
      }, 1000);
    }

    return () => clearInterval(interval);
  }, [isRunning, timeLeft, isWorkTime, workDuration, breakDuration]);

  const startTimer = () => setIsRunning(true);
  const pauseTimer = () => setIsRunning(false);
  const resetTimer = () => {
    setIsRunning(false);
    setTimeLeft(isWorkTime ? workDuration : breakDuration);
  };

  return (
    <PomodoroContext.Provider
      value={{
        isRunning,
        timeLeft,
        workDuration,
        breakDuration,
        isWorkTime,
        startTimer,
        pauseTimer,
        resetTimer,
        setWorkDuration,
        setBreakDuration,
      }}
    >
      {children}
    </PomodoroContext.Provider>
  );
};

export const usePomodoro = () => {
  const context = useContext(PomodoroContext);
  if (context === undefined) {
    throw new Error('usePomodoro must be used within a PomodoroProvider');
  }
  return context;
}; 