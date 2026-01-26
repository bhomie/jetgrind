import { useState, useEffect } from 'react';
import {
  Plus,
  CheckCircle2,
  Circle,
  Trash2,
  ChevronRight,
  ChevronDown,
  Edit3,
  ListTree,
  Sparkles,
} from 'lucide-react';
import { useTaskStore } from '../../stores/taskStore';
import { useUserStore } from '../../stores/userStore';
import { useToastStore } from '../../stores/toastStore';
import { cn } from '../../utils/cn';
import { TaskModal } from './TaskModal';
import type { Task, TaskPriority, TaskSize, CreateTask } from '../../../shared/types';

export function TaskList() {
  const { tasks, loading, createTask, updateTask, completeTask, deleteTask, init } = useTaskStore();
  const { refresh: refreshUser } = useUserStore();
  const { showReward, showLevelUp, showSuccess } = useToastStore();

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingTask, setEditingTask] = useState<Task | null>(null);
  const [parentTask, setParentTask] = useState<Task | null>(null);
  const [expandedTasks, setExpandedTasks] = useState<Set<string>>(new Set());
  const [completingTaskId, setCompletingTaskId] = useState<string | null>(null);

  useEffect(() => {
    init();
  }, [init]);

  const handleCreateTask = async (data: CreateTask) => {
    await createTask(data);
    showSuccess('Task Created', 'Your task has been added!');
  };

  const handleUpdateTask = async (data: CreateTask) => {
    if (editingTask) {
      await updateTask(editingTask.id, data);
      showSuccess('Task Updated', 'Your changes have been saved!');
    }
  };

  const handleCompleteTask = async (task: Task) => {
    setCompletingTaskId(task.id);

    // Add a small delay for the animation
    setTimeout(async () => {
      const result = await completeTask(task.id);
      setCompletingTaskId(null);

      if (result) {
        showReward(result.xpEarned, result.coinsEarned, 'Task Complete!');
        await refreshUser();

        if (result.leveledUp && result.newLevel) {
          setTimeout(() => showLevelUp(result.newLevel!), 500);
        }
      }
    }, 300);
  };

  const handleAddSubtask = (task: Task) => {
    setParentTask(task);
    setEditingTask(null);
    setIsModalOpen(true);
  };

  const handleEditTask = (task: Task) => {
    setEditingTask(task);
    setParentTask(null);
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setEditingTask(null);
    setParentTask(null);
  };

  const toggleExpanded = (taskId: string) => {
    setExpandedTasks((prev) => {
      const next = new Set(prev);
      if (next.has(taskId)) {
        next.delete(taskId);
      } else {
        next.add(taskId);
      }
      return next;
    });
  };

  // Organize tasks: root tasks and their subtasks
  const rootTasks = tasks.filter((t) => !t.parentId);
  const getSubtasks = (parentId: string) => tasks.filter((t) => t.parentId === parentId);

  const pendingRootTasks = rootTasks.filter((t) => t.status !== 'completed');
  const completedRootTasks = rootTasks.filter((t) => t.status === 'completed');

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin w-8 h-8 border-4 border-primary-200 border-t-primary-500 rounded-full" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-800">Tasks</h1>
        <button
          onClick={() => {
            setEditingTask(null);
            setParentTask(null);
            setIsModalOpen(true);
          }}
          className="kawaii-button flex items-center gap-2"
        >
          <Plus className="w-4 h-4" />
          Add Task
        </button>
      </div>

      {/* Task List */}
      <div className="space-y-3">
        {pendingRootTasks.length === 0 ? (
          <div className="kawaii-card text-center py-12">
            <div className="text-6xl mb-4">🎉</div>
            <h3 className="text-xl font-medium text-gray-700">All caught up!</h3>
            <p className="text-gray-500 mt-2">Add a new task to get started.</p>
          </div>
        ) : (
          pendingRootTasks.map((task) => (
            <TaskItemWithSubtasks
              key={task.id}
              task={task}
              subtasks={getSubtasks(task.id)}
              isExpanded={expandedTasks.has(task.id)}
              isCompleting={completingTaskId === task.id}
              onToggleExpand={() => toggleExpanded(task.id)}
              onComplete={() => handleCompleteTask(task)}
              onDelete={() => deleteTask(task.id)}
              onEdit={() => handleEditTask(task)}
              onAddSubtask={() => handleAddSubtask(task)}
              onCompleteSubtask={handleCompleteTask}
              onDeleteSubtask={(id) => deleteTask(id)}
              completingTaskId={completingTaskId}
            />
          ))
        )}
      </div>

      {/* Completed Tasks */}
      {completedRootTasks.length > 0 && (
        <div className="mt-8">
          <h2 className="text-lg font-medium text-gray-500 mb-3">
            Completed ({completedRootTasks.length})
          </h2>
          <div className="space-y-2 opacity-60">
            {completedRootTasks.slice(0, 5).map((task) => (
              <TaskItem
                key={task.id}
                task={task}
                onComplete={() => {}}
                onDelete={() => deleteTask(task.id)}
                onEdit={() => {}}
                isCompleting={false}
              />
            ))}
          </div>
        </div>
      )}

      {/* Task Modal */}
      <TaskModal
        isOpen={isModalOpen}
        onClose={handleCloseModal}
        onSave={editingTask ? handleUpdateTask : handleCreateTask}
        task={editingTask || undefined}
        parentTask={parentTask || undefined}
      />
    </div>
  );
}

