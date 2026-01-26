import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { PomodoroProvider } from './contexts/PomodoroContext';
import { TaskProvider } from './contexts/TaskContext';
import Sidebar from './components/Sidebar';
import TaskList from './components/TaskList';
import PomodoroTimer from './components/PomodoroTimer';
import Settings from './components/Settings';

const App: React.FC = () => {
  return (
    <Router>
      <TaskProvider>
        <PomodoroProvider>
          <div className="flex h-screen bg-gray-50">
            <Sidebar />
            <main className="flex-1 overflow-y-auto">
              <div className="container mx-auto px-6 py-8">
                <Routes>
                  <Route path="/" element={<TaskList />} />
                  <Route path="/pomodoro" element={<PomodoroTimer />} />
                  <Route path="/settings" element={<Settings />} />
                </Routes>
              </div>
            </main>
          </div>
        </PomodoroProvider>
      </TaskProvider>
    </Router>
  );
};

export default App; 