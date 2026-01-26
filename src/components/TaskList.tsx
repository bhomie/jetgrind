import React, { useState } from 'react';
import { useTasks } from '../contexts/TaskContext';

const TaskList: React.FC = () => {
  const { tasks, addTask, updateTask, deleteTask } = useTasks();
  const [isAddingTask, setIsAddingTask] = useState(false);
  const [newTask, setNewTask] = useState({
    title: '',
    description: '',
    priority: 'medium' as const,
    estimatedPomodoros: 1,
  });

  const handleAddTask = (e: React.FormEvent) => {
    e.preventDefault();
    addTask({
      ...newTask,
      status: 'todo',
    });
    setNewTask({
      title: '',
      description: '',
      priority: 'medium',
      estimatedPomodoros: 1,
    });
    setIsAddingTask(false);
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'high':
        return 'bg-red-100 text-red-800';
      case 'medium':
        return 'bg-yellow-100 text-yellow-800';
      case 'low':
        return 'bg-green-100 text-green-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  return (
    <div className="max-w-4xl mx-auto">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold text-gray-800">Tasks</h1>
        <button
          onClick={() => setIsAddingTask(true)}
          className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors"
        >
          Add Task
        </button>
      </div>

      {isAddingTask && (
        <div className="bg-white rounded-lg shadow-lg p-6 mb-6">
          <h2 className="text-xl font-semibold text-gray-800 mb-4">New Task</h2>
          <form onSubmit={handleAddTask}>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Title
                </label>
                <input
                  type="text"
                  value={newTask.title}
                  onChange={(e) =>
                    setNewTask({ ...newTask, title: e.target.value })
                  }
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  required
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Description
                </label>
                <textarea
                  value={newTask.description}
                  onChange={(e) =>
                    setNewTask({ ...newTask, description: e.target.value })
                  }
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  rows={3}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Priority
                </label>
                <select
                  value={newTask.priority}
                  onChange={(e) =>
                    setNewTask({
                      ...newTask,
                      priority: e.target.value as 'low' | 'medium' | 'high',
                    })
                  }
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                >
                  <option value="low">Low</option>
                  <option value="medium">Medium</option>
                  <option value="high">High</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Estimated Pomodoros
                </label>
                <input
                  type="number"
                  min="1"
                  value={newTask.estimatedPomodoros}
                  onChange={(e) =>
                    setNewTask({
                      ...newTask,
                      estimatedPomodoros: parseInt(e.target.value),
                    })
                  }
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                />
              </div>
            </div>
            <div className="mt-6 flex justify-end space-x-3">
              <button
                type="button"
                onClick={() => setIsAddingTask(false)}
                className="px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors"
              >
                Cancel
              </button>
              <button
                type="submit"
                className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors"
              >
                Add Task
              </button>
            </div>
          </form>
        </div>
      )}

      <div className="space-y-4">
        {tasks.map((task) => (
          <div
            key={task.id}
            className="bg-white rounded-lg shadow p-6 hover:shadow-md transition-shadow"
          >
            <div className="flex justify-between items-start">
              <div>
                <h3 className="text-lg font-semibold text-gray-800">
                  {task.title}
                </h3>
                <p className="text-gray-600 mt-1">{task.description}</p>
              </div>
              <div className="flex items-center space-x-2">
                <span
                  className={`px-2 py-1 rounded-full text-sm ${getPriorityColor(
                    task.priority
                  )}`}
                >
                  {task.priority}
                </span>
                <span className="text-sm text-gray-500">
                  {task.pomodorosCompleted}/{task.estimatedPomodoros} pomodoros
                </span>
              </div>
            </div>
            <div className="mt-4 flex justify-between items-center">
              <div className="flex space-x-2">
                <button
                  onClick={() =>
                    updateTask(task.id, {
                      status:
                        task.status === 'todo'
                          ? 'in-progress'
                          : task.status === 'in-progress'
                          ? 'completed'
                          : 'todo',
                    })
                  }
                  className="px-3 py-1 text-sm bg-blue-100 text-blue-800 rounded hover:bg-blue-200 transition-colors"
                >
                  {task.status === 'todo'
                    ? 'Start'
                    : task.status === 'in-progress'
                    ? 'Complete'
                    : 'Reopen'}
                </button>
                <button
                  onClick={() => deleteTask(task.id)}
                  className="px-3 py-1 text-sm bg-red-100 text-red-800 rounded hover:bg-red-200 transition-colors"
                >
                  Delete
                </button>
              </div>
              <span className="text-sm text-gray-500">
                Created: {new Date(task.createdAt).toLocaleDateString()}
              </span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default TaskList; 