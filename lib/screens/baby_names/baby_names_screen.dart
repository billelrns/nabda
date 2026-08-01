import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/baby_names_database.dart';
import '../../data/twin_names_database.dart';
import '../../data/names_articles_database.dart';

// ══════════════════════════════════════════════════════════════
// Baby Names Screen — Inspired by WeMoms with Islamic names filter
// ══════════════════════════════════════════════════════════════

class BabyName {
  final String name;
  final String gender;
  final String meaning;
  final int popularityRank;
  final List<String> countries;
  final bool isIslamic;
  const BabyName(this.name, this.gender, this.meaning, this.popularityRank, this.countries, {this.isIslamic = false});
}

class BabyNamesScreen extends StatefulWidget {
  const BabyNamesScreen({Key? key}) : super(key: key);
  @override
  State<BabyNamesScreen> createState() => _BabyNamesScreenState();
}

class _BabyNamesScreenState extends State<BabyNamesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCountry = 'الجزائر';
  String _sortBy = 'popular'; // popular, az, islamic
  String _searchQuery = '';
  Set<String> _favorites = {};
  final _searchController = TextEditingController();
  List<BabyName> _userNames = [];

  // Twin filtering state
  String _selectedTwinType = 'الكل'; // الكل، ثنائي، ثلاثي، رباعي
  String _selectedTwinGender = 'الكل'; // الكل، بنات، أولاد، مختلط

  // Articles filtering state
  String _selectedArticleCategory = 'الكل'; // الكل، شرعية، دليل الاختيار، علم النفس

  // Global likes system
  Map<String, int> _likesCount = {};    // name → total likes from all users
  Set<String> _likedByMe = {};          // names the current user liked

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: 1);
    _loadFavorites();
    _loadUserNames();
    _loadGlobalLikes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['favoriteNames'] != null) {
        setState(() {
          _favorites = Set<String>.from(data['favoriteNames'] as List);
          _likedByMe = Set<String>.from(_favorites);
        });
      }
    }
  }

  Future<void> _loadUserNames() async {
    final snap = await FirebaseFirestore.instance.collection('user_baby_names').orderBy('createdAt', descending: true).get();
    setState(() {
      _userNames = snap.docs.map((d) {
        final data = d.data();
        return BabyName(
          data['name'] ?? '', data['gender'] ?? 'male',
          data['meaning'] ?? '', 999,
          List<String>.from(data['countries'] ?? []),
        );
      }).toList();
    });
  }

  Future<void> _loadGlobalLikes() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final snap = await FirebaseFirestore.instance.collection('baby_name_likes').get();
    final Map<String, int> counts = {};
    final Set<String> myLikes = {};
    for (final doc in snap.docs) {
      final data = doc.data();
      counts[doc.id] = (data['count'] as int?) ?? 0;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      if (uid != null && likedBy.contains(uid)) {
        myLikes.add(doc.id);
      }
    }
    if (mounted) {
      setState(() {
        _likesCount = counts;
        _likedByMe = myLikes;
        // Sync personal favorites with global likes
        _favorites = Set<String>.from(myLikes);
      });
    }
  }

  Future<void> _toggleFavorite(String name) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final docRef = FirebaseFirestore.instance.collection('baby_name_likes').doc(name);
    final isLiked = _likedByMe.contains(name);

    // Optimistic UI update
    setState(() {
      if (isLiked) {
        _likedByMe.remove(name);
        _favorites.remove(name);
        _likesCount[name] = (_likesCount[name] ?? 1) - 1;
        if ((_likesCount[name] ?? 0) < 0) _likesCount[name] = 0;
      } else {
        _likedByMe.add(name);
        _favorites.add(name);
        _likesCount[name] = (_likesCount[name] ?? 0) + 1;
      }
    });

    // Firestore update
    try {
      final docSnap = await docRef.get();
      if (docSnap.exists) {
        if (isLiked) {
          await docRef.update({
            'count': FieldValue.increment(-1),
            'likedBy': FieldValue.arrayRemove([uid]),
          });
        } else {
          await docRef.update({
            'count': FieldValue.increment(1),
            'likedBy': FieldValue.arrayUnion([uid]),
          });
        }
      } else {
        // First like — create the document
        await docRef.set({
          'count': 1,
          'likedBy': [uid],
        });
      }
      // Also save to user's personal favorites
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'favoriteNames': _favorites.toList(),
      });
    } catch (_) {
      // Revert on error
      setState(() {
        if (isLiked) {
          _likedByMe.add(name);
          _favorites.add(name);
          _likesCount[name] = (_likesCount[name] ?? 0) + 1;
        } else {
          _likedByMe.remove(name);
          _favorites.remove(name);
          _likesCount[name] = (_likesCount[name] ?? 1) - 1;
        }
      });
    }
  }

  List<BabyName> _getFilteredNames(String gender) {
    final all = [...babyNamesDatabase, ..._userNames];
    List<BabyName> names;
    if (gender == 'fav') {
      names = all.where((n) => _favorites.contains(n.name)).toList();
    } else {
      names = all.where((n) => n.gender == gender && n.countries.contains(_selectedCountry)).toList();
    }
    // If Islamic filter is active, only show Islamic names
    if (_sortBy == 'islamic') {
      names = names.where((n) => n.isIslamic).toList();
    }
    if (_searchQuery.isNotEmpty) {
      names = names.where((n) => n.name.contains(_searchQuery) || n.meaning.contains(_searchQuery)).toList();
    }
    if (_sortBy == 'az') {
      names.sort((a, b) => a.name.compareTo(b.name));
    } else {
      names.sort((a, b) => a.popularityRank.compareTo(b.popularityRank));
    }
    return names;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8FB),
        appBar: AppBar(
          title: const Text('أسماء المواليد', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFF1F1A20),
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFCE4EC), Color(0xFFFFF8FB), Color(0xFFEDE7F6)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddNameDialog,
          backgroundColor: const Color(0xFF7C4DFF),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('أضيفي اسماً', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
        body: Column(children: [
          // Search bar + country chip
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'ابحثي عن اسم...', hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 22),
                      border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () {
                            _searchController.clear(); setState(() => _searchQuery = '');
                          }) : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _showCountrySheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE7F6), borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFF7C4DFF).withOpacity(0.2)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.location_on, color: Color(0xFF7C4DFF), size: 16),
                    const SizedBox(width: 4),
                    Text(_selectedCountry, style: const TextStyle(color: Color(0xFF7C4DFF), fontWeight: FontWeight.w600, fontSize: 13)),
                  ]),
                ),
              ),
            ]),
          ),
          // Sort chips row — now includes Islamic
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _sortChip('popular', 'الأكثر شعبية', Icons.trending_up),
                const SizedBox(width: 8),
                _sortChip('az', 'أبجدي (أ-ي)', Icons.sort_by_alpha),
                const SizedBox(width: 8),
                _sortChip('islamic', 'أسماء إسلامية', Icons.auto_stories),
              ]),
            ),
          ),
          const SizedBox(height: 6),
          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(999)),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicator: BoxDecoration(color: const Color(0xFF7C4DFF), borderRadius: BorderRadius.circular(999)),
              labelColor: Colors.white, unselectedLabelColor: Colors.grey.shade600,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              indicatorSize: TabBarIndicatorSize.tab, dividerHeight: 0,
              tabs: const [
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.favorite, size: 14), SizedBox(width: 2), Text('المفضلة')])),
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.female, size: 14), SizedBox(width: 2), Text('بنات')])),
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.male, size: 14), SizedBox(width: 2), Text('أولاد')])),
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.people, size: 14), SizedBox(width: 2), Text('التوائم')])),
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.menu_book, size: 14), SizedBox(width: 2), Text('دليل الأسماء')])),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Islamic filter banner (only if not on twins/articles tab)
          if (_sortBy == 'islamic' && _tabController.index != 3 && _tabController.index != 4)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [const Color(0xFF00897B).withOpacity(0.1), const Color(0xFF00897B).withOpacity(0.05)]),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00897B).withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.auto_stories, color: Color(0xFF00897B), size: 20),
                const SizedBox(width: 8),
                const Expanded(child: Text('أسماء مستوحاة من القرآن الكريم والسنة النبوية', style: TextStyle(color: Color(0xFF00897B), fontSize: 13, fontWeight: FontWeight.w600))),
                GestureDetector(
                  onTap: () => setState(() => _sortBy = 'popular'),
                  child: const Icon(Icons.close, color: Color(0xFF00897B), size: 18),
                ),
              ]),
            ),
          if (_sortBy == 'islamic' && _tabController.index != 3 && _tabController.index != 4) const SizedBox(height: 8),
          Expanded(
            child: TabBarView(controller: _tabController, children: [
              _buildNamesList('fav'), _buildNamesList('female'), _buildNamesList('male'), _buildTwinsTab(), _buildArticlesTab(),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _sortChip(String value, String label, IconData icon) {
    final sel = _sortBy == value;
    final isIslamicChip = value == 'islamic';
    final activeColor = isIslamicChip ? const Color(0xFF00897B) : const Color(0xFF7C4DFF);
    return GestureDetector(
      onTap: () => setState(() => _sortBy = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: sel ? activeColor : Colors.grey.shade300),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: sel ? Colors.white : Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? Colors.white : Colors.grey.shade600)),
        ]),
      ),
    );
  }

  Widget _buildNamesList(String gender) {
    final names = _getFilteredNames(gender);
    if (names.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(gender == 'fav' ? Icons.favorite_border : (_sortBy == 'islamic' ? Icons.auto_stories : Icons.baby_changing_station),
          size: 60, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(gender == 'fav' ? 'لم تضيفي أسماء للمفضلة بعد' : (_sortBy == 'islamic' ? 'لا توجد أسماء إسلامية في هذا البلد' : 'لا توجد أسماء مطابقة'),
          style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
        if (gender == 'fav')
          Padding(padding: const EdgeInsets.only(top: 8),
            child: Text('اضغطي على ♡ لإضافة الأسماء', style: TextStyle(color: Colors.grey.shade400, fontSize: 13))),
      ]));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: names.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
      itemBuilder: (context, i) {
        final name = names[i];
        final isFav = _likedByMe.contains(name.name);
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          leading: Container(
            width: 36, height: 36, alignment: Alignment.center,
            decoration: BoxDecoration(
              color: i < 3 ? const Color(0xFF7C4DFF).withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${i + 1}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
              color: i < 3 ? const Color(0xFF7C4DFF) : Colors.grey.shade400)),
          ),
          title: Row(children: [
            Flexible(child: Text(name.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1F1A20)))),
            if (name.isIslamic) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF00897B).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: const Text('قرآني', style: TextStyle(fontSize: 9, color: Color(0xFF00897B), fontWeight: FontWeight.w700)),
              ),
            ],
          ]),
          subtitle: Text(name.meaning, style: TextStyle(fontSize: 12, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: GestureDetector(
            onTap: () => _toggleFavorite(name.name),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? const Color(0xFFE91E63) : Colors.grey.shade300, size: 24),
                const SizedBox(height: 2),
                Text(
                  '${_likesCount[name.name] ?? 0}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isFav ? const Color(0xFFE91E63) : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          onTap: () => _showNameDetail(name),
        );
      },
    );
  }

  Widget _buildTwinsTab() {
    final filteredTwins = twinNamesDatabase.where((twin) {
      final typeMatches = _selectedTwinType == 'الكل' || twin.type == _selectedTwinType;
      final genderMatches = _selectedTwinGender == 'الكل' || twin.genderType == _selectedTwinGender;
      return typeMatches && genderMatches;
    }).toList();

    return Column(
      children: [
        // Choice chips for twin type
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text('نوع التوأم:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1F1A20))),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['الكل', 'ثنائي', 'ثلاثي', 'رباعي'].map((type) {
                      final isSelected = _selectedTwinType == type;
                      return Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setState(() => _selectedTwinType = type);
                          },
                          selectedColor: const Color(0xFF7C4DFF),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999), side: BorderSide(color: Colors.grey.shade200)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Choice chips for gender
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              const Text('الجنس:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1F1A20))),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['الكل', 'بنات', 'أولاد', 'مختلط'].map((gender) {
                      final isSelected = _selectedTwinGender == gender;
                      return Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: ChoiceChip(
                          label: Text(gender),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setState(() => _selectedTwinGender = gender);
                          },
                          selectedColor: const Color(0xFFE91E63),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999), side: BorderSide(color: Colors.grey.shade200)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: filteredTwins.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 60, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('لا توجد توائم مطابقة للخيارات', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: filteredTwins.length,
                  itemBuilder: (context, index) {
                    final group = filteredTwins[index];
                    Color genderColor;
                    IconData genderIcon;
                    if (group.genderType == 'بنات') {
                      genderColor = const Color(0xFFE91E63);
                      genderIcon = Icons.female;
                    } else if (group.genderType == 'أولاد') {
                      genderColor = const Color(0xFF7C4DFF);
                      genderIcon = Icons.male;
                    } else {
                      genderColor = const Color(0xFFFF9800);
                      genderIcon = Icons.wc;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: genderColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(genderIcon, size: 14, color: genderColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${group.type} - ${group.genderType}',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: genderColor),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00897B).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.stars, size: 14, color: Color(0xFF00897B)),
                                      SizedBox(width: 4),
                                      Text(
                                        'تناسق مميز',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF00897B)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: group.names.map((name) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        genderColor.withOpacity(0.15),
                                        genderColor.withOpacity(0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: genderColor.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    name,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1F1A20)),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'سر التناسق: ${group.harmonyReason}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24, color: Color(0xFFFFF1F6)),
                            Text(
                              group.meaning,
                              style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF4A434B)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showNameDetail(BabyName name) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: DraggableScrollableSheet(
          initialChildSize: 0.65, minChildSize: 0.4, maxChildSize: 0.9,
          builder: (_, scrollCtrl) => Container(
            decoration: const BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: ListView(controller: scrollCtrl, padding: EdgeInsets.zero, children: [
              Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Center(child: Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    name.gender == 'female' ? const Color(0xFFE91E63) : const Color(0xFF7C4DFF),
                    name.gender == 'female' ? const Color(0xFFF48FB1) : const Color(0xFFB388FF),
                  ]), borderRadius: BorderRadius.circular(35),
                ),
                child: Center(child: Text(name.name.isNotEmpty ? name.name[0] : '?', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white))),
              )),
              const SizedBox(height: 14),
              Center(child: Text(name.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF1F1A20)))),
              const SizedBox(height: 6),
              Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: name.gender == 'female' ? const Color(0xFFFCE4EC) : const Color(0xFFEDE7F6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(name.gender == 'female' ? '♀ اسم بنت' : '♂ اسم ولد',
                    style: TextStyle(color: name.gender == 'female' ? const Color(0xFFE91E63) : const Color(0xFF7C4DFF),
                      fontWeight: FontWeight.w600, fontSize: 13)),
                ),
                if (name.isIslamic) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00897B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.auto_stories, size: 14, color: Color(0xFF00897B)),
                      SizedBox(width: 4),
                      Text('اسم إسلامي', style: TextStyle(color: Color(0xFF00897B), fontWeight: FontWeight.w600, fontSize: 13)),
                    ]),
                  ),
                ],
              ])),
              const SizedBox(height: 20),
              // Meaning
              Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Container(
                width: double.infinity, padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFFFF8FB), borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.auto_stories, color: Color(0xFF7C4DFF), size: 20),
                    SizedBox(width: 8),
                    Text('المعنى', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF7C4DFF))),
                  ]),
                  const SizedBox(height: 10),
                  Text(name.meaning, style: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF4A434B))),
                ]),
              )),
              const SizedBox(height: 14),
              // Countries
              Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Container(
                width: double.infinity, padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFF3E5F5).withOpacity(0.4), borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFCE93D8).withOpacity(0.2))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.public, color: Color(0xFF7C4DFF), size: 20),
                    SizedBox(width: 8),
                    Text('شائع في', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF7C4DFF))),
                  ]),
                  const SizedBox(height: 10),
                  Wrap(spacing: 6, runSpacing: 6, children: name.countries.map((c) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFF7C4DFF).withOpacity(0.2))),
                    child: Text(c, style: const TextStyle(fontSize: 12, color: Color(0xFF7C4DFF))),
                  )).toList()),
                ]),
              )),
              const SizedBox(height: 20),
              // Likes count display
              Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE4EC).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.favorite, color: Color(0xFFE91E63), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    '${_likesCount[name.name] ?? 0} إعجاب',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFE91E63)),
                  ),
                ]),
              )),
              const SizedBox(height: 14),
              // Favorite button
              Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 30), child: SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton.icon(
                  onPressed: () { _toggleFavorite(name.name); Navigator.pop(ctx); },
                  icon: Icon(_likedByMe.contains(name.name) ? Icons.favorite : Icons.favorite_border),
                  label: Text(_likedByMe.contains(name.name) ? 'إزالة من المفضلة' : 'إضافة للمفضلة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _likedByMe.contains(name.name) ? Colors.grey.shade200 : const Color(0xFF7C4DFF),
                    foregroundColor: _likedByMe.contains(name.name) ? Colors.grey.shade700 : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)), elevation: 0,
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              )),
            ]),
          ),
        ),
      ),
    );
  }

  void _showAddNameDialog() {
    final nameC = TextEditingController();
    final meaningC = TextEditingController();
    String gender = 'female';
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(builder: (ctx2, setS) => Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx2).viewInsets.bottom + 24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const Text('أضيفي اسماً جديداً', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('شاركي اسماً غير موجود في القائمة', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () => setS(() => gender = 'female'),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: gender == 'female' ? const Color(0xFFFCE4EC) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: gender == 'female' ? const Color(0xFFE91E63) : Colors.grey.shade200),
                  ),
                  child: Column(children: [
                    Icon(Icons.female, color: gender == 'female' ? const Color(0xFFE91E63) : Colors.grey, size: 28),
                    const SizedBox(height: 4),
                    Text('بنت', style: TextStyle(fontWeight: FontWeight.w700,
                      color: gender == 'female' ? const Color(0xFFE91E63) : Colors.grey)),
                  ]),
                ),
              )),
              const SizedBox(width: 12),
              Expanded(child: GestureDetector(
                onTap: () => setS(() => gender = 'male'),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: gender == 'male' ? const Color(0xFFEDE7F6) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: gender == 'male' ? const Color(0xFF7C4DFF) : Colors.grey.shade200),
                  ),
                  child: Column(children: [
                    Icon(Icons.male, color: gender == 'male' ? const Color(0xFF7C4DFF) : Colors.grey, size: 28),
                    const SizedBox(height: 4),
                    Text('ولد', style: TextStyle(fontWeight: FontWeight.w700,
                      color: gender == 'male' ? const Color(0xFF7C4DFF) : Colors.grey)),
                  ]),
                ),
              )),
            ]),
            const SizedBox(height: 16),
            TextField(controller: nameC, decoration: InputDecoration(
              labelText: 'الاسم', filled: true, fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            )),
            const SizedBox(height: 12),
            TextField(controller: meaningC, maxLines: 3, decoration: InputDecoration(
              labelText: 'المعنى', filled: true, fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            )),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
              onPressed: () async {
                if (nameC.text.trim().isEmpty || meaningC.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx2).showSnackBar(
                    const SnackBar(content: Text('يرجى ملء الاسم والمعنى'), backgroundColor: Colors.red));
                  return;
                }
                await FirebaseFirestore.instance.collection('user_baby_names').add({
                  'name': nameC.text.trim(), 'meaning': meaningC.text.trim(),
                  'gender': gender, 'countries': [_selectedCountry],
                  'addedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (mounted) Navigator.pop(ctx);
                _loadUserNames();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تمت إضافة الاسم بنجاح ✓'), backgroundColor: Color(0xFF7C4DFF)));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C4DFF), foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)), elevation: 0,
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              child: const Text('إضافة الاسم'),
            )),
          ])),
        )),
      ),
    );
  }

  void _showCountrySheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const Text('اختاري البلد', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Expanded(child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _countries.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, i) {
                final c = _countries[i];
                final sel = c['name'] == _selectedCountry;
                return ListTile(
                  leading: Text(c['flag']!, style: const TextStyle(fontSize: 28)),
                  title: Text(c['name']!, style: TextStyle(fontSize: 16,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    color: sel ? const Color(0xFF7C4DFF) : const Color(0xFF1F1A20))),
                  trailing: sel
                    ? const Icon(Icons.check_circle, color: Color(0xFF7C4DFF), size: 24)
                    : Icon(Icons.radio_button_off, color: Colors.grey.shade300, size: 24),
                  onTap: () { setState(() => _selectedCountry = c['name']!); Navigator.pop(context); },
                );
              },
            )),
          ]),
        ),
      ),
    );
  }

  static const _countries = [
    {'name': 'الجزائر', 'flag': '🇩🇿'}, {'name': 'المغرب', 'flag': '🇲🇦'},
    {'name': 'تونس', 'flag': '🇹🇳'}, {'name': 'ليبيا', 'flag': '🇱🇾'},
    {'name': 'مصر', 'flag': '🇪🇬'}, {'name': 'السعودية', 'flag': '🇸🇦'},
    {'name': 'الإمارات', 'flag': '🇦🇪'}, {'name': 'الكويت', 'flag': '🇰🇼'},
    {'name': 'قطر', 'flag': '🇶🇦'}, {'name': 'البحرين', 'flag': '🇧🇭'},
    {'name': 'عُمان', 'flag': '🇴🇲'}, {'name': 'العراق', 'flag': '🇮🇶'},
    {'name': 'سوريا', 'flag': '🇸🇾'}, {'name': 'الأردن', 'flag': '🇯🇴'},
    {'name': 'لبنان', 'flag': '🇱🇧'}, {'name': 'فلسطين', 'flag': '🇵🇸'},
    {'name': 'اليمن', 'flag': '🇾🇪'}, {'name': 'السودان', 'flag': '🇸🇩'},
    {'name': 'موريتانيا', 'flag': '🇲🇷'}, {'name': 'الصومال', 'flag': '🇸🇴'},
    {'name': 'جيبوتي', 'flag': '🇩🇯'}, {'name': 'جزر القمر', 'flag': '🇰🇲'},
  ];

  Widget _buildArticlesTab() {
    final filteredArticles = namesArticlesDatabase.where((art) {
      return _selectedArticleCategory == 'الكل' || art.category == _selectedArticleCategory;
    }).toList();

    return Column(
      children: [
        // Category choice chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Text('التصنيف:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1F1A20))),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['الكل', 'شرعية', 'دليل الاختيار', 'علم النفس'].map((cat) {
                      final isSelected = _selectedArticleCategory == cat;
                      Color activeColor;
                      if (cat == 'شرعية') {
                        activeColor = const Color(0xFF00897B);
                      } else if (cat == 'دليل الاختيار') {
                        activeColor = const Color(0xFF7C4DFF);
                      } else if (cat == 'علم النفس') {
                        activeColor = const Color(0xFFFF9800);
                      } else {
                        activeColor = const Color(0xFF1F1A20);
                      }

                      return Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setState(() => _selectedArticleCategory = cat);
                          },
                          selectedColor: activeColor,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999), side: BorderSide(color: Colors.grey.shade200)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: filteredArticles.length,
            itemBuilder: (context, index) {
              final art = filteredArticles[index];
              Color catColor = const Color(0xFF7C4DFF);
              IconData catIcon = Icons.menu_book;
              if (art.category == 'شرعية') {
                catColor = const Color(0xFF00897B);
                catIcon = Icons.auto_stories;
              } else if (art.category == 'علم النفس') {
                catColor = const Color(0xFFFF9800);
                catIcon = Icons.psychology;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                color: Colors.white,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(catIcon, color: catColor, size: 20),
                  ),
                  title: Text(
                    art.title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1F1A20)),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      art.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BabyNameArticleDetailScreen(article: art),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class BabyNameArticleDetailScreen extends StatelessWidget {
  final NamesArticle article;

  const BabyNameArticleDetailScreen({Key? key, required this.article}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color catColor = const Color(0xFF7C4DFF);
    IconData catIcon = Icons.menu_book;
    if (article.category == 'شرعية') {
      catColor = const Color(0xFF00897B);
      catIcon = Icons.auto_stories;
    } else if (article.category == 'علم النفس') {
      catColor = const Color(0xFFFF9800);
      catIcon = Icons.psychology;
    }

    final paragraphs = article.body.split('\n\n').where((p) => p.trim().isNotEmpty).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(article.category, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: const Color(0xFF1F1A20),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(catIcon, size: 14, color: catColor),
                    const SizedBox(width: 6),
                    Text(
                      article.category,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: catColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                article.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1F1A20), height: 1.4),
              ),
              const Divider(height: 32, color: Color(0xFFFFF1F6)),
              for (final p in paragraphs) ...[
                Text(
                  p.trim(),
                  style: const TextStyle(fontSize: 16, height: 1.8, color: Color(0xFF4A434B)),
                ),
                const SizedBox(height: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
