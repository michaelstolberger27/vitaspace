import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({Key? key}) : super(key: key);

  @override
  _BluetoothPageState createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  final List<BluetoothDevice> devicesList = [];
  BluetoothDevice? connectedDevice;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() {
    flutterBlue.startScan(timeout: const Duration(seconds: 5));
    flutterBlue.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (!devicesList.contains(result.device)) {
          setState(() {
            devicesList.add(result.device);
          });
        }
      }
    });
  }

  void _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      setState(() {
        connectedDevice = device;
      });
      _sendWifiCredentials(device);
    } catch (e) {
      print('Error connecting to device: $e');
    }
  }

  void _sendWifiCredentials(BluetoothDevice device) async {
    final List<BluetoothService> services = await device.discoverServices();
    for (BluetoothService service in services) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.properties.write) {
          await characteristic.write(
              utf8.encode('WIFI_SSID:yourSSID;WIFI_PASSWORD:yourPassword'));
          print('Wi-Fi credentials sent');
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Devices'),
        backgroundColor: const Color(0xFF40E0D0),
      ),
      body: ListView.builder(
        itemCount: devicesList.length,
        itemBuilder: (context, index) {
          final device = devicesList[index];
          return ListTile(
            title: Text(device.name),
            subtitle: Text(device.id.toString()),
            onTap: () => _connectToDevice(device),
          );
        },
      ),
    );
  }
}