interface TaskItemWithSubtasksProps {
  task: Task;
  subtasks: Task[];
  isExpanded: boolean;
  isCompleting: boolean;
  onToggleExpand: () => void;
  onComplete: () => void;
  onDelete: () => void;
  onEdit: () => void;
  onAddSubtask: () => void;
  onCompleteSubtask: (task: Task) => void;
  onDeleteSubtask: (id: string) => void;
  completingTaskId: string | null;
}

function TaskItemWithSubtasks({
  task,
  subtasks,
  isExpanded,
  isCompleting,
  onToggleExpand,
  onComplete,
  onDelete,
  onEdit,
  onAddSubtask,
  onCompleteSubtask,
  onDeleteSubtask,
  completingTaskId,
}: TaskItemWithSubtasksProps) {
  const pendingSubtasks = subtasks.filter((s) => s.status !== 'completed');
  const completedSubtasks = subtasks.filter((s) => s.status === 'completed');
  const hasSubtasks = subtasks.length > 0;

  return (
    <div>
      <TaskItem
        task={task}
        onComplete={onComplete}
        onDelete={onDelete}
        onEdit={onEdit}
        hasSubtasks={hasSubtasks}
        isExpanded={isExpanded}
        onToggleExpand={onToggleExpand}
        onAddSubtask={onAddSubtask}
        subtaskCount={pendingSubtasks.length}
        isCompleting={isCompleting}
      />

      {/* Subtasks */}
      {hasSubtasks && isExpanded && (
        <div className="ml-8 mt-2 space-y-2 border-l-2 border-primary-100 pl-4">
          {pendingSubtasks.map((subtask) => (
            <TaskItem
              key={subtask.id}
              task={subtask}
              onComplete={() => onCompleteSubtask(subtask)}
              onDelete={() => onDeleteSubtask(subtask.id)}
              onEdit={() => {}}
              isSubtask
              isCompleting={completingTaskId === subtask.id}
            />
          ))}
          {completedSubtasks.length > 0 && (
            <div className="opacity-50 space-y-2">
              {completedSubtasks.map((subtask) => (
                <TaskItem
                  key={subtask.id}
                  task={subtask}
                  onComplete={() => {}}
                  onDelete={() => onDeleteSubtask(subtask.id)}
                  onEdit={() => {}}
                  isSubtask
                  isCompleting={false}
                />
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}

interface TaskItemProps {
  task: Task;
  onComplete: () => void;
  onDelete: () => void;
  onEdit: () => void;
  hasSubtasks?: boolean;
  isExpanded?: boolean;
  onToggleExpand?: () => void;
  onAddSubtask?: () => void;
  subtaskCount?: number;
  isSubtask?: boolean;
  isCompleting: boolean;
}

function TaskItem({
  task,
  onComplete,
  onDelete,
  onEdit,
  hasSubtasks,
  isExpanded,
  onToggleExpand,
  onAddSubtask,
  subtaskCount,
  isSubtask,
  isCompleting,
}: TaskItemProps) {
  const isCompleted = task.status === 'completed';

  const priorityColors: Record<TaskPriority, string> = {
    low: 'bg-blue-100 text-blue-700',
    medium: 'bg-yellow-100 text-yellow-700',
    high: 'bg-red-100 text-red-700',
  };

  const sizeLabels: Record<TaskSize, string> = {
    small: 'S',
    medium: 'M',
    large: 'L',
  };

  return (
    <div
      className={cn(
        'kawaii-card flex items-center gap-4 group transition-all duration-300',
        isCompleted && 'opacity-50',
        isSubtask && 'py-3',
        isCompleting && 'scale-95 opacity-70'
      )}
    >
      {/* Expand/Collapse for tasks with subtasks */}
      {hasSubtasks && (
        <button
          onClick={onToggleExpand}
          className="flex-shrink-0 p-1 text-gray-400 hover:text-gray-600 transition-colors"
        >
          {isExpanded ? (
            <ChevronDown className="w-4 h-4" />
          ) : (
            <ChevronRight className="w-4 h-4" />
          )}
        </button>
      )}

      {/* Checkbox */}
      <button
        onClick={onComplete}
        disabled={isCompleted || isCompleting}
        className={cn(
          'flex-shrink-0 transition-all duration-300',
          isCompleted
            ? 'text-green-500'
            : isCompleting
            ? 'text-primary-400 scale-110'
            : 'text-gray-300 hover:text-primary-400'
        )}
      >
        {isCompleted || isCompleting ? (
          <CheckCircle2 className={cn('w-6 h-6', isCompleting && 'animate-pulse')} />
        ) : (
          <Circle className="w-6 h-6" />
        )}
      </button>

      {/* Task Content */}
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          <p
            className={cn(
              'font-medium truncate',
              isCompleted && 'line-through text-gray-400',
              isCompleting && 'text-gray-400'
            )}
          >
            {task.title}
          </p>
          {hasSubtasks && subtaskCount && subtaskCount > 0 && (
            <span className="flex items-center gap-1 text-xs text-gray-400">
              <ListTree className="w-3 h-3" />
              {subtaskCount}
            </span>
          )}
        </div>
        <div className="flex items-center gap-2 mt-1">
          <span
            className={cn('text-xs px-2 py-0.5 rounded-full', priorityColors[task.priority])}
          >
            {task.priority}
          </span>
          <span className="text-xs px-2 py-0.5 rounded-full bg-gray-100 text-gray-600">
            {sizeLabels[task.size]}
          </span>
          <span className="text-xs text-accent-600 flex items-center gap-0.5">
            <Sparkles className="w-3 h-3" />+{task.xpReward} XP
          </span>
        </div>
      </div>

      {/* Actions */}
      <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
        {!isSubtask && !isCompleted && onAddSubtask && (
          <button
            onClick={onAddSubtask}
            className="p-2 text-gray-400 hover:text-primary-500 transition-colors"
            title="Add subtask"
          >
            <ListTree className="w-4 h-4" />
          </button>
        )}
        {!isCompleted && (
          <button
            onClick={onEdit}
            className="p-2 text-gray-400 hover:text-primary-500 transition-colors"
            title="Edit task"
          >
            <Edit3 className="w-4 h-4" />
          </button>
        )}
        <button
          onClick={onDelete}
          className="p-2 text-gray-400 hover:text-red-500 transition-colors"
          title="Delete task"
        >
          <Trash2 className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
}
