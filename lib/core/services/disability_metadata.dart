const disabilityValueKey = '__disability';
const disabilityStatusErrorKey = '__disability_status';
const disabilityTypesErrorKey = '__disability_types';
const disabilityOtherTypeErrorKey = '__disability_other_type';

const selfIdentifiedDisability = 'self-identified disability';
const otherDisabilityType = 'other';

class DisabilityOption {
  const DisabilityOption(this.value, this.label);

  final String value;
  final String label;
}

const disabilityStatusOptions = <DisabilityOption>[
  DisabilityOption('none', 'No disability'),
  DisabilityOption(selfIdentifiedDisability, 'Self-identified disability'),
  DisabilityOption('prefer not to say', 'Prefer not to say'),
  DisabilityOption('not assessed', 'Not assessed'),
];

const disabilityTypeOptions = <DisabilityOption>[
  DisabilityOption('physical_mobility', 'Physical / mobility'),
  DisabilityOption('visual', 'Visual'),
  DisabilityOption('hearing', 'Hearing'),
  DisabilityOption('speech_communication', 'Speech / communication'),
  DisabilityOption(
    'intellectual_developmental',
    'Intellectual / developmental',
  ),
  DisabilityOption(
    'psychosocial_mental_health',
    'Psychosocial / mental health',
  ),
  DisabilityOption('learning', 'Learning'),
  DisabilityOption(otherDisabilityType, 'Other'),
];

Map<String, dynamic> disabilityFromValues(Map<String, dynamic> values) {
  final raw = values[disabilityValueKey];
  return raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
}

bool disabilityIsComplete(Map<String, dynamic> value) {
  final status = value['status']?.toString() ?? '';
  if (!disabilityStatusOptions.any((item) => item.value == status)) {
    return false;
  }
  if (status != selfIdentifiedDisability) return true;
  final types = (value['types'] as List? ?? const [])
      .map((item) => item.toString())
      .toList();
  if (types.isEmpty) return false;
  return !types.contains(otherDisabilityType) ||
      (value['other_type']?.toString().trim().length ?? 0) >= 2;
}

String disabilityStatusLabel(String? value) =>
    disabilityStatusOptions
        .where((item) => item.value == value)
        .map((item) => item.label)
        .firstOrNull ??
    'Not provided';

List<String> disabilityTypeLabels(Map<String, dynamic> value) {
  if (value['status'] != selfIdentifiedDisability) {
    return const ['Not applicable'];
  }
  final types = (value['types'] as List? ?? const [])
      .map((item) => item.toString())
      .toList();
  return types.map((type) {
    if (type == otherDisabilityType &&
        (value['other_type']?.toString().trim().isNotEmpty ?? false)) {
      return 'Other: ${value['other_type'].toString().trim()}';
    }
    return disabilityTypeOptions
            .where((item) => item.value == type)
            .map((item) => item.label)
            .firstOrNull ??
        type;
  }).toList();
}
