import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todolist_apps/model/todoModel.dart';

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  List<Todo> _todos = [];
  List<Todo> _filteredTodos = [];
  bool _isLoading = true;
  String _filterStatus = 'all'; // 'all', 'completed', 'active'
  String _filterPriority = 'all'; // 'all', 'low', 'medium', 'high'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final todosString = prefs.getString('todos');

    setState(() {
      if (todosString != null) {
        final List<dynamic> todosJson = jsonDecode(todosString);
        _todos = todosJson.map((json) => Todo.fromJson(json)).toList();
      }
      _applyFilters();
      _isLoading = false;
    });
  }

  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final String todosString = jsonEncode(
      _todos.map((todo) => todo.toJson()).toList(),
    );
    await prefs.setString('todos', todosString);
  }

  void _addTodo(Todo todo) {
    setState(() {
      _todos.add(todo);
      _applyFilters();
    });
    _saveTodos();
  }

  void _updateTodo(Todo updatedTodo) {
    setState(() {
      final index = _todos.indexWhere((todo) => todo.id == updatedTodo.id);
      if (index != -1) {
        _todos[index] = updatedTodo;
        _applyFilters();
      }
    });
    _saveTodos();
  }

  void _deleteTodo(String id) {
    setState(() {
      _todos.removeWhere((todo) => todo.id == id);
      _applyFilters();
    });
    _saveTodos();
  }

  void _toggleTodoCompletion(String id) {
    setState(() {
      final index = _todos.indexWhere((todo) => todo.id == id);
      if (index != -1) {
        _todos[index].isCompleted = !_todos[index].isCompleted;
        _applyFilters();
      }
    });
    _saveTodos();
  }

  void _applyFilters() {
    _filteredTodos =
        _todos.where((todo) {
          // Apply status filter
          if (_filterStatus == 'completed' && !todo.isCompleted) return false;
          if (_filterStatus == 'active' && todo.isCompleted) return false;

          // Apply priority filter
          if (_filterPriority != 'all' && todo.priority != _filterPriority)
            return false;

          // Apply search query
          if (_searchQuery.isNotEmpty &&
              !todo.title.toLowerCase().contains(_searchQuery.toLowerCase()) &&
              !todo.description.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              )) {
            return false;
          }

          return true;
        }).toList();

    // Sort todos by completion status and creation date
    _filteredTodos.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1; // Incomplete todos first
      }

      // Sort by priority (high to low)
      final priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
      if (a.priority != b.priority) {
        return priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
      }

      // Sort by due date if available
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      } else if (a.dueDate != null) {
        return -1; // Items with due dates come first
      } else if (b.dueDate != null) {
        return 1;
      }

      // Sort by creation date (newest first)
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Todo List',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _filterStatus = value;
                _applyFilters();
              });
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(value: 'all', child: Text('All Tasks')),
                  const PopupMenuItem(
                    value: 'active',
                    child: Text('Active Tasks'),
                  ),
                  const PopupMenuItem(
                    value: 'completed',
                    child: Text('Completed Tasks'),
                  ),
                ],
            icon: const Icon(Icons.filter_list, color: Colors.white),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search todos...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _applyFilters();
                        });
                      },
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('All'),
                          selected: _filterPriority == 'all',
                          onSelected: (selected) {
                            setState(() {
                              _filterPriority = 'all';
                              _applyFilters();
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('High Priority'),
                          selected: _filterPriority == 'high',
                          backgroundColor: Colors.red[100],
                          selectedColor: Colors.red[200],
                          onSelected: (selected) {
                            setState(() {
                              _filterPriority = 'high';
                              _applyFilters();
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Medium Priority'),
                          selected: _filterPriority == 'medium',
                          backgroundColor: Colors.orange[100],
                          selectedColor: Colors.orange[200],
                          onSelected: (selected) {
                            setState(() {
                              _filterPriority = 'medium';
                              _applyFilters();
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Low Priority'),
                          selected: _filterPriority == 'low',
                          backgroundColor: Colors.green[100],
                          selectedColor: Colors.green[200],
                          onSelected: (selected) {
                            setState(() {
                              _filterPriority = 'low';
                              _applyFilters();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child:
                        _filteredTodos.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.task_alt,
                                    size: 70,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _todos.isEmpty
                                        ? 'No tasks yet! Add your first task.'
                                        : 'No tasks match your filters.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              itemCount: _filteredTodos.length,
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              itemBuilder: (context, index) {
                                final todo = _filteredTodos[index];

                                // Choose color based on priority
                                Color priorityColor;
                                switch (todo.priority) {
                                  case 'high':
                                    priorityColor = Colors.red;
                                    break;
                                  case 'medium':
                                    priorityColor = Colors.orange;
                                    break;
                                  case 'low':
                                    priorityColor = Colors.green;
                                    break;
                                  default:
                                    priorityColor = Colors.blue;
                                }

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: priorityColor.withOpacity(0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 8.0,
                                    ),
                                    leading: Checkbox(
                                      value: todo.isCompleted,
                                      activeColor: Colors.blue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      onChanged: (value) {
                                        _toggleTodoCompletion(todo.id);
                                      },
                                    ),
                                    title: Text(
                                      todo.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        decoration:
                                            todo.isCompleted
                                                ? TextDecoration.lineThrough
                                                : null,
                                        color:
                                            todo.isCompleted
                                                ? Colors.grey
                                                : Colors.black,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (todo.description.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4.0,
                                            ),
                                            child: Text(
                                              todo.description,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                decoration:
                                                    todo.isCompleted
                                                        ? TextDecoration
                                                            .lineThrough
                                                        : null,
                                              ),
                                            ),
                                          ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: priorityColor
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                'Priority: ${todo.priority[0].toUpperCase() + todo.priority.substring(1)}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: priorityColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            if (todo.dueDate != null) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.calendar_today,
                                                      size: 12,
                                                      color: Colors.blue,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${todo.dueDate!.day}/${todo.dueDate!.month}/${todo.dueDate!.year}',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.blue,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          color: Colors.blue,
                                          onPressed: () {
                                            _showTodoDialog(
                                              context,
                                              todo: todo,
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          color: Colors.red,
                                          onPressed: () {
                                            _showDeleteConfirmation(
                                              context,
                                              todo,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showTodoDialog(context);
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Todo todo) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Task'),
            content: Text('Are you sure you want to delete "${todo.title}"?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () {
                  _deleteTodo(todo.id);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Task deleted'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                child: const Text(
                  'DELETE',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _showTodoDialog(BuildContext context, {Todo? todo}) {
    final isEditing = todo != null;
    final titleController = TextEditingController(text: todo?.title ?? '');
    final descriptionController = TextEditingController(
      text: todo?.description ?? '',
    );
    String priority = todo?.priority ?? 'medium';
    DateTime? dueDate = todo?.dueDate;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(isEditing ? 'Edit Task' : 'Add New Task'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                        autofocus: true,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Priority:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      RadioListTile<String>(
                        title: const Text('High'),
                        value: 'high',
                        groupValue: priority,
                        onChanged: (value) {
                          setState(() {
                            priority = value!;
                          });
                        },
                        activeColor: Colors.red,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      RadioListTile<String>(
                        title: const Text('Medium'),
                        value: 'medium',
                        groupValue: priority,
                        onChanged: (value) {
                          setState(() {
                            priority = value!;
                          });
                        },
                        activeColor: Colors.orange,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      RadioListTile<String>(
                        title: const Text('Low'),
                        value: 'low',
                        groupValue: priority,
                        onChanged: (value) {
                          setState(() {
                            priority = value!;
                          });
                        },
                        activeColor: Colors.green,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Due Date:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              dueDate == null
                                  ? 'Set Date'
                                  : '${dueDate?.day}/${dueDate?.month}/${dueDate?.year}',
                            ),
                            onPressed: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: dueDate ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  dueDate = pickedDate;
                                });
                              }
                            },
                          ),
                          if (dueDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  dueDate = null;
                                });
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('CANCEL'),
                  ),
                  TextButton(
                    onPressed: () {
                      if (titleController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Title cannot be empty'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (isEditing) {
                        final updatedTodo = Todo(
                          id: todo.id,
                          title: titleController.text.trim(),
                          description: descriptionController.text.trim(),
                          isCompleted: todo.isCompleted,
                          createdAt: todo.createdAt,
                          dueDate: dueDate,
                          priority: priority,
                        );
                        _updateTodo(updatedTodo);
                      } else {
                        final newTodo = Todo(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: titleController.text.trim(),
                          description: descriptionController.text.trim(),
                          createdAt: DateTime.now(),
                          dueDate: dueDate,
                          priority: priority,
                        );
                        _addTodo(newTodo);
                      }

                      Navigator.of(context).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEditing ? 'Task updated' : 'Task added',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    child: Text(isEditing ? 'UPDATE' : 'ADD'),
                  ),
                ],
              );
            },
          ),
    );
  }
}
