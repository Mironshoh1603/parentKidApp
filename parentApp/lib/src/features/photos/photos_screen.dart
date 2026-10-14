import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/photo_model.dart';
import '../../providers.dart';

/// Oshkora rasmlar galereyasi (Bosqich 5) — ota-ona tomoni.
class PhotosScreen extends ConsumerWidget {
  final String childId;
  final String childName;
  const PhotosScreen(
      {super.key, required this.childId, required this.childName});

  Future<void> _request(BuildContext context, WidgetRef ref) async {
    await ref.read(commandServiceProvider).requestPhoto(childId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Rasm so\'rovi yuborildi. Bola ko\'rib yuboradi.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(photosProvider(childId));
    return Scaffold(
      appBar: AppBar(
        title: Text('Rasmlar — $childName'),
        actions: [
          IconButton(
            tooltip: 'Rasm so\'rash',
            icon: const Icon(Icons.add_a_photo),
            onPressed: () => _request(context, ref),
          ),
        ],
      ),
      body: photos.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Xatolik: $e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_library_outlined, size: 64),
                    const SizedBox(height: 12),
                    const Text(
                      'Hali rasm yo\'q.\nYuqoridagi tugma orqali rasm so\'rang.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _request(context, ref),
                      icon: const Icon(Icons.add_a_photo),
                      label: const Text('Rasm so\'rash'),
                    ),
                  ],
                ),
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: list.length,
            itemBuilder: (_, i) => _PhotoTile(
              photo: list[i],
              onTap: () => _open(context, ref, list[i]),
            ),
          );
        },
      ),
    );
  }

  void _open(BuildContext context, WidgetRef ref, PhotoModel p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PhotoViewer(
          photo: p,
          onDelete: () async {
            await ref.read(photoServiceProvider).delete(childId, p.id);
          },
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final PhotoModel photo;
  final VoidCallback onTap;
  const _PhotoTile({required this.photo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('dd/MM HH:mm').format(photo.createdAt.toLocal());
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              photo.url,
              fit: BoxFit.cover,
              loadingBuilder: (c, w, p) => p == null
                  ? w
                  : const Center(child: CircularProgressIndicator()),
              errorBuilder: (c, e, s) =>
                  const Center(child: Icon(Icons.broken_image)),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: Colors.black54,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      photo.source == 'sos'
                          ? Icons.sos
                          : Icons.photo_camera,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(time,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoViewer extends StatelessWidget {
  final PhotoModel photo;
  final Future<void> Function() onDelete;
  const _PhotoViewer({required this.photo, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final time =
        DateFormat('dd MMMM yyyy, HH:mm').format(photo.createdAt.toLocal());
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(time),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Rasm o\'chirilsinmi?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Bekor')),
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('O\'chirish')),
                  ],
                ),
              );
              if (ok == true) {
                await onDelete();
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            photo.url,
            fit: BoxFit.contain,
            errorBuilder: (c, e, s) => const Icon(Icons.broken_image,
                color: Colors.white, size: 64),
          ),
        ),
      ),
    );
  }
}
