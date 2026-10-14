import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/cloudinary_config.dart';
import '../../providers.dart';
import '../../services/photo_service.dart';

/// OSHKORA rasm yuborish ekrani. Bola kamerani O'ZI ochadi va rasmni ko'rib
/// turib yuboradi. Maxfiy suratga olish YO'Q — bola har doim xabardor.
class CheckinScreen extends ConsumerStatefulWidget {
  /// Agar ota-ona so'rovi (`request_photo`) orqali ochilgan bo'lsa — komanda id'si.
  final String? commandId;
  const CheckinScreen({super.key, this.commandId});

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  final _picker = ImagePicker();
  XFile? _photo;
  bool _sending = false;
  String? _message;

  bool get _isRequested => widget.commandId != null;

  Future<void> _openCamera() async {
    try {
      final shot = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1280,
      );
      if (shot != null) setState(() => _photo = shot);
    } catch (e) {
      setState(() => _message = 'Kamera ochilmadi: $e');
    }
  }

  Future<void> _markCommandDone() async {
    final id = widget.commandId;
    if (id == null) return;
    await ref.read(childCommandServiceProvider)?.markDone(id);
  }

  Future<void> _send() async {
    final photo = _photo;
    if (photo == null) return;
    setState(() {
      _sending = true;
      _message = null;
    });
    final res = await ref
        .read(photoServiceProvider)
        .sendPhoto(File(photo.path), source: 'checkin');
    if (!mounted) return;
    if (res.ok) {
      await _markCommandDone();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rasm ota-onangizga yuborildi ✓')),
      );
      return;
    }
    setState(() {
      _sending = false;
      _message = _errorText(res.status);
    });
  }

  String _errorText(PhotoUploadStatus s) {
    switch (s) {
      case PhotoUploadStatus.notConfigured:
        return 'Cloudinary sozlanmagan (cloudinary_config.dart).';
      case PhotoUploadStatus.uploadFailed:
        return 'Yuklab bo\'lmadi — internetni tekshiring.';
      case PhotoUploadStatus.noAuth:
        return 'Qurilma juftlanmagan.';
      default:
        return 'Xatolik yuz berdi. Qayta urining.';
    }
  }

  Future<void> _cancel() async {
    await _markCommandDone();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rasm yuborish'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _sending ? null : _cancel,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // OSHKORALIK bildirgisi.
            Card(
              color: scheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(_isRequested
                        ? Icons.notifications_active
                        : Icons.photo_camera),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isRequested
                            ? 'Ota-onangiz rasm so\'radi. Rasm ularga yuboriladi.'
                            : 'Bu rasm ota-onangizga yuboriladi.',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: _photo == null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_a_photo,
                              size: 96, color: scheme.outline),
                          const SizedBox(height: 12),
                          const Text('Rasmga olish uchun tugmani bosing'),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(File(_photo!.path),
                            fit: BoxFit.contain),
                      ),
              ),
            ),
            if (!CloudinaryConfig.isConfigured) ...[
              const SizedBox(height: 8),
              Text(
                'Eslatma: Cloudinary hali sozlanmagan — yuborish ishlamaydi.',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.error, fontSize: 12),
              ),
            ],
            if (_message != null) ...[
              const SizedBox(height: 8),
              Text(_message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.error)),
            ],
            const SizedBox(height: 16),
            if (_photo == null)
              FilledButton.icon(
                onPressed: _openCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Kamerani ochish'),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _sending ? null : _openCamera,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Qayta'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send),
                      label: Text(_sending ? 'Yuborilmoqda...' : 'Yuborish'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
