import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SpacesProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _spaces = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get spaces => _spaces;
  bool get isLoading => _isLoading;

  Future<void> fetchSpaces() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print('Error: User not authenticated.');
      return;
    }

    _isLoading = true;

    // Defer notifyListeners() to avoid the error during build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners(); // Notify listeners after the build phase
    });

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('spaces')
          .get();

      _spaces = snapshot.docs
          .map((doc) => {
                'id': doc.id,
                'name': doc['name'],
              })
          .toList();

      _isLoading = false;

      // Defer notifyListeners() to avoid the error during build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners(); // Notify listeners after the build phase
      });
    } catch (e) {
      print('Error fetching spaces: $e');
      _isLoading = false;

      // Defer notifyListeners() to avoid the error during build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners(); // Notify listeners after the build phase
      });

      rethrow;
    }
  }

  Future<void> addSpace(String name) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || name.isEmpty) return;

    try {
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('spaces')
          .add({'name': name});
      _spaces.add({'id': docRef.id, 'name': name});

      notifyListeners();
    } catch (e) {
      print('Error adding space: $e');
      rethrow;
    }
  }

  Future<void> renameSpace(String spaceId, String newName) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || newName.isEmpty) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('spaces')
          .doc(spaceId)
          .update({'name': newName});

      final space = _spaces.firstWhere((space) => space['id'] == spaceId);
      space['name'] = newName;
      notifyListeners();
    } catch (e) {
      print('Error renaming space: $e');
      rethrow;
    }
  }

  Future<void> deleteSpace(String spaceId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print('Error: User not authenticated.');
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('spaces')
          .doc(spaceId)
          .delete();

      _spaces.removeWhere((space) => space['id'] == spaceId);
      notifyListeners();
    } catch (e) {
      print('Error deleting space: $e');
      rethrow;
    }
  }

  void clearSpaces() {
    _spaces = [];
    notifyListeners();
  }
}
