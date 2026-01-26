import { useState } from 'react';
import { TaskList } from '../tasks/TaskList';
import { TimerView } from '../timer/TimerView';
import { PetDisplay } from '../pet/PetDisplay';

type View = 'tasks' | 'timer' | 'shop' | 'profile' | 'settings';

export function MainContent() {
  const [currentView, setCurrentView] = useState<View>('tasks');

  return (
    <main className="flex-1 flex overflow-hidden">
      {/* Main Content Area */}
      <div className="flex-1 p-6 overflow-y-auto">
        {currentView === 'tasks' && <TaskList />}
        {currentView === 'timer' && <TimerView />}
        {currentView === 'shop' && (
          <div className="text-center py-12 text-gray-500">
            <p className="text-xl">🛍️ Shop coming soon!</p>
          </div>
        )}
        {currentView === 'profile' && (
          <div className="text-center py-12 text-gray-500">
            <p className="text-xl">👤 Profile coming soon!</p>
          </div>
        )}
        {currentView === 'settings' && (
          <div className="text-center py-12 text-gray-500">
            <p className="text-xl">⚙️ Settings coming soon!</p>
          </div>
        )}
      </div>

      {/* Pet Display Panel */}
      <aside className="w-72 bg-white/60 backdrop-blur-sm border-l-2 border-pink-100 p-4">
        <PetDisplay />

        {/* Quick Timer */}
        <div className="mt-4">
          <TimerWidget onNavigate={() => setCurrentView('timer')} />
        </div>
      </aside>
    </main>
  );
}

function TimerWidget({ onNavigate }: { onNavigate: () => void }) {
  return (
    <div
      className="kawaii-card cursor-pointer hover:shadow-kawaii-lg transition-all"
      onClick={onNavigate}
    >
      <div className="text-center">
        <div className="text-xs text-gray-500 mb-1">Quick Timer</div>
        <div className="text-3xl font-bold text-primary-600">25:00</div>
        <button className="mt-2 kawaii-button text-sm">
          Start Focus
        </button>
      </div>
    </div>
  );
}
