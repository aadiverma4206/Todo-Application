import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../models/task_model.dart';
import 'add_task_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final firestore = context.read<FirestoreService>();

    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Tasks"),
        actions: [
          IconButton(
            onPressed: () async {
              await auth.logout();
            },
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6C63FF),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddTaskScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<TaskModel>>(
        stream: firestore.getUserTasks(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final tasks = snapshot.data ?? [];

          if (tasks.isEmpty) {
            return const EmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return TaskCard(task: task);
            },
          );
        },
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final TaskModel task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: task.isCompleted
            ? Colors.green.withOpacity(0.1)
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
              Checkbox(
                value: task.isCompleted,
                onChanged: (value) async {
                  final updatedTask =
                  task.copyWith(isCompleted: value ?? false);

                  await firestore.updateTask(updatedTask);

                  if (updatedTask.isCompleted &&
                      task.notificationId != null) {
                    await NotificationService.cancelNotification(
                      task.notificationId!,
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (task.description.isNotEmpty)
            Text(
              task.description,
              style: const TextStyle(color: Colors.grey),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16),
              const SizedBox(width: 6),
              Text(
                task.reminderTime != null
                    ? DateFormat('dd MMM yyyy, hh:mm a')
                    .format(task.reminderTime!)
                    : "No Reminder",
                style: TextStyle(
                  fontSize: 12,
                  color: task.isOverdue ? Colors.red : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () async {
                  await firestore.deleteTask(task.id);

                  if (task.notificationId != null) {
                    await NotificationService.cancelNotification(
                      task.notificationId!,
                    );
                  }
                },
                icon: const Icon(Icons.delete, color: Colors.red),
              )
            ],
          )
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            "No Tasks Yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Tap + to add your first task",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}