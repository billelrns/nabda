import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import '../../models/medical_facility_model.dart';
import '../../services/medical_directory_service.dart';

class ArabCountry {
  final int code;
  final String nameAr;
  final String nameEn;
  final String flag;
  final double lat;
  final double lon;
  final double zoom;

  const ArabCountry({
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.flag,
    required this.lat,
    required this.lon,
    required this.zoom,
  });
}

const List<ArabCountry> arabCountries = [
  ArabCountry(code: 0, nameAr: "الجزائر", nameEn: "Algeria", flag: "🇩🇿", lat: 28.0, lon: 3.0, zoom: 5.5),
  ArabCountry(code: 100, nameAr: "مصر", nameEn: "Egypt", flag: "🇪🇬", lat: 26.8206, lon: 30.8025, zoom: 6.0),
  ArabCountry(code: 101, nameAr: "السعودية", nameEn: "Saudi Arabia", flag: "🇸🇦", lat: 23.8859, lon: 45.0792, zoom: 5.5),
  ArabCountry(code: 102, nameAr: "المغرب", nameEn: "Morocco", flag: "🇲🇦", lat: 31.7917, lon: -7.0926, zoom: 6.0),
  ArabCountry(code: 103, nameAr: "تونس", nameEn: "Tunisia", flag: "🇹🇳", lat: 33.8869, lon: 9.5375, zoom: 6.5),
  ArabCountry(code: 104, nameAr: "ليبيا", nameEn: "Libya", flag: "🇱🇾", lat: 26.3351, lon: 17.2283, zoom: 6.0),
  ArabCountry(code: 105, nameAr: "السودان", nameEn: "Sudan", flag: "🇸🇩", lat: 12.8628, lon: 30.2176, zoom: 5.5),
  ArabCountry(code: 106, nameAr: "سوريا", nameEn: "Syria", flag: "🇸🇾", lat: 34.8021, lon: 38.9968, zoom: 7.0),
  ArabCountry(code: 107, nameAr: "العراق", nameEn: "Iraq", flag: "🇮🇶", lat: 33.2232, lon: 43.6793, zoom: 6.5),
  ArabCountry(code: 108, nameAr: "الأردن", nameEn: "Jordan", flag: "🇯🇴", lat: 31.2401, lon: 36.5106, zoom: 7.5),
  ArabCountry(code: 109, nameAr: "لبنان", nameEn: "Lebanon", flag: "🇱🇧", lat: 33.8547, lon: 35.8623, zoom: 9.0),
  ArabCountry(code: 110, nameAr: "فلسطين", nameEn: "Palestine", flag: "🇵🇸", lat: 31.9522, lon: 35.2332, zoom: 8.5),
  ArabCountry(code: 111, nameAr: "اليمن", nameEn: "Yemen", flag: "🇾🇪", lat: 15.5527, lon: 48.5164, zoom: 6.0),
  ArabCountry(code: 112, nameAr: "عمان", nameEn: "Oman", flag: "🇴🇲", lat: 21.4735, lon: 55.9754, zoom: 6.0),
  ArabCountry(code: 113, nameAr: "الإمارات", nameEn: "United Arab Emirates", flag: "🇦🇪", lat: 23.4241, lon: 53.8478, zoom: 7.0),
  ArabCountry(code: 114, nameAr: "الكويت", nameEn: "Kuwait", flag: "🇰🇼", lat: 29.3117, lon: 47.4818, zoom: 9.5),
  ArabCountry(code: 115, nameAr: "قطر", nameEn: "Qatar", flag: "🇶🇦", lat: 25.3548, lon: 51.1839, zoom: 9.0),
  ArabCountry(code: 116, nameAr: "البحرين", nameEn: "Bahrain", flag: "🇧🇭", lat: 26.0667, lon: 50.5500, zoom: 10.0),
  ArabCountry(code: 117, nameAr: "موريتانيا", nameEn: "Mauritania", flag: "🇲🇷", lat: 21.0079, lon: -10.9408, zoom: 5.5),
];

class DoctorsListScreen extends StatefulWidget {
  const DoctorsListScreen({Key? key}) : super(key: key);

  @override
  State<DoctorsListScreen> createState() => _DoctorsListScreenState();
}

class _DoctorsListScreenState extends State<DoctorsListScreen> with SingleTickerProviderStateMixin {
  final MedicalDirectoryService _directoryService = MedicalDirectoryService();
  late TabController _tabController;
  final MapController _mapController = MapController();

