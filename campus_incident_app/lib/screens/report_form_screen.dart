import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/validators.dart';
import '../models/incident.dart';
import '../providers/incident_provider.dart';
import '../widgets/incident_style.dart';

/// The form a student uses to report a campus problem
class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _detailsController = TextEditingController();
  final _picker = ImagePicker();

  IncidentCategory? _category;
  String? _location;
  XFile? _photo;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _choosePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      // Shrinking the picture keeps uploads fast and storage small
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (file != null && mounted) setState(() => _photo = file);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the camera or gallery.')),
      );
    }
  }

  Future<void> _submit() async {
    // Stop here and show the red messages if any field is invalid.
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<IncidentProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final success = await provider.submitReport(
      title: _titleController.text,
      description: _descriptionController.text,
      category: _category!,
      location: _location!,
      locationDetails: _detailsController.text,
      photo: _photo,
    );

    if (success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Report submitted. Thank you!')),
      );
      if (mounted) navigator.pop();
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Could not submit the report.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.select<IncidentProvider, bool>(
      (p) => p.isSubmitting,
    );
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Report an Incident')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionLabel('Select a category'),
                _buildCategoryPicker(theme),
                const SizedBox(height: 20),
                _sectionLabel('Title'),
                TextFormField(
                  controller: _titleController,
                  maxLength: Validators.titleMax,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Briefly describe the issue',
                  ),
                  validator: Validators.incidentTitle,
                ),
                const SizedBox(height: 12),
                _sectionLabel('Description'),
                TextFormField(
                  controller: _descriptionController,
                  maxLength: Validators.descriptionMax,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'What happened, when, and how it affects people',
                    alignLabelWithHint: true,
                  ),
                  validator: Validators.incidentDescription,
                ),
                const SizedBox(height: 12),
                _sectionLabel('Location'),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                  hint: const Text('Where is the problem?'),
                  items: [
                    for (final place in AppConstants.campusLocations)
                      DropdownMenuItem(value: place, child: Text(place)),
                  ],
                  onChanged: (value) => setState(() => _location = value),
                  validator: (value) => Validators.requiredChoice(
                    value,
                    'Please choose a location',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _detailsController,
                  maxLength: 80,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: 'Room or exact spot (optional), e.g. Room 204',
                  ),
                ),
                const SizedBox(height: 12),
                _sectionLabel('Add a photo (optional)'),
                _buildPhotoPicker(),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: isSubmitting ? null : _submit,
                  child: isSubmitting
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : const Text('Submit Report'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Chips for the six categories. A FormField lets the form validate the
  /// choice and show an error under the chips if none is selected
  Widget _buildCategoryPicker(ThemeData theme) {
    return FormField<IncidentCategory>(
      validator: (value) =>
          Validators.requiredChoice(value, 'Please select a category'),
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in IncidentCategory.values)
                  ChoiceChip(
                    avatar: Icon(categoryIcon(category), size: 18),
                    label: Text(category.label),
                    selected: field.value == category,
                    onSelected: (_) {
                      field.didChange(category);
                      setState(() => _category = category);
                    },
                  ),
              ],
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: Text(
                  field.errorText!,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPhotoPicker() {
    final photo = _photo;

    if (photo == null) {
      return OutlinedButton.icon(
        onPressed: _choosePhoto,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Tap to add a photo'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(photo.path),
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton.filled(
            tooltip: 'Remove photo',
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => _photo = null),
          ),
        ),
      ],
    );
  }
}
