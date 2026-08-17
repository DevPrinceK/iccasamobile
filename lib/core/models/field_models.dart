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
  });

  final int id;
  final int? organizationId;
  final String name;
  final String email;
  final String role;
  final String? phone;

  bool get canReview => role != 'field_agent';
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
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'organization_id': organizationId,
    'name': name,
    'email': email,
    'role': role,
    'phone': phone,
  };
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

  List<String> get options => (config['options'] as List? ?? const [])
      .map((value) => value.toString())
      .where((value) => value.isNotEmpty)
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

  int get fieldCount => version?.fields.length ?? 0;
  int get requiredCount =>
      version?.fields.where((field) => field.required).length ?? 0;
  bool get isReady => isActive && version != null && version!.isPublished;

  factory FieldAssignment.fromJson(Map<String, dynamic> json) {
    final current = json['current_version'];
    return FieldAssignment(
      id: _asInt(json['id']),
      projectId: _asNullableInt(json['project_id']),
      indicatorId: _asNullableInt(json['indicator_id']),
      name: json['name']?.toString() ?? 'Collection form',
      description:
          json['description']?.toString() ?? 'No description provided.',
      isActive: json['is_active'] != false,
      version: current is Map
          ? FormVersion.fromJson(Map<String, dynamic>.from(current))
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

  factory SubmissionRecord.fromJson(Map<String, dynamic> json) =>
      SubmissionRecord(
        id: json['id']?.toString() ?? '',
        formId: _asInt(json['form_id']),
        formVersionId: _asInt(json['form_version_id']),
        status: json['status']?.toString() ?? 'pending_review',
        data: _asMap(json['data']),
        createdAt:
            DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
        reviewNote: json['review_note']?.toString(),
        localState: _recordState(json['local_state']?.toString()),
        formName: json['form_name']?.toString(),
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
  final decoded = jsonDecode(source);
  if (decoded is! List) return const [];
  return decoded
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}
