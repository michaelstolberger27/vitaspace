import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/device_provider.dart';

class DevicesPage extends StatefulWidget {
  final String spaceId;

  const DevicesPage({Key? key, required this.spaceId}) : super(key: key);

  @override
  _DevicesPageState createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<DeviceProvider>(context, listen: false)
            .fetchDevices(userId, widget.spaceId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: true);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: Color(0xFF4EAACC), size: 28),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Devices',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4EAACC),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.add,
                        color: Color(0xFF4EAACC), size: 28),
                    onPressed: () {
                      _showWiFiConnectionDialog();
                    },
                  ),
                ],
              ),
            ),

            // Devices List
            Expanded(
              child: Consumer<DeviceProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (provider.devices.isEmpty) {
                    return const Center(
                      child: Text(
                        'No devices available',
                        style: TextStyle(color: Colors.black54),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: provider.devices.length,
                    itemBuilder: (context, index) {
                      final device = provider.devices[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(
                            device['name'],
                            style: const TextStyle(color: Colors.black87),
                          ),
                          tileColor: Colors.grey[200],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.more_vert,
                                color: Colors.grey, size: 28),
                            onPressed: () {
                              _showDeviceOptionsDialog(
                                  context, deviceProvider, device);
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show Wi-Fi credentials dialog
  void _showWiFiConnectionDialog() {
    String ssid = '';
    String password = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Connect to Device'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Step 1: Connect to the Wi-Fi network named:\n'
                    '"VitaSpace_<Device_ID>"\n\n'
                    'Step 2: Enter your home Wi-Fi SSID and password.',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Enter SSID'),
                    onChanged: (value) {
                      setDialogState(() {
                        ssid = value;
                      });
                    },
                  ),
                  TextField(
                    decoration:
                        const InputDecoration(labelText: 'Enter Password'),
                    obscureText: true,
                    onChanged: (value) {
                      setDialogState(() {
                        password = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (ssid.isNotEmpty && password.isNotEmpty) {
                      _sendWiFiCredentials(ssid, password);
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please enter valid credentials')),
                      );
                    }
                  },
                  child: const Text('Connect'),
                ),
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
              ],
            );
          },
        );
      },
    );
  }

  // Send Wi-Fi credentials and add device
  Future<void> _sendWiFiCredentials(String ssid, String password) async {
    final url = Uri.parse('http://192.168.4.1/prov');
    try {
      final response =
          await http.post(url, body: {'ssid': ssid, 'password': password});

      if (response.statusCode == 200) {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          Provider.of<DeviceProvider>(context, listen: false)
              .addDevice(userId, widget.spaceId, 'AdaptAir+', '192.168.4.1');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wi-Fi credentials sent successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send Wi-Fi credentials.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Show device options (rename or remove)
  void _showDeviceOptionsDialog(BuildContext context,
      DeviceProvider deviceProvider, Map<String, dynamic> device) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Options for "${device['name']}"'),
        content: const Text('What would you like to do?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showRenameDeviceDialog(context, deviceProvider, device);
            },
            child: const Text('Rename'),
          ),
          TextButton(
            onPressed: () async {
              final userId = FirebaseAuth.instance.currentUser?.uid;
              if (userId != null) {
                await deviceProvider.removeDevice(
                    userId, widget.spaceId, device['id']);
              }
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Show rename device dialog
  void _showRenameDeviceDialog(BuildContext context,
      DeviceProvider deviceProvider, Map<String, dynamic> device) {
    final TextEditingController controller =
        TextEditingController(text: device['name']);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename Device'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter new name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final userId = FirebaseAuth.instance.currentUser?.uid;
              if (userId != null) {
                await deviceProvider.renameDevice(
                    userId, widget.spaceId, device['id'], controller.text);
              }
              Navigator.pop(context);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }
}
