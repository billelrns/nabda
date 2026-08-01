import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/medical_facility_model.dart';

class MedicalDirectoryService {
  static final MedicalDirectoryService _instance = MedicalDirectoryService._internal();
  factory MedicalDirectoryService() => _instance;
  MedicalDirectoryService._internal();

  bool _initialized = false;
  List<MedicalFacility> _facilities = [];
  List<WilayaCentroid> _centroids = [];

  bool get isInitialized => _initialized;

  /// Loads the medical facility and wilaya centroid databases from JSON assets.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 1. Load medical facilities
      final String facilitiesRaw = await rootBundle.loadString('assets/data/arab_world_doctors.json');
      final List<dynamic> facilitiesJson = json.decode(facilitiesRaw);
      _facilities = facilitiesJson.map((json) => MedicalFacility.fromJson(json)).toList();

      // 2. Load wilaya centroids
      final String centroidsRaw = await rootBundle.loadString('assets/data/algeria_wilaya_centroids.json');
      final List<dynamic> centroidsJson = json.decode(centroidsRaw);
      _centroids = centroidsJson.map((json) => WilayaCentroid.fromJson(json)).toList();

      _initialized = true;
    } catch (e) {
      // Keep lists empty if loading fails
      _initialized = false;
      rethrow;
    }
  }

  /// Retrieve all medical facilities.
  List<MedicalFacility> getAll() => _facilities;

  /// Retrieve all wilaya centroids.
  List<WilayaCentroid> getCentroids() => _centroids;

  /// Retrieve the centroid coordinates for a specific wilaya by ID.
  WilayaCentroid? getCentroidFor(int wilayaId) {
    try {
      return _centroids.firstWhere((c) => c.id == wilayaId);
    } catch (_) {
      return null;
    }
  }

  /// Search and filter medical facilities.
  ///
  /// Filters:
  /// - [query]: search in Arabic/French names, address, or city.
  /// - [wilayaId]: filter by Wilaya ID (1 to 69).
  /// - [type]: filter by type ('gynaecologist', 'clinic', 'hospital', 'doctor').
  /// - [isPublic]: filter public (true) or private (false).
  List<MedicalFacility> search({
    String? query,
    int? wilayaId,
    String? type,
    bool? isPublic,
  }) {
    List<MedicalFacility> results = _facilities;

    // Filter by Wilaya
    if (wilayaId != null && wilayaId > 0) {
      results = results.where((f) => f.wilayaId == wilayaId).toList();
    }

    // Filter by Type
    if (type != null && type.isNotEmpty && type != 'all') {
      results = results.where((f) => f.type == type).toList();
    }

    // Filter by Public/Private
    if (isPublic != null) {
      results = results.where((f) => f.isPublic == isPublic).toList();
    }

    // Filter by Query text search
    if (query != null && query.trim().isNotEmpty) {
      final cleanQuery = query.trim().toLowerCase();
      results = results.where((f) {
        final nameAr = f.nameAr.toLowerCase();
        final nameFr = f.nameFr.toLowerCase();
        final address = f.address.toLowerCase();
        final city = f.city.toLowerCase();
        final typeDesc = f.typeDescAr.toLowerCase();
        final phone = f.phone;

        return nameAr.contains(cleanQuery) ||
               nameFr.contains(cleanQuery) ||
               address.contains(cleanQuery) ||
               city.contains(cleanQuery) ||
               typeDesc.contains(cleanQuery) ||
               phone.contains(cleanQuery);
      }).toList();
    }

    return results;
  }
}
