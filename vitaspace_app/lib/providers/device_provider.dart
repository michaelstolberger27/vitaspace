import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class DeviceProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _devices = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get devices => _devices;
  bool get isLoading => _isLoading;

  /// Fetch devices for the given user and space.
  Future<void> fetchDevices(String userId, String spaceId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('spaces')
          .doc(spaceId)
          .collection('devices')
          .get();

      _devices =
          snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      print('❌ Error fetching devices: $e');
      _devices = []; // Reset devices list on error
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Add a new device to Firestore.
  Future<void> addDevice(
      String userId, String spaceId, String name, String ipAddress) async {
    final document = {
      'name': name,
      'status': 'offline',
      'ipAddress': ipAddress,
    };
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('spaces')
          .doc(spaceId)
          .collection('devices')
          .add(document);

      _devices.add({'id': docRef.id, ...document});
      notifyListeners();
    } catch (e) {
      print('❌ Error adding device: $e');
    }
  }

  /// Remove a device from Firestore.
  Future<void> removeDevice(
      String userId, String spaceId, String deviceId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('spaces')
          .doc(spaceId)
          .collection('devices')
          .doc(deviceId)
          .delete();

      _devices.removeWhere((device) => device['id'] == deviceId);
      notifyListeners();
    } catch (e) {
      print('❌ Error removing device: $e');
    }
  }

  /// Rename a device in Firestore.
  Future<void> renameDevice(
      String userId, String spaceId, String deviceId, String newName) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('spaces')
          .doc(spaceId)
          .collection('devices')
          .doc(deviceId)
          .update({'name': newName});

      final deviceIndex =
          _devices.indexWhere((device) => device['id'] == deviceId);
      if (deviceIndex != -1) {
        _devices[deviceIndex]['name'] = newName;
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error renaming device: $e');
    }
  }
}
