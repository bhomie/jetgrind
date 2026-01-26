import { cn } from '../../utils/cn';
import type { MoodState } from '../../../shared/types';

interface PetDisplayProps {
  mood?: MoodState;
}

export function PetDisplay({ mood = 'happy' }: PetDisplayProps) {
  const moodEmojis: Record<MoodState, string> = {
    ecstatic: '🤩',
    happy: '😊',
    content: '🙂',
    neutral: '😐',
    sad: '😢',
    worried: '😰',
  };

  const moodMessages: Record<MoodState, string> = {
    ecstatic: "I'm so proud of you!",
    happy: "You're doing great!",
    content: "Keep it up!",
    neutral: "Let's get started!",
    sad: "I miss you...",
    worried: "Don't forget about me!",
  };

  const moodColors: Record<MoodState, string> = {
    ecstatic: 'from-yellow-200 to-yellow-300',
    happy: 'from-green-200 to-green-300',
    content: 'from-blue-200 to-blue-300',
    neutral: 'from-purple-200 to-purple-300',
    sad: 'from-slate-200 to-slate-300',
    worried: 'from-pink-200 to-pink-300',
  };

  return (
    <div className="text-center">
      <h3 className="text-sm font-medium text-gray-500 mb-3">Your Pet</h3>

      {/* Pet Container */}
      <div
        className={cn(
          'relative w-48 h-48 mx-auto rounded-full bg-gradient-to-br shadow-kawaii-lg flex items-center justify-center',
          moodColors[mood]
        )}
      >
        {/* Pet Character Placeholder */}
        <div className="text-8xl animate-float">
          {moodEmojis[mood]}
        </div>

        {/* Mood Indicator */}
        <div
          className={cn(
            'absolute top-2 right-2 w-4 h-4 rounded-full animate-pulse shadow-sm',
            `mood-${mood}`
          )}
        />
      </div>

      {/* Speech Bubble */}
      <div className="mt-4 relative">
        <div className="kawaii-card inline-block">
          <p className="text-sm text-gray-600">{moodMessages[mood]}</p>
        </div>
        {/* Triangle pointer */}
        <div
          className="absolute -top-2 left-1/2 transform -translate-x-1/2 w-0 h-0"
          style={{
            borderLeft: '8px solid transparent',
            borderRight: '8px solid transparent',
            borderBottom: '8px solid white',
          }}
        />
      </div>

      {/* Quick Stats */}
      <div className="mt-4 grid grid-cols-2 gap-2 text-xs">
        <div className="kawaii-card py-2">
          <div className="text-lg">🎯</div>
          <div className="text-gray-500">Tasks</div>
          <div className="font-bold text-primary-600">3</div>
        </div>
        <div className="kawaii-card py-2">
          <div className="text-lg">🍅</div>
          <div className="text-gray-500">Pomodoros</div>
          <div className="font-bold text-primary-600">5</div>
        </div>
      </div>
    </div>
  );
}
