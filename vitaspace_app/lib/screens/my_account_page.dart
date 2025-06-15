import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/spaces_provider.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'reset_password_page.dart';
import 'help_page.dart';

class MyAccountPage extends StatelessWidget {
  const MyAccountPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Back Button and Title
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF4EAACC), // Turquoise
                      size: 28,
                    ),
                    onPressed: () {
                      Navigator.pop(
                          context); // Takes the user back to the last page
                    },
                  ),
                  const Text(
                    'My Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4EAACC), // Turquoise
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // User Icon and Email
            Column(
              children: [
                const Icon(
                  Icons.person,
                  size: 100,
                  color: Color(0xFF4EAACC), // Turquoise
                ),
                const SizedBox(height: 10),
                Text(
                  user?.email ?? 'No email available',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Account Management Options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildAccountOption(
                    context,
                    icon: Icons.lock,
                    label: "Change Password",
                    onTap: () {
                      // Navigate to change password page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ResetPasswordPage(),
                        ),
                      );
                    },
                  ),
                  _buildAccountOption(
                    context,
                    icon: Icons.help_outline,
                    label: "Help",
                    onTap: () {
                      // Navigate to HelpPage
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HelpPage(),
                        ),
                      );
                    },
                  ),
                  _buildAccountOption(
                    context,
                    icon: Icons.logout,
                    label: "Sign Out",
                    onTap: () async {
                      final spacesProvider =
                          Provider.of<SpacesProvider>(context, listen: false);

                      // Clear spaces data
                      spacesProvider.clearSpaces();

                      // Sign out user
                      await FirebaseAuth.instance.signOut();

                      // Navigate to LoginPage
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to build account options
  Widget _buildAccountOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[200], // Light gray background
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF4EAACC), // Turquoise
              size: 28,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
