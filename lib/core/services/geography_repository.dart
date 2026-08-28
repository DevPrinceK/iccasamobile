import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const geographyValueKey = '__geography';
const geographyCountryErrorKey = '__geography_country';
const geographyAreaErrorKey = '__geography_area';

class GeographyCountry {
  const GeographyCountry({
    required this.code,
    required this.name,
    required this.areaLabel,
  });

  final String code;
  final String name;
  final String areaLabel;

  factory GeographyCountry.fromJson(Map<String, dynamic> json) =>
      GeographyCountry(
        code: json['code']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        areaLabel: json['area_label']?.toString() ?? 'District / county',
      );
}

class GeographyArea {
  const GeographyArea({
    required this.code,
    required this.name,
    this.parentName,
    this.isCustom = false,
  });

  final String code;
  final String name;
  final String? parentName;
  final bool isCustom;

  factory GeographyArea.fromJson(Map<String, dynamic> json) => GeographyArea(
    code: json['code']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    parentName: json['parent_name']?.toString(),
    isCustom: json['is_custom'] == true,
  );
}

class GeographyRepository {
  GeographyRepository._();

  static final instance = GeographyRepository._();
  Future<Map<String, dynamic>>? _dataset;

  Future<Map<String, dynamic>> _load() => _dataset ??= rootBundle
      .loadString('assets/data/geography.json')
      .then((source) => compute(_decodeGeography, source));

  Future<List<GeographyCountry>> countries() async {
    final data = await _load();
    return (data['countries'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => GeographyCountry.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<List<GeographyArea>> areasFor(String countryCode) async {
    final data = await _load();
    final areaMap = data['areas'] is Map
        ? Map<String, dynamic>.from(data['areas'] as Map)
        : const <String, dynamic>{};
    final items = (areaMap[countryCode] as List? ?? const [])
        .whereType<Map>()
        .map((item) => GeographyArea.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    if (items.isEmpty) {
      return [
        GeographyArea(
          code: '$countryCode.NATIONAL',
          name: 'National / not applicable',
        ),
      ];
    }
    return [
      ...items,
      GeographyArea(
        code: '$countryCode.OTHER',
        name: 'Other / not listed',
        isCustom: true,
      ),
    ];
  }
}

Map<String, dynamic> _decodeGeography(String source) =>
    Map<String, dynamic>.from(jsonDecode(source) as Map);

Map<String, dynamic> geographyFromValues(Map<String, dynamic> values) {
  final raw = values[geographyValueKey];
  return raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
}

Map<String, dynamic> submissionDataFromValues(Map<String, dynamic> values) =>
    Map<String, dynamic>.from(values)..remove(geographyValueKey);

bool geographyIsComplete(Map<String, dynamic> value) =>
    (value['country_code']?.toString().isNotEmpty ?? false) &&
    (value['administrative_area_code']?.toString().isNotEmpty ?? false) &&
    (!value['administrative_area_code'].toString().endsWith('.OTHER') ||
        (value['administrative_area_name']?.toString().trim().length ?? 0) >=
            2);
