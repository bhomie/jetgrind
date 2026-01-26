import { useEffect } from 'react';
import { TitleBar } from './components/layout/TitleBar';
import { Sidebar } from './components/layout/Sidebar';
import { MainContent } from './components/layout/MainContent';
import { ToastContainer } from './components/ui/ToastContainer';
import { useUserStore } from './stores/userStore';
import { useTaskStore } from './stores/taskStore';

export default function App() {
  const initUser = useUserStore((state) => state.init);
  const initTasks = useTaskStore((state) => state.init);

  useEffect(() => {
    initUser();
    initTasks();
  }, [initUser, initTasks]);

  return (
    <div className="h-full flex flex-col bg-gradient-to-br from-primary-50 via-kawaii-lavender/30 to-kawaii-sky/20">
      <TitleBar />
      <div className="flex-1 flex overflow-hidden">
        <Sidebar />
        <MainContent />
      </div>
      <ToastContainer />
    </div>
  );
}
