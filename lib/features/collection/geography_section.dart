import 'package:flutter/material.dart';

import '../../core/services/geography_repository.dart';
import '../../design_system/app_ui.dart';

class GeographySection extends StatefulWidget {
  const GeographySection({
    required this.value,
    required this.onChanged,
    required this.countryError,
    required this.areaError,
    super.key,
  });

  final Map<String, dynamic> value;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final bool countryError;
  final bool areaError;

  @override
  State<GeographySection> createState() => _GeographySectionState();
}

class _GeographySectionState extends State<GeographySection> {
  final _repository = GeographyRepository.instance;
  List<GeographyCountry> _countries = const [];
  List<GeographyArea> _areas = const [];
  bool _loadingCountries = true;
  bool _loadingAreas = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    try {
      final countries = await _repository.countries();
      if (!mounted) return;
      setState(() {
        _countries = countries;
        _loadingCountries = false;
      });
      final code = widget.value['country_code']?.toString() ?? '';
      if (code.isNotEmpty) await _loadAreas(code);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingCountries = false;
          _loadError = 'Location options could not be opened on this device.';
        });
      }
    }
  }

  Future<void> _loadAreas(String countryCode) async {
    setState(() {
      _loadingAreas = true;
      _areas = const [];
      _loadError = null;
    });
    try {
      final areas = await _repository.areasFor(countryCode);
      if (mounted) {
        setState(() {
          _areas = areas;
          _loadingAreas = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingAreas = false;
          _loadError = 'Location options could not be opened on this device.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final countryName = widget.value['country_name']?.toString() ?? '';
    final areaName = widget.value['administrative_area_name']?.toString() ?? '';
    final areaLabel =
        widget.value['administrative_area_type']?.toString() ??
        'District / county';
    return Column(
      children: [
        _GeographyFieldCard(
          index: 1,
          label: 'Country',
          value: countryName,
          placeholder: _loadingCountries
              ? 'Loading countries...'
              : 'Search and select a country',
          error: widget.countryError,
          enabled: !_loadingCountries && _countries.isNotEmpty,
          onTap: _selectCountry,
        ),
        const SizedBox(height: 16),
        _GeographyFieldCard(
          index: 2,
          label: areaLabel,
          value: areaName,
          placeholder:
              widget.value['country_code'] == null ||
                  widget.value['country_code'].toString().isEmpty
              ? 'Select a country first'
              : _loadingAreas
              ? 'Loading ${areaLabel.toLowerCase()} options...'
              : 'Search and select ${areaLabel.toLowerCase()}',
          error: widget.areaError,
          enabled: !_loadingAreas && _areas.isNotEmpty,
          onTap: _selectArea,
        ),
        if (_loadError != null) ...[
          const SizedBox(height: 10),
          MessageBanner(message: _loadError!),
        ],
      ],
    );
  }

  Future<void> _selectCountry() async {
    final selected = await _showSearchPicker<GeographyCountry>(
      context,
      title: 'Select country',
      items: _countries,
      label: (item) => item.name,
      detail: (_) => null,
    );
    if (selected == null) return;
    widget.onChanged({
      'country_code': selected.code,
      'country_name': selected.name,
      'administrative_area_code': '',
      'administrative_area_name': '',
      'administrative_area_type': selected.areaLabel,
    });
    await _loadAreas(selected.code);
  }

  Future<void> _selectArea() async {
    final selected = await _showSearchPicker<GeographyArea>(
      context,
      title:
          'Select ${widget.value['administrative_area_type'] ?? 'district / county'}',
      items: _areas,
      label: (item) => item.name,
      detail: (item) => item.parentName,
    );
    if (selected == null) return;
    var name = selected.name;
    if (selected.isCustom) {
      final custom = await _askForCustomArea();
      if (custom == null) return;
      name = custom;
    }
    widget.onChanged({
      ...widget.value,
      'administrative_area_code': selected.code,
      'administrative_area_name': name,
    });
  }

  Future<String?> _askForCustomArea() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Specify administrative area'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 150,
          decoration: const InputDecoration(
            labelText: 'District / county name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.length >= 2) Navigator.pop(context, value);
            },
            child: const Text('Use this name'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }
}

class _GeographyFieldCard extends StatelessWidget {
  const _GeographyFieldCard({
    required this.index,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.error,
    required this.enabled,
    required this.onTap,
  });

  final int index;
  final String label;
  final String value;
  final String placeholder;
  final bool error;
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
              prefixIcon: const Icon(Icons.search_rounded),
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
        if (error) ...[
          const SizedBox(height: 8),
          Text(
            '$label is required.',
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

Future<T?> _showSearchPicker<T>(
  BuildContext context, {
  required String title,
  required List<T> items,
  required String Function(T) label,
  required String? Function(T) detail,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (context) => _SearchPicker<T>(
    title: title,
    items: items,
    label: label,
    detail: detail,
  ),
);

class _SearchPicker<T> extends StatefulWidget {
  const _SearchPicker({
    required this.title,
    required this.items,
    required this.label,
    required this.detail,
  });

  final String title;
  final List<T> items;
  final String Function(T) label;
  final String? Function(T) detail;

  @override
  State<_SearchPicker<T>> createState() => _SearchPickerState<T>();
}

class _SearchPickerState<T> extends State<_SearchPicker<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final needle = _query.trim().toLowerCase();
    final filtered = widget.items.where((item) {
      final haystack = '${widget.label(item)} ${widget.detail(item) ?? ''}'
          .toLowerCase();
      return needle.isEmpty || haystack.contains(needle);
    }).toList();
    return FractionallySizedBox(
      heightFactor: .86,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 14),
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Type to search',
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No matching options'))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return ListTile(
                          title: Text(widget.label(item)),
                          subtitle: widget.detail(item) == null
                              ? null
                              : Text(widget.detail(item)!),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.pop(context, item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
