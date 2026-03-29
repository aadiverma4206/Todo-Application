import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = "tasks";

  Future<void> addTask(TaskModel task) async {
    final docRef = _firestore.collection(_collection).doc();
    final newTask = task.copyWith(id: docRef.id);
    await docRef.set(newTask.toMap());
  }

  Stream<List<TaskModel>> getUserTasks(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TaskModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> updateTask(TaskModel task) async {
    await _firestore
        .collection(_collection)
        .doc(task.id)
        .update(task.toMap());
  }

  Future<void> deleteTask(String taskId) async {
    await _firestore.collection(_collection).doc(taskId).delete();
  }

  Future<void> toggleComplete(TaskModel task) async {
    await _firestore.collection(_collection).doc(task.id).update({
      'isCompleted': !task.isCompleted,
    });
  }

  Future<TaskModel?> getTaskById(String taskId) async {
    final doc = await _firestore.collection(_collection).doc(taskId).get();

    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null) return null;

    return TaskModel.fromMap(data, doc.id);
  }

  Future<void> deleteAllTasks(String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .get();

    final batch = _firestore.batch();

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}