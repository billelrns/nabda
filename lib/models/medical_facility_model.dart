class MedicalFacility {
  final String id;
  final String nameAr;
  final String nameFr;
  final double lat;
  final double lon;
  final String phone;
  final String address;
  final String city;
  final int wilayaId;
  final String wilayaNameAr;
  final String wilayaNameFr;
  final String type; // 'gynaecologist', 'pediatrician', 'maternity_hospital', 'clinic', 'hospital', 'doctor'
  final String specialtyGroup; // 'gyn', 'pedia', 'maternity', 'general'
  final String typeDescAr;
  final bool isPublic;
  final String website;

  MedicalFacility({
    required this.id,
    required this.nameAr,
    required this.nameFr,
    required this.lat,
    required this.lon,
    required this.phone,
    required this.address,
    required this.city,
    required this.wilayaId,
    required this.wilayaNameAr,
    required this.wilayaNameFr,
    required this.type,
    required this.specialtyGroup,
    required this.typeDescAr,
    required this.isPublic,
    required this.website,
  });

  bool get isGynaecology => specialtyGroup == 'gyn' || type == 'gynaecologist';
  bool get isPediatrics => specialtyGroup == 'pedia' || type == 'pediatrician';
  bool get isMaternity => specialtyGroup == 'maternity' || type == 'maternity_hospital';

  factory MedicalFacility.fromJson(Map<String, dynamic> json) {
    final typeVal = json['type'] ?? 'unknown';
    String groupVal = json['specialty_group'] ?? '';
    if (groupVal.isEmpty) {
      if (typeVal == 'gynaecologist') groupVal = 'gyn';
      else if (typeVal == 'pediatrician') groupVal = 'pedia';
      else if (typeVal == 'maternity_hospital') groupVal = 'maternity';
      else groupVal = 'general';
    }

    return MedicalFacility(
      id: json['id'] ?? '',
      nameAr: json['name_ar'] ?? '',
      nameFr: json['name_fr'] ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
      phone: json['phone'] ?? 'غير متوفر',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      wilayaId: (json['wilaya_id'] as num?)?.toInt() ?? 0,
      wilayaNameAr: json['wilaya_name_ar'] ?? '',
      wilayaNameFr: json['wilaya_name_fr'] ?? '',
      type: typeVal,
      specialtyGroup: groupVal,
      typeDescAr: json['type_desc_ar'] ?? 'طبيب / عيادة',
      isPublic: json['is_public'] ?? false,
      website: json['website'] ?? 'غير متوفر',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_ar': nameAr,
      'name_fr': nameFr,
      'lat': lat,
      'lon': lon,
      'phone': phone,
      'address': address,
      'city': city,
      'wilaya_id': wilayaId,
      'wilaya_name_ar': wilayaNameAr,
      'wilaya_name_fr': wilayaNameFr,
      'type': type,
      'specialty_group': specialtyGroup,
      'type_desc_ar': typeDescAr,
      'is_public': isPublic,
      'website': website,
    };
  }
}

class WilayaCentroid {
  final int id;
  final String nameAr;
  final String nameFr;
  final double lat;
  final double lon;

  WilayaCentroid({
    required this.id,
    required this.nameAr,
    required this.nameFr,
    required this.lat,
    required this.lon,
  });

  factory WilayaCentroid.fromJson(Map<String, dynamic> json) {
    return WilayaCentroid(
      id: json['wilaya_id'] ?? 0,
      nameAr: json['wilaya_name_ar'] ?? '',
      nameFr: json['wilaya_name_fr'] ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 36.75,
      lon: (json['lon'] as num?)?.toDouble() ?? 3.05,
    );
  }
}