  bool _isLoading = true;
  bool _isLocating = false; // Location loading indicator
  String _searchQuery = '';
  int _selectedCountryCode = 0; // 0 = Algeria
  int _selectedWilayaId = 0; // 0 means All Algeria wilayas
  String _selectedCity = ''; // Filter by city for other Arab countries
  LatLng? _userLocation; // User's custom geolocation
  
  // Filters for Map & List
  bool _showGyn = true;
  bool _showPedia = true;
  bool _showMaternity = true;
  bool _showClinics = false;
  bool _showHospitals = false;

  List<MedicalFacility> _allFacilities = [];
  List<WilayaCentroid> _wilayas = [];
  List<MedicalFacility> _filteredFacilities = [];
  
  // Currently selected facility for map popup detail
  MedicalFacility? _selectedFacility;

  List<String> getSelectedCountryCities() {
    if (_selectedCountryCode == 0) return [];
    final cities = _allFacilities
        .where((f) => f.wilayaId == _selectedCountryCode)
        .map((f) => f.city.trim())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    cities.sort();
    return cities;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    
    // Listen to tab changes to clear popup if switching tabs
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedFacility = null;
        });
      }
    });
  }

  Future<void> _loadData() async {
    try {
      await _directoryService.initialize();
      setState(() {
        _allFacilities = _directoryService.getAll();
        _wilayas = _directoryService.getCentroids();
        // Sort wilayas alphabetically by Arabic name
        _wilayas.sort((a, b) => a.nameAr.compareTo(b.nameAr));
        _updateFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحميل قاعدة البيانات: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Haversine formula to compute distance in km between two coords
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // pi / 180
    final a = 0.5 - math.cos((lat2 - lat1) * p) / 2 +
              math.cos(lat1 * p) * math.cos(lat2 * p) *
              (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
  }

  // Request browser/device geolocation and filter closest
  Future<void> _getUserLocation() async {
    setState(() {
      _isLocating = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'خدمات الموقع الجغرافي (GPS) معطلة على هذا الجهاز. يرجى تفعيلها.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'تم رفض الوصول لصلاحية الموقع الجغرافي.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'تم رفض الوصول لصلاحية الموقع الجغرافي بشكل دائم من إعدادات المتصفح/الجهاز.';
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _isLocating = false;
        
        // When user location is found, enable all categories by default to allow proximity search of everything
        _showGyn = true;
        _showPedia = true;
        _showMaternity = true;
        _showClinics = true;
        
        _updateFilters();
        
        // Pushes map camera directly to the user if map is active
        if (_tabController.index == 1) {
          _mapController.move(_userLocation!, 12.5);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديد موقعكِ بنجاح! تم ترتيب العيادات والأطباء من الأقرب إليكِ.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLocating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.orange.shade800,
        ),
      );
    }
  }

  void _updateFilters() {
    final bool isMapView = _tabController.index == 1;
    
    // Determine what specialty groups/types to show
    List<String> activeGroups = [];
    if (_showGyn) activeGroups.add('gyn');
    if (_showPedia) activeGroups.add('pedia');
    if (_showMaternity) activeGroups.add('maternity');
    if (_showClinics) activeGroups.add('general');
    if (_showHospitals) activeGroups.add('general');
    
    // If all are toggled off, show nothing
    if (activeGroups.isEmpty) {
      setState(() {
        _filteredFacilities = [];
      });
      return;
    }

    List<MedicalFacility> results = _allFacilities;

    // Filter by Country / Region / City (If user hasn't gotten location sorted)
    if (_userLocation == null) {
      if (_selectedCountryCode == 0) {
        // Algeria: wilayaId must be within 1-69 (Algerian wilayas)
        results = results.where((f) => f.wilayaId <= 69).toList();
        if (_selectedWilayaId > 0) {
          results = results.where((f) => f.wilayaId == _selectedWilayaId).toList();
        }
      } else {
        // Other Arab Countries: wilayaId must match the country code!
        results = results.where((f) => f.wilayaId == _selectedCountryCode).toList();
        if (_selectedCity.isNotEmpty) {
          results = results.where((f) => f.city == _selectedCity).toList();
        }
      }
    }

    // Filter by Group / Specialty
    results = results.where((f) => activeGroups.contains(f.specialtyGroup)).toList();

    // Filter by Text Search
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      results = results.where((f) {
        return f.nameAr.toLowerCase().contains(q) ||
               f.nameFr.toLowerCase().contains(q) ||
               f.address.toLowerCase().contains(q) ||
               f.city.toLowerCase().contains(q);
      }).toList();
    }

    // Primary Sort: Prioritize entries with valid phone numbers & specialists first
    results.sort((a, b) {
      if (_userLocation != null) {
        final distA = _calculateDistance(_userLocation!.latitude, _userLocation!.longitude, a.lat, a.lon);
        final distB = _calculateDistance(_userLocation!.latitude, _userLocation!.longitude, b.lat, b.lon);
        return distA.compareTo(distB);
      }
      
      // 1. Phone availability (has phone comes first)
      final bool hasPhoneA = a.phone.isNotEmpty && a.phone != 'غير متوفر';
      final bool hasPhoneB = b.phone.isNotEmpty && b.phone != 'غير متوفر';
      if (hasPhoneA != hasPhoneB) {
        return hasPhoneA ? -1 : 1;
      }
      
      // 2. Specialty priority (OB/GYN, Pediatrics & Maternity before general)
      final bool isSpecialistA = a.specialtyGroup != 'general';
      final bool isSpecialistB = b.specialtyGroup != 'general';
      if (isSpecialistA != isSpecialistB) {
        return isSpecialistA ? -1 : 1;
      }
      
      return a.nameAr.compareTo(b.nameAr);
    });

    setState(() {
      _filteredFacilities = results;
    });
  }

  // Focus map camera on the selected country
  void _zoomToCountry(int countryCode) {
    try {
      final country = arabCountries.firstWhere((c) => c.code == countryCode);
      setState(() {
        _userLocation = null;
      });
      _mapController.move(LatLng(country.lat, country.lon), country.zoom);
    } catch (_) {}
  }

  // Focus map camera on the average location of the selected City
  void _zoomToCity(String cityName) {
    final cityFacilities = _filteredFacilities.where((f) => f.city == cityName).toList();
    if (cityFacilities.isNotEmpty) {
      final avgLat = cityFacilities.map((f) => f.lat).reduce((a, b) => a + b) / cityFacilities.length;
      final avgLon = cityFacilities.map((f) => f.lon).reduce((a, b) => a + b) / cityFacilities.length;
      _mapController.move(LatLng(avgLat, avgLon), 11.5);
    }
  }

  // Focus map camera on the selected Wilaya
  void _zoomToWilaya(int wilayaId) {
    if (wilayaId == 0) {
      _mapController.move(LatLng(28.0, 3.0), 5.5);
      return;
    }
    
    final centroid = _directoryService.getCentroidFor(wilayaId);
    if (centroid != null) {
      // Clear user location to prevent filters conflicting when checking wilaya specifically
      setState(() {
        _userLocation = null;
      });
      _mapController.move(LatLng(centroid.lat, centroid.lon), 11.0);
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber == 'غير متوفر') return;
    
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+|-'), '');
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanPhone,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Could not launch $launchUri';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إجراء المكالمة: $e')),
      );
    }
  }

  Future<void> _openInGoogleMaps(double lat, double lon) async {
    final Uri googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $googleMapsUrl';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر فتح الخرائط: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF00897B);
    const accentPink = Color(0xFFE91E63);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'دليل أطباء وعيادات النساء بالوطن العربي',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: primaryTeal,
            labelColor: primaryTeal,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(icon: Icon(Icons.list), text: 'قائمة الأطباء والأقرب'),
              Tab(icon: Icon(Icons.map), text: 'الخريطة التفاعلية'),
            ],
            onTap: (index) {
              setState(() {
                _updateFilters();
              });
            },
          ),
        ),
        body: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: primaryTeal),
                    SizedBox(height: 15),
                    Text('جاري تحميل قاعدة بيانات الأطباء والعيادات...'),
                  ],
                ),
              )
            : TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(), 
                children: [
                  // TAB 1: LIST VIEW
                  _buildListViewTab(primaryTeal, accentPink),

                  // TAB 2: MAP VIEW
                  _buildMapViewTab(primaryTeal, accentPink),
                ],
              ),
      ),
    );
  }

  // --- TAB 1: LIST VIEW WIDGETS ---
  Widget _buildListViewTab(Color teal, Color pink) {
    return Column(
      children: [
        // Search & Filter Panel
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Search Input
              TextField(
                decoration: InputDecoration(
                  hintText: 'ابحثي باسم الطبيب، الولاية، أو البلدية...',
                  prefixIcon: Icon(Icons.search, color: teal),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _updateFilters();
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: teal, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                    _updateFilters();
                  });
                },
              ),
              const SizedBox(height: 10),
              
              // Location Button and Wilaya dropdown
              Row(
                children: [
                  // Geolocator Button
                  ElevatedButton.icon(
                    onPressed: _isLocating ? null : _getUserLocation,
                    icon: _isLocating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location, size: 16),
                    label: Text(_userLocation != null ? 'تحديث موقعي 📍' : 'الأطباء الأقرب إليّ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pink,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Wilaya Dropdown (disabled if location is active, to enforce proximity search)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: _userLocation != null ? Colors.grey.shade100 : Colors.white,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _userLocation != null ? 0 : _selectedWilayaId,
                          hint: const Text('كل الولايات'),
                          isExpanded: true,
                          disabledHint: const Text('مرتب حسب الأقرب 📍'),
                          items: [
                            const DropdownMenuItem<int>(
                              value: 0,
                              child: Text('كل ولايات الجزائر 🇩🇿', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            ..._wilayas.map((w) {
                              return DropdownMenuItem<int>(
                                value: w.id,
                                child: Text('${w.id}. ${w.nameAr}'),
                              );
                            }).toList(),
                          ],
                          onChanged: _userLocation != null ? null : (val) {
                            setState(() {
                              _selectedWilayaId = val ?? 0;
                              _updateFilters();
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('🩺 نساء وتوليد'),
                      selected: _showGyn,
                      selectedColor: pink.withOpacity(0.15),
                      checkmarkColor: pink,
                      labelStyle: TextStyle(color: _showGyn ? pink : Colors.black, fontWeight: _showGyn ? FontWeight.bold : FontWeight.normal),
                      onSelected: (selected) {
                        setState(() {
                          _showGyn = selected;
                          _updateFilters();
                        });
                      },
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: const Text('👶 طب الأطفال'),
                      selected: _showPedia,
                      selectedColor: Colors.purple.withOpacity(0.15),
                      checkmarkColor: Colors.purple,
                      labelStyle: TextStyle(color: _showPedia ? Colors.purple.shade700 : Colors.black, fontWeight: _showPedia ? FontWeight.bold : FontWeight.normal),
                      onSelected: (selected) {
                        setState(() {
                          _showPedia = selected;
                          _updateFilters();
                        });
                      },
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: const Text('🏥 أمومة وطفولة / مستشفيات'),
                      selected: _showMaternity,
                      selectedColor: Colors.blue.withOpacity(0.15),
                      checkmarkColor: Colors.blue,
                      labelStyle: TextStyle(color: _showMaternity ? Colors.blue.shade700 : Colors.black, fontWeight: _showMaternity ? FontWeight.bold : FontWeight.normal),
                      onSelected: (selected) {
                        setState(() {
                          _showMaternity = selected;
                          _updateFilters();
                        });
                      },
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: const Text('🩺 عيادات عامة'),
                      selected: _showClinics,
                      selectedColor: teal.withOpacity(0.15),
                      checkmarkColor: teal,
                      labelStyle: TextStyle(color: _showClinics ? teal : Colors.black, fontWeight: _showClinics ? FontWeight.bold : FontWeight.normal),
                      onSelected: (selected) {
                        setState(() {
                          _showClinics = selected;
                          _updateFilters();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Results Summary / Location Reset
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _userLocation != null
                    ? 'الأطباء الأقرب إليكِ أولاً (${_filteredFacilities.length} منشأة)'
                    : 'العثور على: ${_filteredFacilities.length} منشأة طبية',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700, fontSize: 13),
              ),
              if (_userLocation != null)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _userLocation = null;
                      _updateFilters();
                    });
                  },
                  icon: const Icon(Icons.refresh, size: 14, color: Colors.red),
                  label: const Text('إلغاء التحديد الجغرافي', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                )
              else if (_selectedWilayaId > 0)
                Text(
                  _wilayas.firstWhere((w) => w.id == _selectedWilayaId).nameAr,
                  style: TextStyle(fontWeight: FontWeight.bold, color: teal, fontSize: 13),
                ),
            ],
          ),
        ),

        // List View of Facilities
        Expanded(
          child: _filteredFacilities.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 10),
                      const Text(
                        'لا توجد نتائج تطابق خيارات البحث.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      const Text('يرجى تعديل الفلاتر أو كتابة عبارة بحث أخرى.'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: _filteredFacilities.length,
                  itemBuilder: (context, index) {
                    final f = _filteredFacilities[index];
                    
                    // Compute distance dynamically if user coordinates are active
                    double? distanceKm;
                    if (_userLocation != null) {
                      distanceKm = _calculateDistance(_userLocation!.latitude, _userLocation!.longitude, f.lat, f.lon);
                    }

                    return _buildMedicalFacilityCard(f, teal, pink, distanceKm);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMedicalFacilityCard(MedicalFacility f, Color teal, Color pink, double? distanceKm) {
    IconData iconData = Icons.local_hospital;
    Color typeColor = teal;
    
    if (f.type == 'gynaecologist') {
      iconData = Icons.pregnant_woman;
      typeColor = pink;
    } else if (f.type == 'hospital') {
      iconData = Icons.domain;
      typeColor = Colors.blue;
    } else if (f.type == 'doctor') {
      iconData = Icons.medical_services;
      typeColor = Colors.green;
    }

    // Format distance nicely
    String distanceString = '';
    if (distanceKm != null) {
      if (distanceKm < 1.0) {
        distanceString = 'تبعد ${(distanceKm * 1000).toStringAsFixed(0)} متر 📍';
      } else {
        distanceString = 'تبعد ${distanceKm.toStringAsFixed(1)} كم 📍';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Name, Distance & Type badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: typeColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              f.nameAr,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (distanceString.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                distanceString,
                                style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.w800, fontSize: 11),
                              ),
                            ),
                        ],
                      ),
                      if (f.nameAr != f.nameFr && f.nameFr.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          f.nameFr,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Facility Specs
            Row(
              children: [
                Icon(Icons.label_outline, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 5),
                Text(
                  f.typeDescAr,
                  style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: f.isPublic ? Colors.blue.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    f.isPublic ? 'عمومي' : 'خاص / عيادة حرة',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: f.isPublic ? Colors.blue.shade800 : Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Location
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    '${f.address} (${f.wilayaNameAr})',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Phone
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 5),
                Text(
                  f.phone,
                  style: TextStyle(
                    color: f.phone != 'غير متوفر' ? Colors.blue : Colors.grey.shade700,
                    fontWeight: f.phone != 'غير متوفر' ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Actions Buttons
            Row(
              children: [
                // Click to Call
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: f.phone != 'غير متوفر' ? () => _makePhoneCall(f.phone) : null,
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('اتصال بالعيادة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: teal,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade200,
                      disabledForegroundColor: Colors.grey.shade400,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Open in Maps
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openInGoogleMaps(f.lat, f.lon),
                    icon: Icon(Icons.directions, size: 16, color: teal),
                    label: const Text('الاتجاهات على الخريطة'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: teal),
                      foregroundColor: teal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Show on App Map Tab
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: teal.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.map, color: teal),
                    tooltip: 'عرض على الخريطة المدمجة',
                    onPressed: () {
                      setState(() {
                        _selectedFacility = f;
                        _tabController.animateTo(1);
                      });
                      Future.delayed(const Duration(milliseconds: 300), () {
                        _mapController.move(LatLng(f.lat, f.lon), 15.0);
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 2: MAP VIEW WIDGETS ---
  Widget _buildMapViewTab(Color teal, Color pink) {
    return Stack(
      children: [
        // The OSM Map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _selectedFacility != null
                ? LatLng(_selectedFacility!.lat, _selectedFacility!.lon)
                : LatLng(28.0339, 1.6596),
            initialZoom: _selectedFacility != null ? 13.0 : 5.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.nabda.app',
            ),
            MarkerLayer(markers: _buildMapMarkers(teal, pink)),
          ],
        ),

        // Country and Wilaya selection card / GPS button
        Positioned(
          top: 8,
          left: 8,
          right: 8,
          child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Map Geolocator Trigger Button
                          IconButton(
                            icon: Icon(
                              _userLocation != null ? Icons.gps_fixed : Icons.gps_not_fixed,
                              color: _userLocation != null ? pink : Colors.grey,
                            ),
                            tooltip: 'تحديد موقعي الأقرب إليّ',
                            onPressed: _getUserLocation,
                          ),
                          const VerticalDivider(width: 10, thickness: 1),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _selectedCountryCode,
                                isExpanded: true,
                                items: arabCountries.map((c) {
                                  return DropdownMenuItem<int>(
                                    value: c.code,
                                    child: Text('${c.flag} ${c.nameAr}'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedCountryCode = val ?? 0;
                                    _selectedWilayaId = 0;
                                    _selectedCity = '';
                                    _userLocation = null;
                                    _updateFilters();
                                    _zoomToCountry(_selectedCountryCode);
                                  });
                                },
                              ),
                            ),
                          ),
                          if (_userLocation != null)
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red, size: 20),
                              tooltip: 'إلغاء التحديد الجغرافي',
                              onPressed: () {
                                setState(() {
                                  _userLocation = null;
                                  _updateFilters();
                                });
                              },
                            ),
                        ],
                      ),
                      const Divider(height: 6, thickness: 1),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: DropdownButtonHideUnderline(
                          child: _selectedCountryCode == 0
                              ? DropdownButton<int>(
                                  value: _userLocation != null ? 0 : _selectedWilayaId,
                                  hint: const Text('اختر الولاية لتكبير الخريطة'),
                                  disabledHint: const Text('مرتب حسب الأقرب لموقعكِ 📍'),
                                  isExpanded: true,
                                  items: [
                                    const DropdownMenuItem<int>(
                                      value: 0,
                                      child: Text('كل ولايات الجزائر 🇩🇿', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    ..._wilayas.map((w) {
                                      return DropdownMenuItem<int>(
                                        value: w.id,
                                        child: Text('${w.id}. ${w.nameAr}'),
                                      );
                                    }).toList(),
                                  ],
                                  onChanged: _userLocation != null ? null : (val) {
                                    setState(() {
                                      _selectedWilayaId = val ?? 0;
                                      _updateFilters();
                                      _zoomToWilaya(_selectedWilayaId);
                                    });
                                  },
                                )
                              : DropdownButton<String>(
                                  value: _selectedCity.isEmpty ? null : _selectedCity,
                                  hint: const Text('كل المدن والمحافظات'),
                                  disabledHint: const Text('مرتب حسب الأقرب لموقعكِ 📍'),
                                  isExpanded: true,
                                  items: [
                                    const DropdownMenuItem<String>(
                                      value: null,
                                      child: Text('كل المدن والمحافظات', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    ...getSelectedCountryCities().map((c) {
                                      return DropdownMenuItem<String>(
                                        value: c,
                                        child: Text(c),
                                      );
                                    }).toList(),
                                  ],
                                  onChanged: _userLocation != null ? null : (val) {
                                    setState(() {
                                      _selectedCity = val ?? '';
                                      _updateFilters();
                                      if (_selectedCity.isNotEmpty) {
                                        _zoomToCity(_selectedCity);
                                      } else {
                                        _zoomToCountry(_selectedCountryCode);
                                      }
                                    });
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
            ),

            // Floating Filter chips on Map
            Positioned(
              top: 118,
              left: 8,
              right: 8,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildMapFilterChip('نساء وتوليد 🩺', _showGyn, pink, (val) {
                      setState(() {
                        _showGyn = val;
                        _updateFilters();
                      });
                    }),
                    _buildMapFilterChip('طب الأطفال 👶', _showPedia, Colors.purple, (val) {
                      setState(() {
                        _showPedia = val;
                        _updateFilters();
                      });
                    }),
                    _buildMapFilterChip('أمومة وطفولة 🏥', _showMaternity, Colors.blue, (val) {
                      setState(() {
                        _showMaternity = val;
                        _updateFilters();
                      });
                    }),
                    _buildMapFilterChip('عيادات عامة 🩺', _showClinics, teal, (val) {
                      setState(() {
                        _showClinics = val;
                        _updateFilters();
                      });
                    }),
                  ],
                ),
              ),
            ),

        // Bottom popup details overlay when marker selected
        if (_selectedFacility != null)
          Positioned(
            bottom: 15,
            left: 15,
            right: 15,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: teal.withOpacity(0.2), width: 1.5),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with dismiss & distance
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedFacility!.nameAr,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              if (_selectedFacility!.nameFr.isNotEmpty && _selectedFacility!.nameAr != _selectedFacility!.nameFr) ...[
                                const SizedBox(height: 2),
                                Text(
                                  _selectedFacility!.nameFr,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        // Close button
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            setState(() {
                              _selectedFacility = null;
                            });
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 12),
                    
                    // Info Row: badges & Proximity indicator
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _selectedFacility!.type == 'gynaecologist' ? pink.withOpacity(0.1) : teal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _selectedFacility!.typeDescAr,
                            style: TextStyle(
                              color: _selectedFacility!.type == 'gynaecologist' ? pink : teal,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _selectedFacility!.isPublic ? Colors.blue.shade50 : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _selectedFacility!.isPublic ? 'عمومي' : 'خاص',
                            style: TextStyle(
                              color: _selectedFacility!.isPublic ? Colors.blue.shade800 : Colors.orange.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        
                        // Distance indicator inside map popup
                        if (_userLocation != null) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              'تبعد ${_calculateDistance(_userLocation!.latitude, _userLocation!.longitude, _selectedFacility!.lat, _selectedFacility!.lon).toStringAsFixed(1)} كم',
                              style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ]
                      ],
                    ),
                    const SizedBox(height: 10),
                    
                    // Address & Phone
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, color: Colors.grey, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${_selectedFacility!.address} (${_selectedFacility!.wilayaNameAr})',
                            style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.phone, color: Colors.grey, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _selectedFacility!.phone,
                          style: TextStyle(
                            color: _selectedFacility!.phone != 'غير متوفر' ? Colors.blue : Colors.black,
                            fontWeight: _selectedFacility!.phone != 'غير متوفر' ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Actions Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _selectedFacility!.phone != 'غير متوفر' 
                                ? () => _makePhoneCall(_selectedFacility!.phone) 
                                : null,
                            icon: const Icon(Icons.phone, size: 16),
                            label: const Text('اتصال هاتفي'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: teal,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade100,
                              disabledForegroundColor: Colors.grey.shade400,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _openInGoogleMaps(_selectedFacility!.lat, _selectedFacility!.lon),
                            icon: const Icon(Icons.directions, size: 16),
                            label: const Text('عرض الاتجاهات'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: teal),
                              foregroundColor: teal,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMapFilterChip(String label, bool isSelected, Color activeColor, Function(bool) onSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: activeColor.withOpacity(0.2),
        checkmarkColor: activeColor,
        elevation: 3,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? activeColor : Colors.black,
        ),
        onSelected: onSelected,
      ),
    );
  }

  void _showWilayaRequiredAlert() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('الرجاء اختيار ولاية أو استخدام زر GPS أولاً لعرض العيادات والمستشفيات لتجنب تباطؤ الخريطة.'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  List<Marker> _buildMapMarkers(Color teal, Color pink) {
    final markers = <Marker>[];

    // 1. Draw User's Current GPS Location Marker
    if (_userLocation != null) {
      markers.add(
        Marker(
          point: _userLocation!,
          width: 50.0,
          height: 50.0,
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing circle background
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.25),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue.shade300, width: 1.5),
                ),
              ),
              // Center solid dot
              Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 1),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Draw Doctor & Clinic Markers
    markers.addAll(_filteredFacilities.map((f) {
      Color markerColor = teal;
      IconData markerIcon = Icons.location_on;
      
      if (f.isGynaecology) {
        markerColor = pink;
        markerIcon = Icons.pregnant_woman;
      } else if (f.isPediatrics) {
        markerColor = Colors.purple;
        markerIcon = Icons.child_care;
      } else if (f.isMaternity || f.type == 'hospital') {
        markerColor = Colors.blue;
        markerIcon = Icons.domain;
      } else {
        markerColor = teal;
        markerIcon = Icons.medical_services;
      }

      final bool isSelected = _selectedFacility?.id == f.id;

      return Marker(
        point: LatLng(f.lat, f.lon),
        width: isSelected ? 50.0 : 40.0,
        height: isSelected ? 50.0 : 40.0,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedFacility = f;
            });
            _mapController.move(LatLng(f.lat - 0.002, f.lon), _mapController.camera.zoom);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              shape: BoxShape.circle,
              boxShadow: isSelected
                  ? [
                      const BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: Icon(
              isSelected ? Icons.location_on : markerIcon,
              color: markerColor,
              size: isSelected ? 42 : 32,
            ),
          ),
        ),
      );
    }));

    return markers;
  }
}
