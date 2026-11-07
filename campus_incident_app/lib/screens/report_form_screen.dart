import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/validators.dart';
import '../models/incident.dart';
import '../providers/incident_provider.dart';
import '../widgets/incident_style.dart';

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ReportFormScreen()));
  }

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
      final file = await _picker.pickImage(
        source: source,
        maxWidth: AppConstants.photoMaxWidth,
        imageQuality: AppConstants.photoQuality,
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
            provider.actionErrorMessage ?? 'Could not submit the report.',
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

  Widget _buildCategoryPicker(ThemeData theme) {
    return FormField<IncidentCategory>(
      validator: (value) =>
          Validators.requiredChoice(value, 'Please select a category'),
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.25,
              children: [
                for (final category in IncidentCategory.values)
                  _CategoryTile(
                    category: category,
                    selected: field.value == category,
                    onTap: () {
                      field.didChange(category);
                      setState(() => _category = category);
                    },
                  ),
              ],
            ),
            if (_category == IncidentCategory.safety)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withAlpha(24),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Safety reports are automatically flagged as urgent.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final IncidentCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: selected ? colors.primaryContainer : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? colors.primary : colors.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              categoryIcon(category),
              color: selected ? colors.primary : colors.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            Text(
              category.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected ? colors.onPrimaryContainer : colors.onSurface,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
