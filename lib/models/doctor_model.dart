class DoctorModel {
  final String id;
  final String name;
  final String specialty;
  final double rating;
  final int reviewCount;
  final String phone;
  final String email;
  final String address;
  final List<String> availability; // Time slots
  final String? image;
  final String? bio;
  final bool isVerified;

  DoctorModel({
    required this.id,
    required this.name,
    required this.specialty,
    this.rating = 4.5,
    this.reviewCount = 0,
    required this.phone,
    required this.email,
    required this.address,
    this.availability = const [],
    this.image,
    this.bio,
    this.isVerified = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'rating': rating,
      'reviewCount': reviewCount,
      'phone': phone,
      'email': email,
      'address': address,
      'availability': availability,
      'image': image,
      'bio': bio,
      'isVerified': isVerified,
    };
  }

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      specialty: json['specialty'] ?? '',
      rating: (json['rating'] ?? 4.5).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      availability: List<String>.from(json['availability'] ?? []),
      image: json['image'],
      bio: json['bio'],
      isVerified: json['isVerified'] ?? false,
    );
  }
}






