import 'package:flutter/material.dart';

class SpaceDetailPage extends StatelessWidget {
  final String spaceName;

  const SpaceDetailPage({Key? key, required this.spaceName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          spaceName,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF40E0D0), // Turquoise
        iconTheme: const IconThemeData(color: Colors.white), // White back icon
      ),
      body: Container(
        color: Colors.white, // Set a solid white background
        child: Center(
          child: Text(
            'Welcome to $spaceName!',
            style: const TextStyle(
              fontSize: 24,
              color: Color(0xFF40E0D0), // Turquoise
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
