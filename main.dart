import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TaskManager(),
    );
  }
}

class TaskManager extends StatefulWidget {
  const TaskManager({super.key});

  @override
  State<TaskManager> createState() => _TaskManagerState();
}

class _TaskManagerState extends State<TaskManager> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _availableTags = ['Work', 'Personal', 'Urgent'];

  bool showCompleted = true;
  String? activeTagFilter;
  final List<Task> tasks = [];

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase();

    final filtered = tasks.where((task) {
      final matchesTag = activeTagFilter == null || task.tag == activeTagFilter;
      final matchesSearch = task.title.toLowerCase().contains(query);
      final matchesCompleted = showCompleted || !task.isCompleted;
      return matchesTag && matchesSearch && matchesCompleted;
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          _TopBar(
            searchController: _searchController,
            onChanged: (_) => setState(() {}),
            onAdd: () => _showAddTaskSheet(context),
          ),
          _Filters(
            tags: _availableTags,
            activeTag: activeTagFilter,
            onTagSelected: (tag) => setState(() => activeTagFilter = tag),
            showCompleted: showCompleted,
            onToggleCompleted: (v) => setState(() => showCompleted = v),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: filtered.isEmpty
                  ? _EmptyState(onAdd: () => _showAddTaskSheet(context))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final task = filtered[i];
                        return _TaskCard(
                          task: task,
                          onChanged: (updated) => _updateTask(updated),
                          onDelete: () => _deleteTask(task),
                          onEdit: () => _showEditTaskSheet(context, task),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _TaskSheet(
        onSave: (task) => setState(() => tasks.add(task)),
        availableTags: _availableTags,
      ),
    );
  }

  void _showEditTaskSheet(BuildContext context, Task task) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _TaskSheet(
        task: task,
        onSave: (updated) => setState(() {
          final index = tasks.indexOf(task);
          tasks[index] = updated;
        }),
        availableTags: _availableTags,
      ),
    );
  }

  void _updateTask(Task updated) => setState(() {
        final index = tasks.indexWhere((t) => t.id == updated.id);
        if (index != -1) tasks[index] = updated;
      });

  void _deleteTask(Task task) => setState(() => tasks.remove(task));
}

// ---------------- UI Components ----------------

class _TopBar extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onChanged;
  final VoidCallback onAdd;

  const _TopBar({
    required this.searchController,
    required this.onChanged,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.add_circle, size: 32, color: Colors.blue),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final List<String> tags;
  final String? activeTag;
  final ValueChanged<String?> onTagSelected;
  final bool showCompleted;
  final ValueChanged<bool> onToggleCompleted;

  const _Filters({
    required this.tags,
    required this.activeTag,
    required this.onTagSelected,
    required this.showCompleted,
    required this.onToggleCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: activeTag == null,
            onSelected: (_) => onTagSelected(null),
          ),
          ...tags.map((tag) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: FilterChip(
                  label: Text(tag),
                  selected: activeTag == tag,
                  onSelected: (_) => onTagSelected(tag),
                ),
              )),
          const SizedBox(width: 10),
          FilterChip(
            label: const Text('Show Completed'),
            selected: showCompleted,
            onSelected: (v) => onToggleCompleted(v),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final ValueChanged<Task> onChanged;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _TaskCard({
    required this.task,
    required this.onChanged,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (v) => onChanged(task.copyWith(isCompleted: v ?? false)),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: task.tag != null ? Text(task.tag!) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
            IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text('No tasks yet. Add one!'),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Task'),
          ),
        ],
      ),
    );
  }
}

class _TaskSheet extends StatefulWidget {
  final Task? task;
  final ValueChanged<Task> onSave;
  final List<String> availableTags;

  const _TaskSheet({
    this.task,
    required this.onSave,
    required this.availableTags,
  });

  @override
  State<_TaskSheet> createState() => _TaskSheetState();
}

class _TaskSheetState extends State<_TaskSheet> {
  late TextEditingController _titleController;
  String? selectedTag;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    selectedTag = widget.task?.tag;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Task Title'),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            children: widget.availableTags
                .map((tag) => ChoiceChip(
                      label: Text(tag),
                      selected: selectedTag == tag,
                      onSelected: (_) => setState(() => selectedTag = tag),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              final task = Task(
                id: widget.task?.id ?? UniqueKey().toString(),
                title: _titleController.text,
                tag: selectedTag,
                isCompleted: widget.task?.isCompleted ?? false,
              );
              widget.onSave(task);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ---------------- Model ----------------

class Task {
  final String id;
  final String title;
  final String? tag;
  final bool isCompleted;

  Task({
    required this.id,
    required this.title,
    this.tag,
    this.isCompleted = false,
  });

  Task copyWith({String? title, String? tag, bool? isCompleted}) => Task(
        id: id,
        title: title ?? this.title,
        tag: tag ?? this.tag,
        isCompleted: isCompleted ?? this.isCompleted,
      );
}
