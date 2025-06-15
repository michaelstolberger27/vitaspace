import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_database/firebase_database.dart';
import 'my_account_page.dart';
import 'spaces_page.dart';
import 'notification_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Data lists for charts
  List<FlSpot> temperatureData = [];
  List<FlSpot> humidityData = [];
  List<FlSpot> dustData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSensorData();
  }

  Future<void> _fetchSensorData() async {
    try {
      // Reference to the sensor data in Firebase Realtime Database
      DatabaseReference databaseRef =
          FirebaseDatabase.instance.ref().child('sensor_data');

      // Fetch the last 5 entries
      Query lastFiveEntriesQuery =
          databaseRef.orderByChild('timestamp').limitToLast(5);

      DataSnapshot snapshot = await lastFiveEntriesQuery.get();

      if (snapshot.exists) {
        // Clear existing data
        temperatureData.clear();
        humidityData.clear();
        dustData.clear();

        // Convert the data to a map
        Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;

        // Sort the entries by timestamp
        var sortedEntries = values.entries.toList()
          ..sort((a, b) =>
              (a.value['timestamp'] as int).compareTo(b.value['timestamp']));

        // Process the last 5 entries
        for (int i = 0; i < sortedEntries.length; i++) {
          var entry = sortedEntries[i].value;

          // Add data points to respective lists
          temperatureData.add(
              FlSpot(i.toDouble(), (entry['temperature'] as num).toDouble()));
          humidityData
              .add(FlSpot(i.toDouble(), (entry['humidity'] as num).toDouble()));
          dustData.add(FlSpot(
              i.toDouble(), (entry['dust_concentration'] as num).toDouble()));
        }
      }

      // Update the UI
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching sensor data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildGraph(String title, List<FlSpot> data, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 200,
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: color))
                  : data.isNotEmpty
                      ? LineChart(
                          LineChartData(
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: data,
                                isCurved: true,
                                color: color,
                                dotData: FlDotData(show: false),
                                belowBarData: BarAreaData(
                                    show: true, color: color.withOpacity(0.3)),
                              )
                            ],
                          ),
                        )
                      : Center(
                          child: Text(
                            'No data available',
                            style: TextStyle(color: color),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'VitaSpace',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4EAACC)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.account_circle,
                          size: 40, color: Color(0xFF4EAACC)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const MyAccountPage()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGraph(
                          'Room Temperature (°C)', temperatureData, Colors.red),
                      _buildGraph(
                          'Room Humidity (%)', humidityData, Colors.blue),
                      _buildGraph(
                          'Dust Concentration (µg/m³)', dustData, Colors.green),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.space_dashboard_outlined),
              activeIcon: Icon(Icons.space_dashboard),
              label: 'Spaces'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications),
              label: 'Notifications'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF4EAACC),
        unselectedItemColor: Colors.black54,
        selectedFontSize: 14,
        unselectedFontSize: 12,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });

          // Navigate to corresponding pages
          switch (index) {
            case 1:
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const SpacesPage()));
              break;
            case 2:
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NotificationPage()));
              break;
          }
        },
      ),
    );
  }
}
