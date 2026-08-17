import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';

import '../../app/theme.dart';
import '../../core/models/field_models.dart';
import '../../core/network/api_client.dart';
import '../../core/state/app_controller.dart';
import '../../design_system/app_ui.dart';

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({
    required this.formId,
    required this.draftId,
    super.key,
  });

  final int formId;
  final String? draftId;

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  final _scrollController = ScrollController();
  final _textControllers = <String, TextEditingController>{};
  final _missingKeys = <String>{};
  Timer? _saveDebounce;
  FieldAssignment? _assignment;
  DraftRecord? _draft;
  Map<String, dynamic> _values = {};
  bool _isSaving = false;
  bool _isSubmitting = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    final controller = ref.read(appControllerProvider);
    _assignment = controller.assignmentById(widget.formId);
    if (_assignment != null) {
      _draft = widget.draftId == null
          ? controller.beginDraft(_assignment!)
          : controller.draftById(widget.draftId!);
      _draft ??= controller.beginDraft(_assignment!);
      _values = Map<String, dynamic>.from(_draft!.values);
      for (final field
          in _assignment!.version?.fields ?? const <FieldDefinition>[]) {
        if (_usesTextInput(field)) {
          _textControllers[field.key] = TextEditingController(
            text: _values[field.key]?.toString() ?? '',
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _setValue(String key, dynamic value) {
    setState(() {
      _values[key] = value;
      _missingKeys.remove(key);
      _formError = null;
      _isSaving = true;
    });
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 500), _saveNow);
  }

  Future<void> _saveNow() async {
    if (_draft == null) return;
    await ref.read(appControllerProvider).updateDraft(_draft!.id, _values);
    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _submit() async {
    final fields = _assignment?.version?.fields ?? const <FieldDefinition>[];
    final missing = fields
        .where((field) => field.required && _isEmpty(_values[field.key]))
        .map((field) => field.key)
        .toSet();
    if (missing.isNotEmpty) {
      setState(() {
        _missingKeys
          ..clear()
          ..addAll(missing);
        _formError =
            'Complete ${missing.length} required field${missing.length == 1 ? '' : 's'} before submitting.';
      });
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
      return;
    }
    await _saveNow();
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.fact_check_outlined),
        title: const Text('Submit this record?'),
        content: const Text(
          'Confirm that the information is complete, accurate and ready for ICCASA review. You cannot edit it after submission.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Review again'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit record'),
          ),
        ],
      ),
    );
    if (confirmed != true || _draft == null) return;
    setState(() {
      _isSubmitting = true;
      _formError = null;
    });
    try {
      final synced = await ref
          .read(appControllerProvider)
          .submitDraft(_draft!.id, _values);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            synced
                ? 'Record submitted for review.'
                : 'Record saved to the sync queue.',
          ),
        ),
      );
      context.go('/records');
    } on ApiException catch (error) {
      setState(() => _formError = error.message);
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _close() async {
    await _saveNow();
    if (mounted) context.go('/assignments/${widget.formId}');
  }

  @override
  Widget build(BuildContext context) {
    final assignment = _assignment;
    if (assignment == null || assignment.version == null) {
      return Scaffold(
        body: EmptyState(
          icon: Icons.assignment_late_outlined,
          title: 'Form unavailable',
          message: 'This collection form is not available on the device.',
          action: FilledButton(
            onPressed: () => context.go('/assignments'),
            child: const Text('Back to assignments'),
          ),
        ),
      );
    }
    final fields = assignment.version!.fields;
    final completed = fields
        .where((field) => !_isEmpty(_values[field.key]))
        .length;
    final progress = fields.isEmpty ? 0.0 : completed / fields.length;
    final tablet = MediaQuery.sizeOf(context).width >= 850;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Save and close',
          onPressed: _close,
          icon: const Icon(Icons.close_rounded),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              assignment.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              _isSaving ? 'Saving draft...' : 'Draft saved on this device',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: StatusBadge(
                '${(progress * 100).round()}%',
                icon: Icons.donut_large_rounded,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tablet)
              _ProgressRail(
                fields: fields,
                values: _values,
                missing: _missingKeys,
              ),
            Expanded(
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      tablet ? 28 : 16,
                      24,
                      tablet ? 28 : 16,
                      120,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 820),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Collection record',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                assignment.version!.instructions,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 18),
                              LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$completed of ${fields.length} fields completed',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (_formError != null) ...[
                                const SizedBox(height: 18),
                                MessageBanner(message: _formError!),
                              ],
                              const SizedBox(height: 22),
                              ...fields.indexed.map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _FieldCard(
                                    index: entry.$1,
                                    field: entry.$2,
                                    value: _values[entry.$2.key],
                                    textController:
                                        _textControllers[entry.$2.key],
                                    showError: _missingKeys.contains(
                                      entry.$2.key,
                                    ),
                                    onChanged: (value) =>
                                        _setValue(entry.$2.key, value),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : _close,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(tablet ? 'Save and close' : 'Save draft'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      _isSubmitting ? 'Submitting...' : 'Review and submit',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressRail extends StatelessWidget {
  const _ProgressRail({
    required this.fields,
    required this.values,
    required this.missing,
  });

  final List<FieldDefinition> fields;
  final Map<String, dynamic> values;
  final Set<String> missing;

  @override
  Widget build(BuildContext context) => Container(
    width: 250,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
    ),
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Form progress', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 18),
        ...fields.indexed.map((entry) {
          final complete = !_isEmpty(values[entry.$2.key]);
          final error = missing.contains(entry.$2.key);
          return Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: error
                      ? Theme.of(context).colorScheme.errorContainer
                      : complete
                      ? AppColors.emerald
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: complete && !error
                      ? const Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: Colors.white,
                        )
                      : Text(
                          '${entry.$1 + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: error
                                ? Theme.of(context).colorScheme.error
                                : null,
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.$2.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    ),
  );
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({
    required this.index,
    required this.field,
    required this.value,
    required this.onChanged,
    required this.showError,
    this.textController,
  });

  final int index;
  final FieldDefinition field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;
  final bool showError;
  final TextEditingController? textController;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: field.label,
                  children: [
                    if (field.required)
                      TextSpan(
                        text: '  *',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                ),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _DynamicInput(
          field: field,
          value: value,
          onChanged: onChanged,
          textController: textController,
          showError: showError,
        ),
        if (showError) ...[
          const SizedBox(height: 8),
          Text(
            'This field is required.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    ),
  );
}

class _DynamicInput extends StatefulWidget {
  const _DynamicInput({
    required this.field,
    required this.value,
    required this.onChanged,
    required this.showError,
    this.textController,
  });

  final FieldDefinition field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;
  final bool showError;
  final TextEditingController? textController;

  @override
  State<_DynamicInput> createState() => _DynamicInputState();
}

class _DynamicInputState extends State<_DynamicInput> {
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    final type = widget.field.normalizedType;
    if (type.contains('checkbox') || type == 'boolean') {
      return CheckboxListTile(
        value: widget.value == true,
        onChanged: (value) => widget.onChanged(value ?? false),
        title: const Text('Yes, confirmed'),
        subtitle: const Text('Tap to confirm this statement.'),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
    }
    if (type.contains('select') ||
        type.contains('dropdown') ||
        type.contains('choice')) {
      final options = widget.field.options;
      return DropdownButtonFormField<String>(
        initialValue: options.contains(widget.value)
            ? widget.value?.toString()
            : null,
        isExpanded: true,
        decoration: InputDecoration(
          errorText: widget.showError ? '' : null,
          hintText: 'Select an option',
        ),
        items: options
            .map(
              (option) => DropdownMenuItem(value: option, child: Text(option)),
            )
            .toList(),
        onChanged: widget.onChanged,
      );
    }
    if (type.contains('date')) {
      final date = DateTime.tryParse(widget.value?.toString() ?? '');
      return InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final selected = await showDatePicker(
            context: context,
            firstDate: DateTime(2000),
            lastDate: DateTime.now().add(const Duration(days: 730)),
            initialDate: date ?? DateTime.now(),
          );
          if (selected != null) {
            widget.onChanged(selected.toIso8601String().split('T').first);
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            errorText: widget.showError ? '' : null,
            prefixIcon: const Icon(Icons.calendar_today_outlined),
          ),
          child: Text(
            date == null
                ? 'Choose a date'
                : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
          ),
        ),
      );
    }
    if (type.contains('gps') || type.contains('location')) {
      return _locationInput(context);
    }
    if (type.contains('photo') ||
        type.contains('image') ||
        type.contains('file')) {
      return _photoInput(context);
    }
    if (type.contains('signature')) return _signatureInput(context);
    final number =
        type.contains('number') ||
        type.contains('decimal') ||
        type.contains('integer');
    final long =
        type.contains('long') ||
        type.contains('narrative') ||
        type.contains('textarea');
    return TextField(
      controller: widget.textController,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.multiline,
      minLines: long ? 4 : 1,
      maxLines: long ? 7 : 1,
      onChanged: (input) =>
          widget.onChanged(number ? num.tryParse(input) ?? input : input),
      decoration: InputDecoration(
        hintText: long
            ? 'Enter a clear, factual response'
            : number
            ? 'Enter a value'
            : 'Enter response',
        errorText: widget.showError ? '' : null,
      ),
    );
  }

  Widget _locationInput(BuildContext context) {
    final location = widget.value is Map
        ? Map<String, dynamic>.from(widget.value as Map)
        : null;
    return OutlinedButton.icon(
      onPressed: _working ? null : _captureLocation,
      icon: _working
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              location == null
                  ? Icons.my_location_rounded
                  : Icons.location_on_rounded,
            ),
      label: Text(
        location == null
            ? 'Capture current location'
            : '${location['latitude']}, ${location['longitude']}',
      ),
    );
  }

  Future<void> _captureLocation() async {
    setState(() => _working = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Location services are turned off.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is required for this field.');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      widget.onChanged({
        'latitude': double.parse(position.latitude.toStringAsFixed(6)),
        'longitude': double.parse(position.longitude.toStringAsFixed(6)),
        'accuracy_m': double.parse(position.accuracy.toStringAsFixed(1)),
        'captured_at': DateTime.now().toIso8601String(),
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Widget _photoInput(BuildContext context) {
    final file = widget.value is Map
        ? Map<String, dynamic>.from(widget.value as Map)
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _working ? null : _capturePhoto,
          icon: _working
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_a_photo_outlined),
          label: Text(
            file == null ? 'Capture or choose photo' : 'Replace photo',
          ),
        ),
        if (file != null) ...[
          const SizedBox(height: 10),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.image_outlined),
            title: Text(file['filename']?.toString() ?? 'Evidence image'),
            subtitle: const Text('Saved securely with this draft'),
            trailing: IconButton(
              tooltip: 'Remove photo',
              onPressed: () => widget.onChanged(null),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _capturePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add evidence photo',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                subtitle: const Text('Use this device camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from library'),
                subtitle: const Text('Attach an existing evidence image'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;
    setState(() => _working = true);
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 74,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      widget.onChanged({
        'filename': file.name,
        'content_type': file.mimeType ?? 'image/jpeg',
        '_upload_bytes': base64Encode(bytes),
        'captured_at': DateTime.now().toIso8601String(),
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo could not be captured: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Widget _signatureInput(BuildContext context) {
    final signed = widget.value is Map;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _captureSignature,
          icon: Icon(
            signed ? Icons.check_circle_outline_rounded : Icons.draw_outlined,
          ),
          label: Text(signed ? 'Replace signature' : 'Capture signature'),
        ),
        if (signed) ...[
          const SizedBox(height: 8),
          Text(
            'Signature captured',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.emerald,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _captureSignature() async {
    final signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
    final bytes = await showDialog<List<int>?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Capture signature'),
        content: SizedBox(
          width: 520,
          height: 260,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Signature(
              controller: signatureController,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: signatureController.clear,
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (signatureController.isEmpty) return;
              final image = await signatureController.toPngBytes();
              if (context.mounted) Navigator.pop(context, image?.toList());
            },
            child: const Text('Use signature'),
          ),
        ],
      ),
    );
    signatureController.dispose();
    if (bytes != null && bytes.isNotEmpty) {
      widget.onChanged({
        'filename': 'signature-${DateTime.now().millisecondsSinceEpoch}.png',
        'content_type': 'image/png',
        '_upload_bytes': base64Encode(bytes),
        'captured_at': DateTime.now().toIso8601String(),
      });
    }
  }
}

bool _usesTextInput(FieldDefinition field) {
  final type = field.normalizedType;
  return !(type.contains('checkbox') ||
      type == 'boolean' ||
      type.contains('select') ||
      type.contains('dropdown') ||
      type.contains('choice') ||
      type.contains('date') ||
      type.contains('gps') ||
      type.contains('location') ||
      type.contains('photo') ||
      type.contains('image') ||
      type.contains('file') ||
      type.contains('signature'));
}

bool _isEmpty(dynamic value) {
  if (value == null || value == false) return true;
  if (value is String) return value.trim().isEmpty;
  if (value is Map || value is Iterable) return value.isEmpty;
  return false;
}
