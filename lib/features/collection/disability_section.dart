import 'package:flutter/material.dart';

import '../../core/services/disability_metadata.dart';
import '../../design_system/app_ui.dart';

class DisabilitySection extends StatelessWidget {
  const DisabilitySection({
    required this.value,
    required this.onChanged,
    required this.statusError,
    required this.typesError,
    required this.otherTypeError,
    super.key,
  });

  final Map<String, dynamic> value;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final bool statusError;
  final bool typesError;
  final bool otherTypeError;

  @override
  Widget build(BuildContext context) {
    final status = value['status']?.toString() ?? '';
    final selfIdentified = status == selfIdentifiedDisability;
    final typeLabels = disabilityTypeLabels(value);
    return Column(
      children: [
        _DisabilityFieldCard(
          index: 3,
          label: 'Disability status',
          value: status.isEmpty ? '' : disabilityStatusLabel(status),
          placeholder: 'Select disability status',
          helper:
              'Record only information the respondent chooses to disclose or that has been formally assessed.',
          error: statusError,
          required: true,
          enabled: true,
          onTap: () => _selectStatus(context),
        ),
        const SizedBox(height: 16),
        _DisabilityFieldCard(
          index: 4,
          label: 'Type(s) of disability',
          value:
              selfIdentified && (value['types'] as List? ?? const []).isNotEmpty
              ? typeLabels.join(', ')
              : '',
          placeholder: selfIdentified
              ? 'Select one or more disability types'
              : status.isEmpty
              ? 'Select disability status first'
              : 'Not applicable for this status',
          error: typesError || otherTypeError,
          required: selfIdentified,
          enabled: selfIdentified,
          onTap: () => _selectTypes(context),
        ),
      ],
    );
  }

  Future<void> _selectStatus(BuildContext context) async {
    final selected = await showModalBottomSheet<DisabilityOption>(
      context: context,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select disability status',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            ...disabilityStatusOptions.map(
              (option) => ListTile(
                leading: Icon(
                  value['status']?.toString() == option.value
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: value['status']?.toString() == option.value
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                title: Text(option.label),
                selected: value['status']?.toString() == option.value,
                onTap: () => Navigator.pop(context, option),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    onChanged({
      'status': selected.value,
      'types': <String>[],
      'other_type': '',
    });
  }

  Future<void> _selectTypes(BuildContext context) async {
    final selected = <String>{
      ...(value['types'] as List? ?? const []).map((item) => item.toString()),
    };
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => FractionallySizedBox(
          heightFactor: .82,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Select all applicable types',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'More than one disability type can be selected.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: disabilityTypeOptions
                        .map(
                          (option) => CheckboxListTile(
                            value: selected.contains(option.value),
                            title: Text(option.label),
                            onChanged: (checked) => setSheetState(() {
                              if (checked == true) {
                                selected.add(option.value);
                              } else {
                                selected.remove(option.value);
                              }
                            }),
                          ),
                        )
                        .toList(),
                  ),
                ),
                FilledButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () => Navigator.pop(context, selected.toList()),
                  child: const Text('Use selected types'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result == null) return;
    if (!context.mounted) return;
    var otherType = value['other_type']?.toString() ?? '';
    if (result.contains(otherDisabilityType) && otherType.trim().isEmpty) {
      final described = await _askForOtherType(context);
      if (described != null) otherType = described;
    }
    onChanged({
      ...value,
      'types': result,
      'other_type': result.contains(otherDisabilityType) ? otherType : '',
    });
  }

  Future<String?> _askForOtherType(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Describe the other disability type'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 120,
          decoration: const InputDecoration(labelText: 'Disability type'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final description = controller.text.trim();
              if (description.length >= 2) Navigator.pop(context, description);
            },
            child: const Text('Use description'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }
}

class _DisabilityFieldCard extends StatelessWidget {
  const _DisabilityFieldCard({
    required this.index,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.error,
    required this.required,
    required this.enabled,
    required this.onTap,
    this.helper,
  });

  final int index;
  final String label;
  final String value;
  final String placeholder;
  final String? helper;
  final bool error;
  final bool required;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                '$index',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: label,
                  children: [
                    if (required)
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
        InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: InputDecorator(
            decoration: InputDecoration(
              errorText: error ? '' : null,
              prefixIcon: const Icon(Icons.accessible_forward_rounded),
              suffixIcon: const Icon(Icons.expand_more_rounded),
            ),
            child: Text(
              value.isEmpty ? placeholder : value,
              style: value.isEmpty
                  ? Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).hintColor,
                    )
                  : Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 8),
          Text(helper!, style: Theme.of(context).textTheme.bodySmall),
        ],
        if (error) ...[
          const SizedBox(height: 8),
          Text(
            required
                ? '$label is required.'
                : 'Complete the disability type details.',
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
