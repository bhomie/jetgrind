import { Minus, Square, X, Sparkles } from 'lucide-react';

export function TitleBar() {
  const handleMinimize = () => window.electronAPI.minimizeWindow();
  const handleMaximize = () => window.electronAPI.maximizeWindow();
  const handleClose = () => window.electronAPI.closeWindow();

  return (
    <div className="title-bar flex items-center justify-between px-4 bg-gradient-to-r from-primary-400 to-primary-500 text-white">
      <div className="flex items-center gap-2">
        <Sparkles className="w-4 h-4" />
        <span className="text-sm font-medium">JetGrind</span>
      </div>
      <div className="flex items-center gap-1">
        <button
          onClick={handleMinimize}
          className="p-1.5 hover:bg-white/20 rounded transition-colors"
          title="Minimize"
        >
          <Minus className="w-4 h-4" />
        </button>
        <button
          onClick={handleMaximize}
          className="p-1.5 hover:bg-white/20 rounded transition-colors"
          title="Maximize"
        >
          <Square className="w-3 h-3" />
        </button>
        <button
          onClick={handleClose}
          className="p-1.5 hover:bg-red-500 rounded transition-colors"
          title="Close"
        >
          <X className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
}
