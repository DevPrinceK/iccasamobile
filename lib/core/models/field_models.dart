import 'dart:convert';

enum AppStage { booting, signedOut, signedIn }

enum LocalRecordState { draft, queued, syncing, synced, failed }

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.organizationId,
    this.phone,
    this.avatarUrl,
  });

  final int id;
  final int? organizationId;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? avatarUrl;

  bool get canReview =>
      const {'platform_admin', 'organization_admin', 'manager'}.contains(role);
  String get firstName => name.trim().split(RegExp(r'\s+')).firstOrNull ?? name;
  String get roleLabel => role
      .split('_')
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: _asInt(json['id']),
    organizationId: _asNullableInt(json['organization_id']),
    name: json['name']?.toString() ?? 'ICCASA user',
    email: json['email']?.toString() ?? '',
    role: json['role']?.toString() ?? 'field_agent',
    phone: json['phone']?.toString(),
    avatarUrl: json['avatar_url']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'organization_id': organizationId,
    'name': name,
    'email': email,
    'role': role,
    'phone': phone,
    'avatar_url': avatarUrl,
  };
}

class FieldOption {
  const FieldOption({required this.value, required this.label});

  final String value;
  final String label;

  factory FieldOption.fromJson(Object? json) {
    if (json is Map) {
      final value = json['value'] ?? json['label'];
      final label = json['label'] ?? json['value'];
      return FieldOption(
        value: value?.toString() ?? '',
        label: label?.toString() ?? '',
      );
    }
    final value = json?.toString() ?? '';
    return FieldOption(value: value, label: value);
  }
}

class FieldDefinition {
  const FieldDefinition({
    required this.id,
    required this.key,
    required this.label,
    required this.type,
    required this.order,
    required this.required,
    required this.config,
  });

  final int id;
  final String key;
  final String label;
  final String type;
  final int order;
  final bool required;
  final Map<String, dynamic> config;

  List<FieldOption> get options => (config['options'] as List? ?? const [])
      .map(FieldOption.fromJson)
      .where((option) => option.value.isNotEmpty)
      .toList();

  String get normalizedType => type.trim().toLowerCase().replaceAll('_', ' ');

  factory FieldDefinition.fromJson(Map<String, dynamic> json) =>
      FieldDefinition(
        id: _asInt(json['id']),
        key: json['key']?.toString() ?? '',
        label: json['label']?.toString() ?? 'Untitled field',
        type: (json['field_type'] ?? json['type'] ?? 'Text').toString(),
        order: _asInt(json['order']),
        required: json['required'] == true,
        config: _asMap(json['config']),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'key': key,
    'label': label,
    'field_type': type,
    'order': order,
    'required': required,
    'config': config,
  };
}

class FormVersion {
  const FormVersion({
    required this.id,
    required this.version,
    required this.isPublished,
    required this.schema,
    required this.fields,
  });

  final int id;
  final int version;
  final bool isPublished;
  final Map<String, dynamic> schema;
  final List<FieldDefinition> fields;

  String get instructions =>
      schema['instructions']?.toString() ??
      'Complete each field carefully and verify the information before submission.';

