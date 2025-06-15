import 'package:flutter/material.dart';
import 'dart:math';
import 'my_account_page.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<String> notifications =
      List.generate(10, (index) => 'Notification ${index + 1}');

  void _clearNotification(int index) {
    setState(() {
      notifications.removeAt(index);
    });
  }

  void _clearAllNotifications() {
    setState(() {
      notifications.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4EAACC),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.account_circle,
                      color: Color(0xFF4EAACC),
                      size: 40,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyAccountPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Clear All Button
            if (notifications.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 9),
                child: TextButton(
                  onPressed: _clearAllNotifications,
                  child: const Text(
                    'Clear All',
                    style: TextStyle(
                      color: Color(0xFF4EAACC),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

            // Notifications List
            Expanded(
              child: notifications.isNotEmpty
                  ? ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        return NotificationTile(
                          index: index,
                          notification: notifications[index],
                          onDismiss: _clearNotification,
                        );
                      },
                    )
                  : const Center(
                      child: Text(
                        'No new notifications',
                        style: TextStyle(fontSize: 18, color: Colors.black54),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final int index;
  final String notification;
  final void Function(int) onDismiss;

  const NotificationTile({
    Key? key,
    required this.index,
    required this.notification,
    required this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification),
      direction: DismissDirection.startToEnd, // Swipe to right
      onDismissed: (direction) => onDismiss(index),
      background: TrashBinAnimation(), // Custom animated trash bin
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[100],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: ListTile(
          title: Text(
            notification,
            style: const TextStyle(color: Colors.black87),
          ),
          subtitle: const Text(
            'This is a sample notification description.',
            style: TextStyle(color: Colors.black54),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => onDismiss(index),
          ),
        ),
      ),
    );
  }
}

// Animated Trash Bin
class TrashBinAnimation extends StatefulWidget {
  @override
  _TrashBinAnimationState createState() => _TrashBinAnimationState();
}

class _TrashBinAnimationState extends State<TrashBinAnimation> {
  double swipeProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              // Calculate swipe progress based on the horizontal movement
              swipeProgress =
                  (details.primaryDelta ?? 0) / constraints.maxWidth;
              swipeProgress =
                  swipeProgress.clamp(0.0, 1.0); // Limit to 0.0 - 1.0
            });
          },
          onHorizontalDragEnd: (_) {
            // If swipe exceeds 50%, trigger the dismiss action
            if (swipeProgress > 0.5) {
              setState(() {
                swipeProgress = 1.0; // Open lid fully before dismissal
              });
            } else {
              setState(() {
                swipeProgress = 0.0; // Reset lid if swipe is insufficient
              });
            }
          },
          child: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.transparent,
            ),
            child: Stack(
              children: [
                // Trash Bin Base (Icon)
                const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 40,
                ),

                // Animated Lid (Opens as you swipe)
                Positioned(
                  top: -5,
                  left: 6,
                  child: Transform.rotate(
                    angle:
                        -pi / 4 * swipeProgress, // Lid rotates as user swipes
                    alignment: Alignment.bottomLeft,
                    child: const Icon(
                      Icons.remove, // Lid (using "-" as a visual trick)
                      color: Colors.redAccent,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
