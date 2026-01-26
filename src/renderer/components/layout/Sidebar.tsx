import { ListTodo, Timer, ShoppingBag, User, Settings, Trophy } from 'lucide-react';
import { useUserStore } from '../../stores/userStore';
import { cn } from '../../utils/cn';

type View = 'tasks' | 'timer' | 'shop' | 'profile' | 'settings';

interface SidebarProps {
  currentView?: View;
  onViewChange?: (view: View) => void;
}

export function Sidebar({ currentView = 'tasks', onViewChange }: SidebarProps) {
  const { user, xpProgress } = useUserStore();

  const navItems = [
    { id: 'tasks' as View, icon: ListTodo, label: 'Tasks' },
    { id: 'timer' as View, icon: Timer, label: 'Timer' },
    { id: 'shop' as View, icon: ShoppingBag, label: 'Shop' },
    { id: 'profile' as View, icon: User, label: 'Profile' },
  ];

  return (
    <aside className="w-64 bg-white/80 backdrop-blur-sm border-r-2 border-pink-100 flex flex-col">
      {/* User Stats */}
      <div className="p-4 border-b-2 border-pink-100">
        <div className="flex items-center gap-3 mb-3">
          <div className="w-12 h-12 rounded-full bg-gradient-to-br from-primary-300 to-primary-400 flex items-center justify-center shadow-kawaii">
            <Trophy className="w-6 h-6 text-white" />
          </div>
          <div>
            <div className="text-sm text-gray-500">Level</div>
            <div className="text-2xl font-bold text-primary-600">{user?.level || 1}</div>
          </div>
        </div>

        {/* XP Bar */}
        <div className="space-y-1">
          <div className="flex justify-between text-xs text-gray-500">
            <span>XP</span>
            <span>{xpProgress.current} / {xpProgress.required}</span>
          </div>
          <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
            <div
              className="h-full bg-gradient-to-r from-accent-400 to-accent-500 transition-all duration-500"
              style={{ width: `${xpProgress.percentage}%` }}
            />
          </div>
        </div>

        {/* Coins */}
        <div className="mt-3 flex items-center gap-2">
          <span className="text-lg">🪙</span>
          <span className="font-medium text-accent-600">{user?.coins || 0}</span>
        </div>

        {/* Streak */}
        <div className="mt-2 flex items-center gap-2">
          <span className="text-lg">🔥</span>
          <span className="font-medium text-orange-500">{user?.streak || 0} day streak</span>
        </div>
      </div>

      {/* Navigation */}
      <nav className="flex-1 p-2">
        <ul className="space-y-1">
          {navItems.map((item) => (
            <li key={item.id}>
              <button
                onClick={() => onViewChange?.(item.id)}
                className={cn(
                  'w-full flex items-center gap-3 px-4 py-3 rounded-xl text-left transition-all duration-200',
                  currentView === item.id
                    ? 'bg-gradient-to-r from-primary-100 to-primary-50 text-primary-700 shadow-sm'
                    : 'hover:bg-gray-50 text-gray-600'
                )}
              >
                <item.icon className="w-5 h-5" />
                <span className="font-medium">{item.label}</span>
              </button>
            </li>
          ))}
        </ul>
      </nav>

      {/* Settings Button */}
      <div className="p-2 border-t-2 border-pink-100">
        <button
          onClick={() => onViewChange?.('settings')}
          className={cn(
            'w-full flex items-center gap-3 px-4 py-3 rounded-xl text-left transition-all duration-200',
            currentView === 'settings'
              ? 'bg-gradient-to-r from-primary-100 to-primary-50 text-primary-700 shadow-sm'
              : 'hover:bg-gray-50 text-gray-600'
          )}
        >
          <Settings className="w-5 h-5" />
          <span className="font-medium">Settings</span>
        </button>
      </div>
    </aside>
  );
}
