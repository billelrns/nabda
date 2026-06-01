import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // Global likes system
  Map<String, int> _likesCount = {};    // name → total likes from all users
  Set<String> _likedByMe = {};          // names the current user liked

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
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
    final all = [..._allNames, ..._userNames];
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
              indicator: BoxDecoration(color: const Color(0xFF7C4DFF), borderRadius: BorderRadius.circular(999)),
              labelColor: Colors.white, unselectedLabelColor: Colors.grey.shade600,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              indicatorSize: TabBarIndicatorSize.tab, dividerHeight: 0,
              tabs: const [
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.favorite, size: 16), SizedBox(width: 4), Text('المفضلة')])),
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.female, size: 16), SizedBox(width: 4), Text('بنات')])),
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.male, size: 16), SizedBox(width: 4), Text('أولاد')])),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Islamic filter banner
          if (_sortBy == 'islamic')
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
          if (_sortBy == 'islamic') const SizedBox(height: 8),
          Expanded(
            child: TabBarView(controller: _tabController, children: [
              _buildNamesList('fav'), _buildNamesList('female'), _buildNamesList('male'),
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

  // ══════════════════════════════════════════════════════════════
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

  // ══════════════════════════════════════════════════════════════
  // Names Database — 200+ names (100 female + 100 male) with Islamic flag
  // ══════════════════════════════════════════════════════════════
  static const _all = ['الجزائر','المغرب','تونس','ليبيا','مصر','السعودية','الإمارات','الكويت','قطر','البحرين','عُمان','العراق','سوريا','الأردن','لبنان','فلسطين','اليمن','السودان','موريتانيا','الصومال','جيبوتي','جزر القمر'];
  static const _mag = ['الجزائر','المغرب','تونس','ليبيا','موريتانيا'];
  static const _glf = ['السعودية','الإمارات','الكويت','قطر','البحرين','عُمان'];
  static const _shm = ['سوريا','الأردن','لبنان','فلسطين'];
  static const _egy = ['مصر'];
  static const _irq = ['العراق'];
  static const _ymn = ['اليمن'];
  static const _sdn = ['السودان'];
  static const _hrn = ['الصومال','جيبوتي','جزر القمر'];

  static const List<BabyName> _allNames = [
    // ─────────────────── FEMALE — Common (1-40) ───────────────────
    BabyName('مريم', 'female', 'اسم سورة في القرآن الكريم، السيدة مريم بنت عمران عليها السلام', 1, _all, isIslamic: true),
    BabyName('فاطمة', 'female', 'ابنة الرسول ﷺ، يعني التي فُطم عنها كل شر وسوء', 2, _all, isIslamic: true),
    BabyName('آية', 'female', 'الآية القرآنية، العلامة الدالة على قدرة الله وعظمته', 3, _all, isIslamic: true),
    BabyName('نور', 'female', 'من أسماء الله الحسنى، ذُكر في سورة النور، الضياء والهداية', 4, _all, isIslamic: true),
    BabyName('سارة', 'female', 'زوجة النبي إبراهيم عليه السلام، الأميرة السيدة النبيلة', 5, _all, isIslamic: true),
    BabyName('خديجة', 'female', 'أم المؤمنين زوجة الرسول ﷺ الأولى وأول من آمن به', 6, _all, isIslamic: true),
    BabyName('عائشة', 'female', 'أم المؤمنين زوجة الرسول ﷺ، ذات الحياة والعيش الرغيد', 7, _all, isIslamic: true),
    BabyName('أمينة', 'female', 'والدة الرسول ﷺ، المؤتمنة الصادقة ذات الأمانة والوفاء', 8, _all, isIslamic: true),
    BabyName('زينب', 'female', 'ابنة الرسول ﷺ وزوجته، شجرة جميلة طيبة الرائحة', 9, _all, isIslamic: true),
    BabyName('ياسمين', 'female', 'زهرة عطرة بيضاء رمز الجمال والنقاء والطهارة', 10, _all),
    BabyName('هاجر', 'female', 'أم النبي إسماعيل عليه السلام، زوجة إبراهيم الخليل', 11, _all, isIslamic: true),
    BabyName('ليلى', 'female', 'نشوة الخمر أو الليلة الظلماء الشديدة السواد', 12, _all),
    BabyName('أسماء', 'female', 'ذات النطاقين بنت أبي بكر الصديق رضي الله عنها', 13, _all, isIslamic: true),
    BabyName('حنان', 'female', 'الرحمة والعطف والحنو والشفقة على الآخرين', 14, _all),
    BabyName('سلمى', 'female', 'السالمة الناجية من كل آفة وسوء ومكروه', 15, _all),
    BabyName('رقية', 'female', 'ابنة الرسول ﷺ، الارتقاء والسمو والرفعة', 16, _all, isIslamic: true),
    BabyName('هدى', 'female', 'ذُكرت في القرآن كثيراً، الرشاد والطريق المستقيم', 17, _all, isIslamic: true),
    BabyName('سمية', 'female', 'أول شهيدة في الإسلام، علامة مميزة وسمة بارزة', 18, _all, isIslamic: true),
    BabyName('إيمان', 'female', 'التصديق والاعتقاد الجازم بالله ورسوله', 19, _all, isIslamic: true),
    BabyName('رحمة', 'female', 'من صفات الله، اللطف والرأفة والرفق بالخلق', 20, _all, isIslamic: true),
    BabyName('كريمة', 'female', 'السخية الجوادة ذات الأصل الطيب والنسب الشريف', 21, _all),
    BabyName('صفية', 'female', 'أم المؤمنين صفية بنت حيي، النقية الخالصة', 22, _all, isIslamic: true),
    BabyName('نادية', 'female', 'المنادية بصوت عالٍ أو الندية المبللة بالندى', 23, _all),
    BabyName('سناء', 'female', 'الضوء الساطع والرفعة والمجد والسمو والعلو', 24, _all),
    BabyName('وفاء', 'female', 'الإخلاص والأمانة والوفاء بالعهد والوعد الصادق', 25, _all),
    BabyName('هناء', 'female', 'السعادة والفرح والسرور وطيب العيش والرفاهية', 26, _all),
    BabyName('دعاء', 'female', 'الابتهال والتضرع إلى الله تعالى بالخشوع', 27, _all, isIslamic: true),
    BabyName('منال', 'female', 'ما يُنال ويُحصل عليه من خير وبركة ورزق', 28, _all),
    BabyName('سهام', 'female', 'النصيب والحظ الجيد، وهي أيضاً جمع سهم', 29, _all),
    BabyName('نجاة', 'female', 'النجاة والخلاص والسلامة من كل مكروه وأذى', 30, _all),
    BabyName('لجين', 'female', 'الفضة البيضاء اللامعة الخالصة النقية', 31, _all),
    BabyName('تسبيح', 'female', 'تمجيد الله وتنزيهه عن كل نقص سبحانه', 32, _all, isIslamic: true),
    BabyName('حنين', 'female', 'الشوق العميق والحنين إلى الأحبة والديار', 33, _all),
    BabyName('ابتهال', 'female', 'التضرع والدعاء إلى الله تعالى بخشوع وخضوع', 34, _all, isIslamic: true),
    BabyName('غفران', 'female', 'المغفرة والعفو من الله تعالى، التسامح والصفح', 35, _all, isIslamic: true),
    BabyName('مروة', 'female', 'جبل المروة في مكة المكرمة، من شعائر الحج', 36, _all, isIslamic: true),
    BabyName('تقوى', 'female', 'الخوف من الله واتقاء غضبه بالطاعة والعبادة', 37, _all, isIslamic: true),
    BabyName('براءة', 'female', 'سورة التوبة (البراءة)، النقاء والطهارة من العيوب', 38, _all, isIslamic: true),
    BabyName('عزة', 'female', 'القوة والمنعة والكرامة والعزة بالله تعالى', 39, _all),
    BabyName('نوال', 'female', 'العطاء والهبة والكرم والمنح والإحسان', 40, _all),
    // Female Common (41-60)
    BabyName('ملاك', 'female', 'الكائن النوراني الطاهر ذو الجمال والنقاء', 41, _all),
    BabyName('جنان', 'female', 'الحدائق الخضراء في الجنة، ذُكرت في القرآن', 42, _all, isIslamic: true),
    BabyName('إلهام', 'female', 'الوحي والإلهام الرباني والفكرة المبدعة', 43, _all),
    BabyName('سندس', 'female', 'الحرير الأخضر الرقيق، لباس أهل الجنة في القرآن', 44, _all, isIslamic: true),
    BabyName('أحلام', 'female', 'الرؤى في المنام والأماني والتطلعات الجميلة', 45, _all),
    BabyName('رانيا', 'female', 'المحدقة والناظرة بتأمل وإعجاب في الجمال', 46, _all),
    BabyName('عهد', 'female', 'الوعد والميثاق والالتزام والوفاء بالعهود', 47, _all),
    BabyName('شروق', 'female', 'وقت شروق الشمس وبزوغها وإشراقها الجميل', 48, _all),
    BabyName('وئام', 'female', 'الوفاق والانسجام والمحبة بين الناس', 49, _all),
    BabyName('عفاف', 'female', 'الطهارة والعفة والبعد عن كل محرّم وسوء', 50, _all),
    BabyName('ثريا', 'female', 'مجموعة نجوم مضيئة في السماء، النجمة اللامعة', 51, _all),
    BabyName('سحر', 'female', 'وقت ما قبل الفجر، السحر الحلال بالجمال', 52, _all),
    BabyName('ندى', 'female', 'قطرات الماء المتكونة صباحاً على الأزهار والأعشاب', 53, _all),
    BabyName('هالة', 'female', 'الدائرة المضيئة حول القمر والنور المحيط به', 54, _all),
    BabyName('سلوى', 'female', 'ذُكرت في القرآن (المن والسلوى)، ما يُسلي النفس', 55, _all, isIslamic: true),
    BabyName('فدوى', 'female', 'الفداء والتضحية من أجل الغالي والعزيز', 56, _all),
    BabyName('رشا', 'female', 'ولد الظبية الرشيق الجميل في حركته ولطافته', 57, _all),
    BabyName('إسراء', 'female', 'رحلة الإسراء المباركة، السير ليلاً بالنبي ﷺ', 58, _all, isIslamic: true),
    BabyName('سدرة', 'female', 'سدرة المنتهى في السماء السابعة، ذُكرت في القرآن', 59, _all, isIslamic: true),
    BabyName('تسنيم', 'female', 'عين ماء في الجنة ذُكرت في سورة المطففين', 60, _all, isIslamic: true),
    // Female Maghreb (61-80)
    BabyName('إيناس', 'female', 'الأنس والمودة والألفة والطمأنينة النفسية', 61, _mag),
    BabyName('إكرام', 'female', 'التكريم والاحترام وإعلاء المقام والإجلال', 62, _mag),
    BabyName('أميرة', 'female', 'الحاكمة الأميرة ذات السلطان والنفوذ', 63, _mag),
    BabyName('سهيلة', 'female', 'السهلة اللينة الطبع الرقيقة المعشر', 64, _mag),
    BabyName('نسيمة', 'female', 'الريح اللطيفة العليلة المنعشة الرقيقة', 65, _mag),
    BabyName('حياة', 'female', 'العيش والبقاء والحياة الطيبة الهانئة', 66, _mag),
    BabyName('نبيلة', 'female', 'الشريفة العالية الشأن ذات النسب الرفيع', 67, _mag),
    BabyName('سعاد', 'female', 'السعد والحظ الجيد والبهجة والسرور', 68, _mag),
    BabyName('لمياء', 'female', 'ذات الشفاه السمراء الجميلة والجمال اللافت', 69, _mag),
    BabyName('سميرة', 'female', 'المحدّثة ليلاً والمؤانسة في السمر والحديث', 70, _mag),
    BabyName('نعيمة', 'female', 'المنعّمة المرفّهة ذات النعمة والرفاهية', 71, _mag),
    BabyName('جميلة', 'female', 'الحسناء ذات الجمال الباهر والوجه البهي', 72, _mag),
    BabyName('فريدة', 'female', 'الوحيدة المتفردة التي لا مثيل لها', 73, _mag),
    BabyName('خيرة', 'female', 'ذات الخير والبركة والعطاء الوفير', 74, _mag),
    BabyName('زهرة', 'female', 'الوردة الجميلة المتفتحة والإشراقة البهية', 75, _mag),
    BabyName('بشرى', 'female', 'الخبر السار المفرح والبشارة الطيبة من الله', 76, _mag, isIslamic: true),
    BabyName('مليكة', 'female', 'الملكة صاحبة الملك والسيادة والنفوذ', 77, _mag),
    BabyName('وردة', 'female', 'الزهرة الجميلة ذات العطر الفواح والألوان', 78, _mag),
    BabyName('لينا', 'female', 'النخلة الصغيرة أو الفتاة الحسناء اللينة', 79, _mag),
    BabyName('ريان', 'female', 'باب من أبواب الجنة للصائمين، المرتوية', 80, _mag, isIslamic: true),
    // Female Gulf (61-80)
    BabyName('لطيفة', 'female', 'الرقيقة اللطيفة ذات الظرف والدماثة', 61, _glf),
    BabyName('موزة', 'female', 'اللؤلؤة الصغيرة البيضاء النفيسة (خليجي)', 62, _glf),
    BabyName('شمّا', 'female', 'ذات الشامة الجميلة والخال الحسن', 63, _glf),
    BabyName('الجوهرة', 'female', 'الدرة الثمينة واللؤلؤة النادرة الغالية', 64, _glf),
    BabyName('نورة', 'female', 'القطعة من النور والضياء والهداية الإلهية', 65, _glf),
    BabyName('هيا', 'female', 'حسنة المظهر ذات الجمال والبهاء والأناقة', 66, _glf),
    BabyName('مها', 'female', 'البقرة الوحشية ذات العيون الواسعة الجميلة', 67, _glf),
    BabyName('ريم', 'female', 'الظبي الأبيض الصغير ذو الجمال الفائق', 68, _glf),
    BabyName('شيخة', 'female', 'المرأة الموقرة ذات المكانة الرفيعة العالية', 69, _glf),
    BabyName('حصة', 'female', 'النصيب والقسمة من الخير والبركة', 70, _glf),
    BabyName('منيرة', 'female', 'المشعة بالنور والضياء والإشراق الجميل', 71, _glf),
    BabyName('عبير', 'female', 'الرائحة الزكية والعطر الفواح المميز', 72, _glf),
    BabyName('لولوة', 'female', 'اللؤلؤة الثمينة النادرة البراقة اللامعة', 73, _glf),
    BabyName('شيماء', 'female', 'أخت الرسول ﷺ من الرضاعة، ذات الشامات', 74, _glf, isIslamic: true),
    BabyName('العنود', 'female', 'العنيدة القوية الشامخة المتمسكة بموقفها', 75, _glf),
    BabyName('مشاعل', 'female', 'المشاعل المنيرة والأنوار الساطعة المضيئة', 76, _glf),
    BabyName('أمل', 'female', 'الرجاء والتمني والتطلع إلى الخير والبركة', 77, _glf),
    BabyName('هند', 'female', 'المائة من الإبل، المرأة الثمينة الغالية', 78, _glf),
    BabyName('جواهر', 'female', 'الأحجار الكريمة الثمينة والدرر النفيسة', 79, _glf),
    BabyName('خلود', 'female', 'البقاء الدائم والخلود الأبدي في النعيم', 80, _glf),
    // Female Sham (61-80)
    BabyName('تالا', 'female', 'النخلة الصغيرة الجميلة أو الفتاة الشابة', 61, _shm),
    BabyName('لمى', 'female', 'سمرة في باطن الشفة تزيدها جمالاً وحسناً', 62, _shm),
    BabyName('رنا', 'female', 'ما يُرنى إليه لحسنه وجماله ولطافته', 63, _shm),
    BabyName('ديما', 'female', 'المطر الهادئ المستمر بلا رعد ولا برق', 64, _shm),
    BabyName('سيدرا', 'female', 'سدرة المنتهى في السماء السابعة عند الله', 65, _shm, isIslamic: true),
    BabyName('جنى', 'female', 'ما يُجنى من الثمار والحصاد والخير الوفير', 66, _shm),
    BabyName('لين', 'female', 'النعومة والرقة واللطافة والليونة في الطبع', 67, _shm),
    BabyName('روان', 'female', 'نهر في الجنة، والروح المتدفقة بالحياة', 68, _shm),
    BabyName('رهف', 'female', 'الرقة واللطف والنعومة الفائقة والدقة', 69, _shm),
    BabyName('يارا', 'female', 'القادرة والمستطيعة، الفتاة القوية الجميلة', 70, _shm),
    BabyName('سما', 'female', 'العلو والارتفاع والسمو والمكانة العالية', 71, _shm),
    BabyName('ناي', 'female', 'آلة موسيقية عذبة الصوت ورقيقة اللحن', 72, _shm),
    BabyName('سلام', 'female', 'السلام اسم من أسماء الله، الأمان والطمأنينة', 73, _shm, isIslamic: true),
    BabyName('ربى', 'female', 'المكان المرتفع العالي والتلة الخضراء', 74, _shm),
    BabyName('مايا', 'female', 'الأم العظيمة أو ربيع الحياة والجمال', 75, _shm),
    BabyName('ألين', 'female', 'أجمل نساء العالم، الفتاة الحسناء الرقيقة', 76, _shm),
    BabyName('ميس', 'female', 'التمايل والتبختر في المشي بدلال وأناقة', 77, _shm),
    BabyName('غزل', 'female', 'المدح والثناء الجميل والحديث العذب اللطيف', 78, _shm),
    BabyName('تمارا', 'female', 'شجرة النخيل المثمرة الباسقة المعطاءة', 79, _shm),
    BabyName('غادة', 'female', 'الفتاة الناعمة اللينة المتمايلة بدلال', 80, _shm),
    // Female Egypt (61-80)
    BabyName('ملك', 'female', 'الملاك الطاهر النقي ذو الجمال الفائق', 61, _egy),
    BabyName('حبيبة', 'female', 'المحبوبة الغالية العزيزة على القلب والنفس', 62, _egy),
    BabyName('شهد', 'female', 'العسل الصافي الخالص الحلو المذاق اللذيذ', 63, _egy),
    BabyName('فرح', 'female', 'السعادة والبهجة والسرور والانشراح في الحياة', 64, _egy),
    BabyName('مرح', 'female', 'الفرح الشديد والبهجة والنشاط والحيوية', 65, _egy),
    BabyName('جودي', 'female', 'الجبل الذي استوت عليه سفينة نوح في القرآن', 66, _egy, isIslamic: true),
    BabyName('بسمة', 'female', 'الابتسامة الجميلة والضحكة الرقيقة الدافئة', 67, _egy),
    BabyName('هبة', 'female', 'العطية والمنحة والهدية من الله تعالى', 68, _egy),
    BabyName('ضحى', 'female', 'سورة الضحى، وقت ارتفاع الشمس وإشراقها', 69, _egy, isIslamic: true),
    BabyName('روضة', 'female', 'الحديقة الغناء المليئة بالأزهار والجمال', 70, _egy),
    BabyName('نهى', 'female', 'العقل والحكمة والرزانة، ذُكرت في القرآن', 71, _egy, isIslamic: true),
    BabyName('سجى', 'female', 'السكون والهدوء في الليل، ذُكرت في سورة الضحى', 72, _egy, isIslamic: true),
    BabyName('رودينا', 'female', 'السحابة التي غطت الرسول ﷺ وقت الغار', 73, _egy),
    BabyName('توليب', 'female', 'زهرة التوليب الجميلة المتعددة الألوان', 74, _egy),
    BabyName('تقى', 'female', 'الورع والتقوى والخوف من الله تعالى', 75, _egy, isIslamic: true),
    BabyName('رغد', 'female', 'سعة العيش والرفاهية، ذُكرت في سورة البقرة', 76, _egy, isIslamic: true),
    BabyName('بثينة', 'female', 'الأرض السهلة اللينة الطيبة الخصبة', 77, _egy),
    BabyName('سهى', 'female', 'نجم صغير خافت الضوء في بنات نعش الكبرى', 78, _egy),
    BabyName('راوية', 'female', 'المحدثة الراوية لأحاديث النبي والعلم', 79, _egy),
    BabyName('عبلة', 'female', 'المرأة الممتلئة الجسم ذات الصحة والعافية', 80, _egy),
    // Female Iraq (61-70)
    BabyName('زهراء', 'female', 'لقب فاطمة الزهراء بنت الرسول ﷺ، المشرقة', 61, _irq, isIslamic: true),
    BabyName('بتول', 'female', 'لقب مريم والزهراء، العذراء المنقطعة للعبادة', 62, _irq, isIslamic: true),
    BabyName('كوثر', 'female', 'نهر في الجنة ذُكر في سورة الكوثر', 63, _irq, isIslamic: true),
    BabyName('حوراء', 'female', 'الحور العين في الجنة، ذات العيون الواسعة', 64, _irq, isIslamic: true),
    BabyName('استبرق', 'female', 'الحرير السميك المنسوج بالذهب، ذُكر في القرآن', 65, _irq, isIslamic: true),
    BabyName('سكينة', 'female', 'السكينة من الله، الهدوء والطمأنينة والوقار', 66, _irq, isIslamic: true),
    BabyName('نرجس', 'female', 'زهرة النرجس الجميلة ذات العطر الفواح', 67, _irq),
    BabyName('زمزم', 'female', 'ماء زمزم المبارك في مكة المكرمة', 68, _irq, isIslamic: true),
    BabyName('سجود', 'female', 'السجود لله تعالى، أقرب ما يكون العبد لربه', 69, _irq, isIslamic: true),
    BabyName('رقيّة', 'female', 'الارتقاء والسمو والعلو في المكانة والشأن', 70, _irq),
    // Female Yemen (61-70)
    BabyName('بلقيس', 'female', 'ملكة سبأ الحكيمة ذُكرت قصتها في سورة النمل', 61, _ymn, isIslamic: true),
    BabyName('أروى', 'female', 'أنثى الوعل الجبلي الجميلة الرشيقة', 62, _ymn),
    BabyName('شذى', 'female', 'الرائحة الزكية القوية والعطر الفواح المميز', 63, _ymn),
    BabyName('غيداء', 'female', 'الفتاة الناعمة المتمايلة ذات الدلال والحسن', 64, _ymn),
    BabyName('وسام', 'female', 'ما يُعلق على الصدر تقديراً وتكريماً', 65, _ymn),
    // Female Sudan (61-70)
    BabyName('آلاء', 'female', 'نعم الله الكثيرة، ذُكرت في سورة الرحمن', 61, _sdn, isIslamic: true),
    BabyName('إشراق', 'female', 'صلاة الإشراق، سطوع الشمس وتألقها عند الصبح', 62, _sdn, isIslamic: true),
    BabyName('مودة', 'female', 'المحبة والألفة، ذُكرت في القرآن الكريم', 63, _sdn, isIslamic: true),
    BabyName('تهاني', 'female', 'التبريكات والتهنئات بالمناسبات السعيدة', 64, _sdn),
    BabyName('رغدة', 'female', 'الرفاهية وسعة العيش والنعمة الوافرة', 65, _sdn),
    // Female Horn (61-70)
    BabyName('آمنة', 'female', 'والدة الرسول ﷺ، المطمئنة الآمنة من كل خوف', 61, _hrn, isIslamic: true),
    BabyName('نعمة', 'female', 'نعم الله على عباده، الخير والفضل والمنحة', 62, _hrn, isIslamic: true),
    BabyName('عابدة', 'female', 'المتعبدة المطيعة لله تعالى بالصلاة والذكر', 63, _hrn, isIslamic: true),
    BabyName('رجاء', 'female', 'الأمل في رحمة الله والتطلع إلى عفوه', 64, _hrn, isIslamic: true),
    BabyName('ثناء', 'female', 'الحمد والثناء على الله تعالى بالخير', 65, _hrn, isIslamic: true),

    // ─────────────────── MALE — Common (1-40) ───────────────────
    BabyName('محمد', 'male', 'المحمود المثنى عليه، اسم النبي ﷺ خاتم الأنبياء والمرسلين', 1, _all, isIslamic: true),
    BabyName('أحمد', 'male', 'الأكثر حمداً لله، اسم النبي ﷺ في الإنجيل المبشر به', 2, _all, isIslamic: true),
    BabyName('يوسف', 'male', 'نبي الله يوسف عليه السلام، ذُكرت سورة كاملة باسمه', 3, _all, isIslamic: true),
    BabyName('عبدالله', 'male', 'عبد الله، أحب الأسماء إلى الله تعالى كما في الحديث', 4, _all, isIslamic: true),
    BabyName('عبدالرحمن', 'male', 'عبد الرحمن، من أحب الأسماء إلى الله كما في الحديث', 5, _all, isIslamic: true),
    BabyName('علي', 'male', 'الرفيع الشأن العالي المقام، اسم الإمام علي بن أبي طالب', 6, _all, isIslamic: true),
    BabyName('عمر', 'male', 'الفاروق عمر بن الخطاب رضي الله عنه، العمر المديد', 7, _all, isIslamic: true),
    BabyName('إبراهيم', 'male', 'خليل الرحمن أبو الأنبياء عليه السلام، ذُكر في القرآن', 8, _all, isIslamic: true),
    BabyName('خالد', 'male', 'سيف الله المسلول خالد بن الوليد، الباقي الدائم', 9, _all, isIslamic: true),
    BabyName('حسن', 'male', 'سبط النبي ﷺ الحسن بن علي، الجميل الحسن البهي', 10, _all, isIslamic: true),
    BabyName('حسين', 'male', 'سبط النبي ﷺ الحسين بن علي سيد الشهداء', 11, _all, isIslamic: true),
    BabyName('ياسين', 'male', 'سورة ياسين قلب القرآن، من الحروف المقطعة', 12, _all, isIslamic: true),
    BabyName('أيوب', 'male', 'نبي الله أيوب عليه السلام، رمز الصبر والاحتساب', 13, _all, isIslamic: true),
    BabyName('آدم', 'male', 'أبو البشر آدم عليه السلام، أول الخلق والأنبياء', 14, _all, isIslamic: true),
    BabyName('إسماعيل', 'male', 'نبي الله إسماعيل ابن إبراهيم، يسمع الله دعاءه', 15, _all, isIslamic: true),
    BabyName('عثمان', 'male', 'ذو النورين عثمان بن عفان، الخليفة الراشد الثالث', 16, _all, isIslamic: true),
    BabyName('بلال', 'male', 'مؤذن الرسول ﷺ بلال بن رباح، الندى والماء', 17, _all, isIslamic: true),
    BabyName('أنس', 'male', 'خادم الرسول ﷺ أنس بن مالك، الأنس والمودة', 18, _all, isIslamic: true),
    BabyName('حمزة', 'male', 'أسد الله حمزة عم النبي ﷺ سيد الشهداء', 19, _all, isIslamic: true),
    BabyName('طارق', 'male', 'ذُكر في سورة الطارق، النجم الثاقب المضيء', 20, _all, isIslamic: true),
    BabyName('زيد', 'male', 'الصحابي زيد بن حارثة، النمو والزيادة في الخير', 21, _all, isIslamic: true),
    BabyName('سعد', 'male', 'الصحابي سعد بن أبي وقاص، السعادة والحظ الجيد', 22, _all, isIslamic: true),
    BabyName('مصطفى', 'male', 'المختار المصطفى، من ألقاب النبي ﷺ الشريفة', 23, _all, isIslamic: true),
    BabyName('كريم', 'male', 'من صفات الله الكريم، السخي ذو الأخلاق النبيلة', 24, _all, isIslamic: true),
    BabyName('عمار', 'male', 'الصحابي عمار بن ياسر، الباني المعمّر ذو العمر الطويل', 25, _all, isIslamic: true),
    BabyName('صلاح', 'male', 'صلاح الدين الأيوبي، الاستقامة والتقوى والبر', 26, _all, isIslamic: true),
    BabyName('نبيل', 'male', 'الشريف ذو الحسب والنسب الرفيع والأخلاق العالية', 27, _all),
    BabyName('ماجد', 'male', 'صاحب المجد والشرف والعزة والكرامة والسؤدد', 28, _all),
    BabyName('رشيد', 'male', 'من أسماء الله الحسنى، المهتدي ذو الرأي السديد', 29, _all, isIslamic: true),
    BabyName('رياض', 'male', 'رياض الجنة، الحدائق الخضراء الجميلة', 30, _all, isIslamic: true),
    // Male Common (31-60)
    BabyName('وائل', 'male', 'الصحابي وائل بن حجر، اللاجئ إلى الله', 31, _all, isIslamic: true),
    BabyName('فادي', 'male', 'المنقذ الفادي المضحي بنفسه لأجل غيره', 32, _all),
    BabyName('هاني', 'male', 'السعيد الهانئ المسرور في حياته وعيشه', 33, _all),
    BabyName('نادر', 'male', 'القليل الوجود والنادر الحصول النفيس', 34, _all),
    BabyName('عماد', 'male', 'عماد الدين، العمود والدعامة والركيزة القوية', 35, _all),
    BabyName('رامي', 'male', 'القاذف بالسهام والرامي الماهر في الرمي', 36, _all),
    BabyName('معاذ', 'male', 'الصحابي معاذ بن جبل، المحفوظ المعاذ بالله', 37, _all, isIslamic: true),
    BabyName('أسامة', 'male', 'أسامة بن زيد حِبّ النبي ﷺ، اسم من أسماء الأسد', 38, _all, isIslamic: true),
    BabyName('ثابت', 'male', 'الصحابي ثابت بن قيس، الراسخ المستقر على الحق', 39, _all, isIslamic: true),
    BabyName('غسان', 'male', 'حدة الشباب ونضارته وقوة الفتوة والحيوية', 40, _all),
    BabyName('أيمن', 'male', 'المبارك ذو اليمن والبركة والخير الوفير', 41, _all),
    BabyName('مؤمن', 'male', 'المؤمن بالله حق الإيمان، من أسماء الله الحسنى', 42, _all, isIslamic: true),
    BabyName('فراس', 'male', 'الفطن الذكي شديد الفراسة والبصيرة النافذة', 43, _all),
    BabyName('سالم', 'male', 'المعافى السالم من كل سوء ومكروه وأذى', 44, _all),
    BabyName('حازم', 'male', 'الجاد الحاسم في أموره بعزم وقوة وثبات', 45, _all),
    BabyName('عادل', 'male', 'العادل المنصف الذي يحكم بالعدل بين الناس', 46, _all),
    BabyName('وسيم', 'male', 'حسن الوجه جميل الملامح متناسق القسمات', 47, _all),
    BabyName('جابر', 'male', 'الصحابي جابر بن عبدالله، المصلح الذي يجبر الكسر', 48, _all, isIslamic: true),
    BabyName('توفيق', 'male', 'التوفيق من الله، النجاح والسداد في الأمور', 49, _all, isIslamic: true),
    BabyName('صالح', 'male', 'نبي الله صالح عليه السلام، المستقيم التقي', 50, _all, isIslamic: true),
    BabyName('موسى', 'male', 'نبي الله موسى كليم الله عليه السلام', 51, _all, isIslamic: true),
    BabyName('داود', 'male', 'نبي الله داود عليه السلام، الحبيب المحبوب', 52, _all, isIslamic: true),
    BabyName('سليمان', 'male', 'نبي الله سليمان عليه السلام، المسالم الحكيم', 53, _all, isIslamic: true),
    BabyName('نوح', 'male', 'نبي الله نوح عليه السلام أبو البشر الثاني', 54, _all, isIslamic: true),
    BabyName('لقمان', 'male', 'لقمان الحكيم المذكور في سورة لقمان في القرآن', 55, _all, isIslamic: true),
    BabyName('شاكر', 'male', 'الشاكر لنعم الله المعترف بفضله سبحانه', 56, _all, isIslamic: true),
    BabyName('عبدالكريم', 'male', 'عبد الكريم المنسوب لله الكريم سبحانه', 57, _all, isIslamic: true),
    BabyName('هشام', 'male', 'الكرم والجود والسخاء الشديد في العطاء', 58, _all),
    BabyName('مؤيد', 'male', 'المنصور المعزز المؤيد بنصر الله وتوفيقه', 59, _all, isIslamic: true),
    BabyName('وليد', 'male', 'المولود الجديد والطفل حديث الولادة', 60, _all),
    // Male Maghreb (61-80)
    BabyName('أمين', 'male', 'لقب النبي ﷺ الأمين، المؤتمن الصادق الوفي', 61, _mag, isIslamic: true),
    BabyName('سفيان', 'male', 'سفيان الثوري العالم الجليل، المسرع بخفة', 62, _mag, isIslamic: true),
    BabyName('إسلام', 'male', 'الإسلام دين الله الحنيف، الاستسلام لله تعالى', 63, _mag, isIslamic: true),
    BabyName('عبدالقادر', 'male', 'عبد القادر الجيلاني، المنسوب لله القادر', 64, _mag, isIslamic: true),
    BabyName('مهدي', 'male', 'المهتدي إلى طريق الحق والرشاد والصواب', 65, _mag, isIslamic: true),
    BabyName('جمال', 'male', 'الحُسن في الخَلق والخُلق والجمال الباهر', 66, _mag),
    BabyName('نسيم', 'male', 'الهواء العليل اللطيف المنعش الرقيق', 67, _mag),
    BabyName('فيصل', 'male', 'الحاكم القاطع الفاصل بين الحق والباطل', 68, _mag),
    BabyName('منير', 'male', 'المشع بالنور والضياء والإشراق الوضاء', 69, _mag),
    BabyName('عبدالحق', 'male', 'عبد الحق، المنسوب لله الحق سبحانه وتعالى', 70, _mag, isIslamic: true),
    BabyName('حكيم', 'male', 'من أسماء الله الحسنى، ذو الحكمة والعلم', 71, _mag, isIslamic: true),
    BabyName('مراد', 'male', 'المطلوب المرغوب والمقصود من كل أمر وعمل', 72, _mag),
    BabyName('جلال', 'male', 'جلال الدين، العظمة والهيبة والوقار', 73, _mag),
    BabyName('لخضر', 'male', 'الأخضر، رمز الحياة والخصب والنماء والبركة', 74, _mag),
    BabyName('مسعود', 'male', 'ابن مسعود الصحابي، ذو السعد والحظ الجيد', 75, _mag, isIslamic: true),
    BabyName('عيسى', 'male', 'نبي الله عيسى المسيح عليه السلام', 76, _mag, isIslamic: true),
    BabyName('فؤاد', 'male', 'الفؤاد ذُكر في القرآن، القلب النابض بالحياة', 77, _mag, isIslamic: true),
    BabyName('نورالدين', 'male', 'نور الدين الزنكي، ضياء الشريعة والإيمان', 78, _mag, isIslamic: true),
    BabyName('رضا', 'male', 'رضا الله، القناعة والرضا بقضاء الله', 79, _mag, isIslamic: true),
    BabyName('عبدالمالك', 'male', 'عبد المالك، المنسوب لله مالك الملك', 80, _mag, isIslamic: true),
    // Male Gulf (61-80)
    BabyName('فهد', 'male', 'الحيوان المفترس السريع الرشيق القوي', 61, _glf),
    BabyName('سلطان', 'male', 'الحاكم صاحب السلطة والسيادة والنفوذ العظيم', 62, _glf),
    BabyName('تركي', 'male', 'القوي الشجاع ذو الأصل العربي العريق', 63, _glf),
    BabyName('ناصر', 'male', 'المنصور الظافر المعين على أعدائه بقوة', 64, _glf),
    BabyName('سعود', 'male', 'جمع سعد، الحظوظ الجيدة والأقدار السعيدة', 65, _glf),
    BabyName('بندر', 'male', 'المرفأ والمدينة الساحلية التجارية المزدهرة', 66, _glf),
    BabyName('مشاري', 'male', 'خلايا النحل، المنتج للعسل والخير والبركة', 67, _glf),
    BabyName('عبدالعزيز', 'male', 'عبد العزيز، المنسوب لله العزيز سبحانه', 68, _glf, isIslamic: true),
    BabyName('حمد', 'male', 'الحمد والثناء والشكر لله رب العالمين', 69, _glf, isIslamic: true),
    BabyName('راشد', 'male', 'المهتدي إلى طريق الصواب والرشد والحق', 70, _glf, isIslamic: true),
    BabyName('ثامر', 'male', 'الشجرة المثمرة كثيرة الثمار والخيرات', 71, _glf),
    BabyName('سيف', 'male', 'السيف القاطع رمز القوة والشجاعة والبأس', 72, _glf),
    BabyName('منصور', 'male', 'المنتصر الظافر الفائز بنصر الله تعالى', 73, _glf, isIslamic: true),
    BabyName('نايف', 'male', 'المرتفع العالي الشامخ السامي المقام', 74, _glf),
    BabyName('مبارك', 'male', 'المبارك ذو البركة والخير الكثير من الله', 75, _glf, isIslamic: true),
    BabyName('جاسم', 'male', 'العظيم الضخم الكبير ذو الجسم القوي', 76, _glf),
    BabyName('طلال', 'male', 'المطل من مكان مرتفع والجمال الباهر اللافت', 77, _glf),
    BabyName('خليفة', 'male', 'خليفة الله في الأرض، من يقوم مقام غيره', 78, _glf, isIslamic: true),
    BabyName('زايد', 'male', 'المتزايد في الخير والعطاء والكرم والإحسان', 79, _glf),
    BabyName('صقر', 'male', 'الطائر الجارح القوي رمز الشجاعة والقوة', 80, _glf),
    // Male Sham (61-80)
    BabyName('باسل', 'male', 'الشجاع المقدام الجريء في المعارك والحروب', 61, _shm),
    BabyName('غيث', 'male', 'المطر الغزير النافع، رحمة الله على عباده', 62, _shm, isIslamic: true),
    BabyName('كنان', 'male', 'الغطاء والستر والحماية من الأذى والشر', 63, _shm),
    BabyName('تيم', 'male', 'تيم الله، العبد المسخّر المذلل بحب الله', 64, _shm, isIslamic: true),
    BabyName('ليث', 'male', 'الأسد الشجاع القوي المقدام في المعارك', 65, _shm),
    BabyName('قصي', 'male', 'جد النبي ﷺ قصي بن كلاب، البعيد النسب الشريف', 66, _shm, isIslamic: true),
    BabyName('مالك', 'male', 'الإمام مالك بن أنس، صاحب الملك والسلطة', 67, _shm, isIslamic: true),
    BabyName('باسم', 'male', 'المبتسم الضاحك ذو البشاشة والطلاقة والبهجة', 68, _shm),
    BabyName('هيثم', 'male', 'الصقر الصغير القوي ابن النسر الشجاع', 69, _shm),
    BabyName('راكان', 'male', 'الوقار والثبات والرزانة والهدوء والحكمة', 70, _shm),
    BabyName('يزن', 'male', 'ذو يزن الحميري، العدل والميزان والاتزان', 71, _shm),
    BabyName('جاد', 'male', 'الكريم السخي المعطاء والجدية في العمل', 72, _shm),
    BabyName('عامر', 'male', 'الباني العامر المعمّر كثير الخير والبركة', 73, _shm),
    BabyName('كرم', 'male', 'السخاء والجود والكرم في العطاء والإحسان', 74, _shm),
    BabyName('أوس', 'male', 'الأوس من قبائل المدينة، الذئب القوي', 75, _shm, isIslamic: true),
    BabyName('لؤي', 'male', 'جد النبي ﷺ لؤي بن غالب، الثور الوحشي', 76, _shm, isIslamic: true),
    BabyName('سامر', 'male', 'المتحدث ليلاً والمسامر في السهرات الجميلة', 77, _shm),
    BabyName('نور الدين', 'male', 'نور الدين الزنكي، ضياء الشريعة والإيمان', 78, _shm, isIslamic: true),
    BabyName('آصف', 'male', 'آصف بن برخيا وزير سليمان، الكاتب الحاذق', 79, _shm, isIslamic: true),
    BabyName('حارث', 'male', 'الحارث، الزارع المزارع ذو الكسب والعمل', 80, _shm),
    // Male Egypt (61-75)
    BabyName('عمرو', 'male', 'عمرو بن العاص فاتح مصر، الحياة الطويلة', 61, _egy, isIslamic: true),
    BabyName('مروان', 'male', 'حجر صلب يُستخدم لإشعال النار والقدح', 62, _egy),
    BabyName('أدهم', 'male', 'إبراهيم بن أدهم الزاهد، الأسود الشديد السواد', 63, _egy, isIslamic: true),
    BabyName('شريف', 'male', 'النبيل ذو الشرف والمكانة الرفيعة العالية', 64, _egy),
    BabyName('تامر', 'male', 'صاحب التمر الكثير والرزق الوفير المبارك', 65, _egy),
    BabyName('ياسر', 'male', 'والد عمار بن ياسر الصحابي، السهل الميسور', 66, _egy, isIslamic: true),
    // Male Iraq (61-75)
    BabyName('حيدر', 'male', 'لقب الإمام علي، الأسد القوي الشجاع المقدام', 61, _irq, isIslamic: true),
    BabyName('عباس', 'male', 'العباس عم النبي ﷺ، الأسد العابس المهاب', 62, _irq, isIslamic: true),
    BabyName('جعفر', 'male', 'جعفر الطيار ابن عم النبي ﷺ، النهر المتدفق', 63, _irq, isIslamic: true),
    BabyName('طه', 'male', 'سورة طه في القرآن الكريم، من الحروف المقطعة', 64, _irq, isIslamic: true),
    BabyName('كاظم', 'male', 'الكاظم للغيظ، من صفات المؤمنين في القرآن', 65, _irq, isIslamic: true),
    BabyName('مرتضى', 'male', 'المرضي المقبول المختار والمصطفى عند الله', 66, _irq, isIslamic: true),
    BabyName('هادي', 'male', 'من أسماء الله الحسنى، المرشد إلى الحق', 67, _irq, isIslamic: true),
    BabyName('ساجد', 'male', 'الساجد لله تعالى في صلاته وعبادته', 68, _irq, isIslamic: true),
    // Male Yemen (61-70)
    BabyName('همام', 'male', 'ذو الهمة العالية والإرادة القوية والعزيمة', 61, _ymn),
    BabyName('شوقي', 'male', 'ذو الشوق العميق والحنين الشديد للأحبة', 62, _ymn),
    // Male Sudan (61-70)
    BabyName('مزمل', 'male', 'سورة المزمل، من ألقاب النبي ﷺ المتلفف بثيابه', 61, _sdn, isIslamic: true),
    BabyName('معتصم', 'male', 'المتمسك بالحق المعتصم بحبل الله المتين', 62, _sdn, isIslamic: true),
    BabyName('بشير', 'male', 'حامل البشارة والخبر السار، صفة النبي ﷺ', 63, _sdn, isIslamic: true),
    BabyName('حاتم', 'male', 'حاتم الطائي رمز الكرم، القاضي الحاكم بعدل', 64, _sdn),
    BabyName('صديق', 'male', 'لقب أبي بكر الصديق، الصادق الأمين', 65, _sdn, isIslamic: true),
    // Male Horn (61-70)
    BabyName('عبدي', 'male', 'العبد المنسوب إلى الله تعالى بالعبودية', 61, _hrn, isIslamic: true),
    BabyName('فارح', 'male', 'السعيد الفرح المسرور ذو البهجة والسرور', 62, _hrn),
    BabyName('عقيل', 'male', 'عقيل بن أبي طالب، العاقل الرزين ذو الحكمة', 63, _hrn, isIslamic: true),
  ];
}
