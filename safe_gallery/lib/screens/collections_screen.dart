import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/collection.dart';
import 'photo_picker_screen.dart';
import 'presentation_screen.dart';
import 'settings_screen.dart';

class CollectionsScreen extends StatelessWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS
        ? const _IOSCollectionsScreen()
        : const _AndroidCollectionsScreen();
  }
}

class _AndroidCollectionsScreen extends StatelessWidget {
  const _AndroidCollectionsScreen();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safe Gallery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.collections.isEmpty
              ? _buildEmptyState(context)
              : _buildCollectionGrid(context, provider.collections),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewCollection(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No collections yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first collection',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionGrid(BuildContext context, List<Collection> collections) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: collections.length,
      itemBuilder: (context, index) {
        final collection = collections[index];
        return _CollectionCard(
          collection: collection,
          onTap: () => _openPresentation(context, collection),
          onLongPress: () => _showCollectionOptions(context, collection),
        );
      },
    );
  }

  void _createNewCollection(BuildContext context) async {
    final name = await _showNameDialog(context, 'New Collection');
    if (name == null || name.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoPickerScreen(collectionName: name),
      ),
    );
  }

  void _openPresentation(BuildContext context, Collection collection) {
    if (collection.photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This collection has no photos')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PresentationScreen(collection: collection),
      ),
    );
  }

  void _showCollectionOptions(BuildContext context, Collection collection) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () async {
                Navigator.pop(context);
                final newName = await _showNameDialog(context, 'Rename Collection', collection.name);
                if (newName != null && newName.isNotEmpty) {
                  context.read<AppProvider>().updateCollectionName(collection.id, newName);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_photo_alternate),
              title: const Text('Add Photos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PhotoPickerScreen(
                      collectionId: collection.id,
                      collectionName: collection.name,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, collection);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Collection collection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Collection'),
        content: Text('Delete "${collection.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AppProvider>().deleteCollection(collection.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showNameDialog(BuildContext context, String title, [String? initialValue]) {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Collection name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _IOSCollectionsScreen extends StatelessWidget {
  const _IOSCollectionsScreen();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Safe Gallery'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.settings),
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
      ),
      child: SafeArea(
        child: provider.isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : provider.collections.isEmpty
                ? _buildEmptyState(context)
                : _buildCollectionGrid(context, provider.collections),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.photo_on_rectangle, size: 64, color: CupertinoColors.systemGrey),
          const SizedBox(height: 16),
          const Text(
            'No collections yet',
            style: TextStyle(fontSize: 20, color: CupertinoColors.systemGrey),
          ),
          const SizedBox(height: 16),
          CupertinoButton.filled(
            child: const Text('Create Collection'),
            onPressed: () => _createNewCollection(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionGrid(BuildContext context, List<Collection> collections) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final collection = collections[index];
                return _CollectionCard(
                  collection: collection,
                  onTap: () => _openPresentation(context, collection),
                  onLongPress: () => _showCollectionOptions(context, collection),
                );
              },
              childCount: collections.length,
            ),
          ),
        ),
      ],
    );
  }

  void _createNewCollection(BuildContext context) async {
    final name = await _showNameDialog(context, 'New Collection');
    if (name == null || name.isEmpty) return;

    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => PhotoPickerScreen(collectionName: name),
      ),
    );
  }

  void _openPresentation(BuildContext context, Collection collection) {
    if (collection.photos.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          content: const Text('This collection has no photos'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => PresentationScreen(collection: collection),
      ),
    );
  }

  void _showCollectionOptions(BuildContext context, Collection collection) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(collection.name),
        actions: [
          CupertinoActionSheetAction(
            child: const Text('Rename'),
            onPressed: () async {
              Navigator.pop(context);
              final newName = await _showNameDialog(context, 'Rename Collection', collection.name);
              if (newName != null && newName.isNotEmpty) {
                context.read<AppProvider>().updateCollectionName(collection.id, newName);
              }
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Add Photos'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (_) => PhotoPickerScreen(
                    collectionId: collection.id,
                    collectionName: collection.name,
                  ),
                ),
              );
            },
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () {
              Navigator.pop(context);
              _confirmDelete(context, collection);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Collection collection) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Collection'),
        content: Text('Delete "${collection.name}"? This cannot be undone.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () {
              context.read<AppProvider>().deleteCollection(collection.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<String?> _showNameDialog(BuildContext context, String title, [String? initialValue]) {
    final controller = TextEditingController(text: initialValue);
    return showCupertinoDialog<String>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: CupertinoTextField(
            controller: controller,
            autofocus: true,
            placeholder: 'Collection name',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text('Save'),
            onPressed: () => Navigator.pop(context, controller.text),
          ),
        ],
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final Collection collection;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _CollectionCard({
    required this.collection,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: collection.thumbnailPath != null
                  ? Image.file(
                      File(collection.thumbnailPath!),
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.photo, size: 48, color: Colors.grey[500]),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${collection.photoCount} photo${collection.photoCount != 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
