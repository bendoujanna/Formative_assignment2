import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/incident.dart';
import '../providers/incident_provider.dart';

class IncidentPhoto extends StatefulWidget {
  const IncidentPhoto({super.key, required this.incident});

  final Incident incident;

  @override
  State<IncidentPhoto> createState() => _IncidentPhotoState();
}

class _IncidentPhotoState extends State<IncidentPhoto> {
  Future<Uint8List?>? _inlinePhoto;

  @override
  void initState() {
    super.initState();
    final incident = widget.incident;
    if (!incident.hasPhoto && incident.hasInlinePhoto) {
      _inlinePhoto = context.read<IncidentProvider>().loadInlinePhoto(
        incident.id,
      );
    }
  }

  void _openFullScreen(BuildContext context, ImageProvider provider) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Image(image: provider, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: SafeArea(
                child: IconButton.filled(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(dialogContext),
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
    final incident = widget.incident;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: _buildImage(context, incident),
      ),
    );
  }

  Widget _buildImage(BuildContext context, Incident incident) {
    if (incident.hasPhoto) {
      final url = incident.photoUrl!;
      return GestureDetector(
        onTap: () => _openFullScreen(context, NetworkImage(url)),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _message(context),
        ),
      );
    }

    return FutureBuilder<Uint8List?>(
      future: _inlinePhoto,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final bytes = snapshot.data;
        if (bytes == null) return _message(context);
        return GestureDetector(
          onTap: () => _openFullScreen(context, MemoryImage(bytes)),
          child: Image.memory(bytes, fit: BoxFit.cover),
        );
      },
    );
  }

  Widget _message(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Text('Photo unavailable', style: theme.textTheme.bodyMedium),
    );
  }
}
