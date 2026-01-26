import { useState, useEffect } from 'react';
import { X, Sparkles, Coins, Calendar, ListTree } from 'lucide-react';
import type { Task, TaskPriority, TaskSize, CreateTask } from '../../../shared/types';
import { XP_REWARDS, COIN_REWARDS } from '../../../shared/types';
import { cn } from '../../utils/cn';

interface TaskModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (data: CreateTask) => Promise<void>;
  task?: Task; // If provided, we're editing
  parentTask?: Task; // If provided, we're creating a subtask
}

export function TaskModal({ isOpen, onClose, onSave, task, parentTask }: TaskModalProps) {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [priority, setPriority] = useState<TaskPriority>('medium');
  const [size, setSize] = useState<TaskSize>('medium');
  const [dueDate, setDueDate] = useState('');
  const [saving, setSaving] = useState(false);

  const isEditing = !!task;
  const isSubtask = !!parentTask;

  useEffect(() => {
    if (task) {
      setTitle(task.title);
      setDescription(task.description || '');
      setPriority(task.priority);
      setSize(task.size);
      setDueDate(task.dueDate ? new Date(task.dueDate).toISOString().split('T')[0] : '');
    } else {
      setTitle('');
      setDescription('');
      setPriority('medium');
      setSize('medium');
      setDueDate('');
    }
  }, [task, isOpen]);

  const handleSave = async () => {
    if (!title.trim()) return;

    setSaving(true);
    try {
      await onSave({
        title: title.trim(),
        description: description.trim() || undefined,
        priority,
        size,
        dueDate: dueDate ? new Date(dueDate) : null,
        parentId: parentTask?.id || task?.parentId || null,
      });
      onClose();
    } finally {
      setSaving(false);
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && e.metaKey) {
      handleSave();
    } else if (e.key === 'Escape') {
      onClose();
    }
  };

  if (!isOpen) return null;

  const xpReward = XP_REWARDS[size];
  const coinReward = COIN_REWARDS[size];

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      {/* Backdrop */}
      <div className="absolute inset-0 bg-black/30 backdrop-blur-sm" onClick={onClose} />

      {/* Modal */}
      <div
        className="relative bg-white rounded-3xl shadow-2xl w-full max-w-lg mx-4 animate-scale-up"
        onKeyDown={handleKeyDown}
      >
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-gray-100">
          <div>
            <h2 className="text-xl font-bold text-gray-800">
              {isEditing ? 'Edit Task' : isSubtask ? 'Add Subtask' : 'New Task'}
            </h2>
            {isSubtask && (
              <p className="text-sm text-gray-500 mt-1 flex items-center gap-1">
                <ListTree className="w-4 h-4" />
                Subtask of: {parentTask.title}
              </p>
            )}
          </div>
          <button
            onClick={onClose}
            className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-xl transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content */}
        <div className="p-6 space-y-5">
          {/* Title */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Task Title</label>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="What do you need to do?"
              className="kawaii-input text-lg"
              autoFocus
            />
          </div>

          {/* Description */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Description <span className="text-gray-400">(optional)</span>
            </label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Add more details..."
              rows={3}
              className="kawaii-input resize-none"
            />
          </div>

          {/* Priority & Size Row */}
          <div className="grid grid-cols-2 gap-4">
            {/* Priority */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Priority</label>
              <div className="flex gap-2">
                {(['low', 'medium', 'high'] as TaskPriority[]).map((p) => (
                  <button
                    key={p}
                    onClick={() => setPriority(p)}
                    className={cn(
                      'flex-1 py-2 px-3 rounded-xl text-sm font-medium transition-all border-2',
                      priority === p
                        ? p === 'low'
                          ? 'bg-blue-100 border-blue-300 text-blue-700'
                          : p === 'medium'
                          ? 'bg-yellow-100 border-yellow-300 text-yellow-700'
                          : 'bg-red-100 border-red-300 text-red-700'
                        : 'bg-gray-50 border-gray-200 text-gray-600 hover:border-gray-300'
                    )}
                  >
                    {p.charAt(0).toUpperCase() + p.slice(1)}
                  </button>
                ))}
              </div>
            </div>

            {/* Size */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Size</label>
              <div className="flex gap-2">
                {(['small', 'medium', 'large'] as TaskSize[]).map((s) => (
                  <button
                    key={s}
                    onClick={() => setSize(s)}
                    className={cn(
                      'flex-1 py-2 px-3 rounded-xl text-sm font-medium transition-all border-2',
                      size === s
                        ? 'bg-primary-100 border-primary-300 text-primary-700'
                        : 'bg-gray-50 border-gray-200 text-gray-600 hover:border-gray-300'
                    )}
                  >
                    {s.charAt(0).toUpperCase()}
                  </button>
                ))}
              </div>
            </div>
          </div>

          {/* Due Date */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Due Date <span className="text-gray-400">(optional)</span>
            </label>
            <div className="relative">
              <Calendar className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
              <input
                type="date"
                value={dueDate}
                onChange={(e) => setDueDate(e.target.value)}
                className="kawaii-input pl-10"
              />
            </div>
          </div>

          {/* Reward Preview */}
          <div className="bg-gradient-to-r from-primary-50 to-accent-50 rounded-2xl p-4">
            <p className="text-sm text-gray-600 mb-2">Rewards for completing:</p>
            <div className="flex items-center gap-4">
              <span className="flex items-center gap-1.5 text-accent-600 font-semibold">
                <Sparkles className="w-5 h-5" />+{xpReward} XP
              </span>
              <span className="flex items-center gap-1.5 text-yellow-600 font-semibold">
                <Coins className="w-5 h-5" />+{coinReward} coins
              </span>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="flex justify-end gap-3 p-6 border-t border-gray-100">
          <button onClick={onClose} className="kawaii-button-secondary">
            Cancel
          </button>
          <button
            onClick={handleSave}
            disabled={!title.trim() || saving}
            className="kawaii-button disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {saving ? 'Saving...' : isEditing ? 'Save Changes' : 'Create Task'}
          </button>
        </div>
      </div>
    </div>
  );
}
