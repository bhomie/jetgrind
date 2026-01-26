import { useToastStore, Toast } from '../../stores/toastStore';
import { X, Sparkles, CheckCircle2, AlertCircle, Info, Coins } from 'lucide-react';
import { cn } from '../../utils/cn';

export function ToastContainer() {
  const { toasts, removeToast } = useToastStore();

  return (
    <div className="fixed bottom-4 right-4 z-50 flex flex-col gap-2">
      {toasts.map((toast) => (
        <ToastItem key={toast.id} toast={toast} onClose={() => removeToast(toast.id)} />
      ))}
    </div>
  );
}

interface ToastItemProps {
  toast: Toast;
  onClose: () => void;
}

function ToastItem({ toast, onClose }: ToastItemProps) {
  const icons = {
    success: <CheckCircle2 className="w-5 h-5 text-green-500" />,
    error: <AlertCircle className="w-5 h-5 text-red-500" />,
    info: <Info className="w-5 h-5 text-blue-500" />,
    reward: <Sparkles className="w-5 h-5 text-yellow-500" />,
  };

  const bgColors = {
    success: 'bg-green-50 border-green-200',
    error: 'bg-red-50 border-red-200',
    info: 'bg-blue-50 border-blue-200',
    reward: 'bg-gradient-to-r from-yellow-50 to-orange-50 border-yellow-300',
  };

  return (
    <div
      className={cn(
        'animate-slide-up flex items-start gap-3 p-4 rounded-2xl border-2 shadow-lg min-w-[280px] max-w-[360px]',
        bgColors[toast.type]
      )}
    >
      <div className="flex-shrink-0 mt-0.5">{icons[toast.type]}</div>
      <div className="flex-1 min-w-0">
        <p className="font-semibold text-gray-800">{toast.title}</p>
        {toast.message && <p className="text-sm text-gray-600 mt-0.5">{toast.message}</p>}
        {toast.type === 'reward' && (toast.xp || toast.coins) && (
          <div className="flex items-center gap-3 mt-2">
            {toast.xp && (
              <span className="flex items-center gap-1 text-sm font-medium text-accent-600">
                <Sparkles className="w-4 h-4" />+{toast.xp} XP
              </span>
            )}
            {toast.coins && (
              <span className="flex items-center gap-1 text-sm font-medium text-yellow-600">
                <Coins className="w-4 h-4" />+{toast.coins}
              </span>
            )}
          </div>
        )}
      </div>
      <button
        onClick={onClose}
        className="flex-shrink-0 p-1 text-gray-400 hover:text-gray-600 transition-colors"
      >
        <X className="w-4 h-4" />
      </button>
    </div>
  );
}
