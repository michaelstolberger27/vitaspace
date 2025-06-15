import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/spaces_provider.dart';
import 'devices_page.dart';
import 'my_account_page.dart';

class SpacesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacesProvider = Provider.of<SpacesProvider>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;

    // Fetch spaces if the user is logged in and they haven't been fetched yet
    if (user != null && spacesProvider.spaces.isEmpty) {
      spacesProvider.fetchSpaces();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Spaces',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4EAACC),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.account_circle,
                      color: Color(0xFF4EAACC), // Turquoise
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

            // Spaces List
            Expanded(
              child: Consumer<SpacesProvider>(
                builder: (context, provider, child) {
                  // Show a loading indicator if spaces are still being fetched
                  if (provider.spaces.isEmpty && provider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF4EAACC)),
                      ),
                    );
                  }

                  if (provider.spaces.isEmpty) {
                    return const Center(
                      child: Text(
                        'No spaces available.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: provider.spaces.length,
                    itemBuilder: (context, index) {
                      final space = provider.spaces[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(
                            space['name'],
                            style: const TextStyle(color: Colors.black87),
                          ),
                          tileColor: Colors.grey[200],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DevicesPage(spaceId: space['id']),
                              ),
                            );
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.more_vert,
                                color: Colors.grey, size: 28),
                            onPressed: () {
                              _showSpaceOptionsDialog(
                                  context, spacesProvider, space);
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4EAACC), // Turquoise
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          _showAddSpaceDialog(context, spacesProvider);
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showAddSpaceDialog(
      BuildContext context, SpacesProvider spacesProvider) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Space'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter space name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await spacesProvider.addSpace(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showSpaceOptionsDialog(BuildContext context,
      SpacesProvider spacesProvider, Map<String, dynamic> space) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Options for "${space['name']}"'),
        content: const Text('What would you like to do?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showRenameSpaceDialog(context, spacesProvider, space);
            },
            child: const Text('Rename'),
          ),
          TextButton(
            onPressed: () async {
              final confirm = await _confirmDeleteDialog(context);
              if (confirm) {
                await spacesProvider.deleteSpace(space['id']);
              }
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showRenameSpaceDialog(BuildContext context,
      SpacesProvider spacesProvider, Map<String, dynamic> space) {
    final TextEditingController controller =
        TextEditingController(text: space['name']);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename Space'),
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
              await spacesProvider.renameSpace(space['id'], controller.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF40E0D0), // Turquoise
            ),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDeleteDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Space'),
              content:
                  const Text('Are you sure you want to delete this space?'),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: const Text('Delete'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