  factory FormVersion.fromJson(Map<String, dynamic> json) {
    final schema = _asMap(json['schema']);
    final rawFields =
        (json['fields'] as List?) ?? (schema['fields'] as List?) ?? const [];
    final fields =
        rawFields
            .whereType<Map>()
            .map(
              (item) =>
                  FieldDefinition.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    return FormVersion(
      id: _asInt(json['id']),
      version: _asInt(json['version']),
      isPublished: json['is_published'] == true,
      schema: schema,
      fields: fields,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'version': version,
    'is_published': isPublished,
    'schema': schema,
    'fields': fields.map((field) => field.toJson()).toList(),
  };
}

class FieldAssignment {
  const FieldAssignment({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    required this.version,
    this.projectId,
    this.indicatorId,
  });

  final int id;
  final int? projectId;
  final int? indicatorId;
  final String name;
  final String description;
  final bool isActive;
  final FormVersion? version;

  int get fieldCount => version == null ? 0 : version!.fields.length + 4;
  int get requiredCount => version == null
      ? 0
      : version!.fields.where((field) => field.required).length + 3;
  bool get isReady => isActive && version != null && version!.isPublished;

  factory FieldAssignment.fromJson(Map<String, dynamic> json) {
    final rawVersions = (json['versions'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final published = rawVersions
        .where((item) => item['is_published'] == true)
        .firstOrNull;
    final current = json['current_version'];
    final selectedVersion = current is Map && current['is_published'] == true
        ? current
        : published ?? (current is Map ? current : null);
    return FieldAssignment(
      id: _asInt(json['id']),
      projectId: _asNullableInt(json['project_id']),
      indicatorId: _asNullableInt(json['indicator_id']),
      name: json['name']?.toString() ?? 'Collection form',
      description:
          json['description']?.toString() ?? 'No description provided.',
      isActive: json['is_active'] != false,
      version: selectedVersion is Map
          ? FormVersion.fromJson(Map<String, dynamic>.from(selectedVersion))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'project_id': projectId,
    'indicator_id': indicatorId,
    'name': name,
    'description': description,
    'is_active': isActive,
    'current_version': version?.toJson(),
  };
}

class DraftRecord {
  DraftRecord({
    required this.id,
    required this.formId,
    required this.formVersionId,
    required this.formName,
    required this.values,
    required this.updatedAt,
    this.startedAt,
  });

  final String id;
  final int formId;
  final int formVersionId;
  final String formName;
  final Map<String, dynamic> values;
  final DateTime updatedAt;
  final DateTime? startedAt;

  factory DraftRecord.fromJson(Map<String, dynamic> json) => DraftRecord(
    id: json['id']?.toString() ?? '',
    formId: _asInt(json['form_id']),
    formVersionId: _asInt(json['form_version_id']),
    formName: json['form_name']?.toString() ?? 'Collection form',
    values: _asMap(json['values']),
    updatedAt:
        DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
        DateTime.now(),
    startedAt: DateTime.tryParse(json['started_at']?.toString() ?? ''),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'form_id': formId,
    'form_version_id': formVersionId,
    'form_name': formName,
    'values': values,
    'updated_at': updatedAt.toIso8601String(),
    'started_at': startedAt?.toIso8601String(),
  };
}

class SubmissionRecord {
  const SubmissionRecord({
    required this.id,
    required this.formId,
    required this.formVersionId,
    required this.status,
    required this.data,
    required this.createdAt,
    this.reviewNote,
    this.localState = LocalRecordState.synced,
    this.formName,
    this.submittedByName,
    this.submittedByEmail,
    this.source = 'field',
    this.countryCode,
    this.countryName,
    this.administrativeAreaCode,
    this.administrativeAreaName,
    this.administrativeAreaType,
    this.disabilityStatus,
    this.disabilityTypes = const [],
    this.otherDisabilityType,
  });

  final String id;
  final int formId;
  final int formVersionId;
  final String status;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final String? reviewNote;
  final LocalRecordState localState;
  final String? formName;
  final String? submittedByName;
  final String? submittedByEmail;
  final String source;
  final String? countryCode;
  final String? countryName;
  final String? administrativeAreaCode;
  final String? administrativeAreaName;
  final String? administrativeAreaType;
  final String? disabilityStatus;
  final List<String> disabilityTypes;
  final String? otherDisabilityType;

  bool get isAwaitingReview => status == 'queued' || status == 'pending_review';

  factory SubmissionRecord.fromJson(Map<String, dynamic> json) =>
      SubmissionRecord(
        id: json['id']?.toString() ?? '',
        formId: _asInt(json['form_id']),
        formVersionId: _asInt(json['form_version_id']),
        status: json['status']?.toString() ?? 'queued',
        data: _asMap(json['data']),
        createdAt:
            DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
        reviewNote: json['review_note']?.toString(),
        localState: _recordState(json['local_state']?.toString()),
        formName: json['form_name']?.toString(),
        submittedByName: json['submitted_by_name']?.toString(),
        submittedByEmail: json['submitted_by_email']?.toString(),
        source: json['source']?.toString() ?? 'field',
        countryCode: json['country_code']?.toString(),
        countryName: json['country_name']?.toString(),
        administrativeAreaCode: json['administrative_area_code']?.toString(),
        administrativeAreaName: json['administrative_area_name']?.toString(),
        administrativeAreaType: json['administrative_area_type']?.toString(),
        disabilityStatus: json['disability_status']?.toString(),
        disabilityTypes: (json['disability_types'] as List? ?? const [])
            .map((item) => item.toString())
            .toList(),
        otherDisabilityType: json['other_disability_type']?.toString(),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'form_id': formId,
    'form_version_id': formVersionId,
    'status': status,
    'data': data,
    'created_at': createdAt.toIso8601String(),
    'review_note': reviewNote,
    'local_state': localState.name,
    'form_name': formName,
    'submitted_by_name': submittedByName,
    'submitted_by_email': submittedByEmail,
    'source': source,
    'country_code': countryCode,
    'country_name': countryName,
    'administrative_area_code': administrativeAreaCode,
    'administrative_area_name': administrativeAreaName,
    'administrative_area_type': administrativeAreaType,
    'disability_status': disabilityStatus,
    'disability_types': disabilityTypes,
    'other_disability_type': otherDisabilityType,
  };
}

class OutboxItem {
  const OutboxItem({
    required this.id,
    required this.formId,
    required this.formVersionId,
    required this.formName,
    required this.data,
    required this.createdAt,
    this.attempts = 0,
    this.lastError,
  });

  final String id;
  final int formId;
  final int formVersionId;
  final String formName;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int attempts;
  final String? lastError;

  OutboxItem copyWith({int? attempts, String? lastError}) => OutboxItem(
    id: id,
    formId: formId,
    formVersionId: formVersionId,
    formName: formName,
    data: data,
    createdAt: createdAt,
    attempts: attempts ?? this.attempts,
    lastError: lastError,
  );

  factory OutboxItem.fromJson(Map<String, dynamic> json) => OutboxItem(
    id: json['id']?.toString() ?? '',
    formId: _asInt(json['form_id']),
    formVersionId: _asInt(json['form_version_id']),
    formName: json['form_name']?.toString() ?? 'Collection form',
    data: _asMap(json['data']),
    createdAt:
        DateTime.tryParse(json['created_at']?.toString() ?? '') ??
        DateTime.now(),
    attempts: _asInt(json['attempts']),
    lastError: json['last_error']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'form_id': formId,
    'form_version_id': formVersionId,
    'form_name': formName,
    'data': data,
    'created_at': createdAt.toIso8601String(),
    'attempts': attempts,
    'last_error': lastError,
  };
}

Map<String, dynamic> _asMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

int _asInt(Object? value) => int.tryParse(value?.toString() ?? '') ?? 0;
int? _asNullableInt(Object? value) =>
    value == null ? null : int.tryParse(value.toString());

LocalRecordState _recordState(String? value) =>
    LocalRecordState.values.firstWhere(
      (state) => state.name == value,
      orElse: () => LocalRecordState.synced,
    );

String encodeJsonList<T>(
  Iterable<T> items,
  Map<String, dynamic> Function(T) encode,
) => jsonEncode(items.map(encode).toList());

List<Map<String, dynamic>> decodeJsonList(String? source) {
  if (source == null || source.isEmpty) return const [];
  try {
    final decoded = jsonDecode(source);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  } on FormatException {
    return const [];
  }
}

bool isResponseEmpty(Object? value) {
  if (value == null) return true;
  if (value is String) return value.trim().isEmpty;
  if (value is Map) return value.isEmpty;
  if (value is Iterable) return value.isEmpty;
  return false;
}
