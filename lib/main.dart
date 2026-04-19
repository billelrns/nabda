import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(NabdaApp());
}

// ==================== APP ROOT ====================
class NabdaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '\u0646\u0628\u0636\u0629',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('ar', 'SA'), Locale('en', 'US')],
      locale: Locale('ar', 'SA'),
      home: AuthGate(),
    );
  }
}

// ==================== AUTH GATE ====================
class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        if (snap.hasData) return MainNav();
        return LoginPage();
      },
    );
  }
}

// ==================== FIRESTORE HELPER ====================
class DB {
  static String get uid => FirebaseAuth.instance.currentUser!.uid;
  static DocumentReference get userDoc =>
      FirebaseFirestore.instance.collection('users').doc(uid);
  static CollectionReference get cycleLogs =>
      userDoc.collection('cycle_logs');
  static CollectionReference get babyLogs =>
      userDoc.collection('baby_logs');

  static String dateKey([DateTime? d]) {
    final dt = d ?? DateTime.now();
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

// ==================== LOGIN PAGE ====================
class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailC = TextEditingController();
  final passC = TextEditingController();
  final nameC = TextEditingController();
  bool loading = false;
  String msg = '';
  bool isRegister = false;

  void doAuth() async {
    if (emailC.text.isEmpty || passC.text.isEmpty) {
      setState(() { msg = '\u064A\u0631\u062C\u0649 \u0645\u0644\u0621 \u062C\u0645\u064A\u0639 \u0627\u0644\u062D\u0642\u0648\u0644'; });
      return;
    }
    setState(() { loading = true; msg = ''; });
    try {
      if (isRegister) {
        var cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailC.text.trim(), password: passC.text);
        if (nameC.text.isNotEmpty) await cred.user?.updateDisplayName(nameC.text.trim());
        // Create initial user document in Firestore
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'name': nameC.text.trim(),
          'email': emailC.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'cycleLength': 28,
          'lastPeriodStart': null,
          'pregnancyStartDate': null,
          'babyName': '',
          'babyBirthDate': null,
        });
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailC.text.trim(), password: passC.text);
      }
    } catch (e) {
      String error = e.toString().split(']').last.trim();
      if (error.contains('user-not-found')) {
        error = '\u0644\u0627 \u064A\u0648\u062C\u062F \u062D\u0633\u0627\u0628 \u0628\u0647\u0630\u0627 \u0627\u0644\u0628\u0631\u064A\u062F';
      } else if (error.contains('wrong-password') || error.contains('invalid-credential')) {
        error = '\u0627\u0644\u0628\u0631\u064A\u062F \u0623\u0648 \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631 \u063A\u064A\u0631 \u0635\u062D\u064A\u062D\u0629';
      } else if (error.contains('email-already-in-use')) {
        error = '\u0647\u0630\u0627 \u0627\u0644\u0628\u0631\u064A\u062F \u0645\u0633\u062A\u062E\u062F\u0645 \u0628\u0627\u0644\u0641\u0639\u0644';
      } else if (error.contains('weak-password')) {
        error = '\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631 \u0636\u0639\u064A\u0641\u0629 \u062C\u062F\u0627\u064B';
      } else {
        error = '\u062D\u062F\u062B \u062E\u0637\u0623 \u063A\u064A\u0631 \u0645\u062A\u0648\u0642\u0639';
      }
      setState(() { msg = error; });
    }
    if (mounted) setState(() { loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 40),
                Icon(Icons.favorite, size: 80, color: Colors.teal),
                SizedBox(height: 12),
                Text('\u0646\u0628\u0636\u0629', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.teal)),
                Text('\u0635\u062D\u0629 \u0627\u0644\u0645\u0631\u0623\u0629 \u0627\u0644\u0639\u0631\u0628\u064A\u0629', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
                SizedBox(height: 40),
                if (isRegister) ...[
                  TextField(controller: nameC,
                    decoration: InputDecoration(labelText: '\u0627\u0644\u0627\u0633\u0645 \u0627\u0644\u0643\u0627\u0645\u0644', prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  SizedBox(height: 14),
                ],
                TextField(controller: emailC, keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(labelText: '\u0627\u0644\u0628\u0631\u064A\u062F \u0627\u0644\u0625\u0644\u0643\u062A\u0631\u0648\u0646\u064A', prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                SizedBox(height: 14),
                TextField(controller: passC, obscureText: true, textDirection: TextDirection.ltr,
                  decoration: InputDecoration(labelText: '\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631', prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                SizedBox(height: 20),
                if (msg.isNotEmpty) Padding(padding: EdgeInsets.only(bottom: 12),
                  child: Text(msg, style: TextStyle(color: Colors.red), textAlign: TextAlign.center)),
                ElevatedButton(
                  onPressed: loading ? null : doAuth,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: loading ? SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(isRegister ? '\u0625\u0646\u0634\u0627\u0621 \u062D\u0633\u0627\u0628' : '\u062A\u0633\u062C\u064A\u0644 \u0627\u0644\u062F\u062E\u0648\u0644', style: TextStyle(fontSize: 18))),
                SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() { isRegister = !isRegister; msg = ''; }),
                  child: Text(isRegister ? '\u0644\u062F\u064A\u0643 \u062D\u0633\u0627\u0628\u061F \u0633\u062C\u0651\u0644\u064A \u0627\u0644\u062F\u062E\u0648\u0644' : '\u0644\u064A\u0633 \u0644\u062F\u064A\u0643 \u062D\u0633\u0627\u0628\u061F \u0633\u062C\u0651\u0644\u064A \u0627\u0644\u0622\u0646',
                    style: TextStyle(fontSize: 15))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== MAIN NAVIGATION ====================
class MainNav extends StatefulWidget {
  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _index = 0;
  void goToTab(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final pages = [HomePage(onCardTap: goToTab), CyclePage(), PregnancyPage(), BabyPage(), ProfilePage()];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: pages[_index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            NavigationDestination(icon: Icon(Icons.home), label: '\u0627\u0644\u0631\u0626\u064A\u0633\u064A\u0629'),
            NavigationDestination(icon: Icon(Icons.calendar_month), label: '\u0627\u0644\u062F\u0648\u0631\u0629'),
            NavigationDestination(icon: Icon(Icons.pregnant_woman), label: '\u0627\u0644\u062D\u0645\u0644'),
            NavigationDestination(icon: Icon(Icons.child_care), label: '\u0627\u0644\u0637\u0641\u0644'),
            NavigationDestination(icon: Icon(Icons.person), label: '\u062D\u0633\u0627\u0628\u064A'),
          ],
        ),
      ),
    );
  }
}

// ==================== HOME PAGE ====================
class HomePage extends StatelessWidget {
  final Function(int)? onCardTap;
  const HomePage({this.onCardTap});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: Text('\u0646\u0628\u0636\u0629'), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: StreamBuilder<DocumentSnapshot>(
        stream: DB.userDoc.snapshots(),
        builder: (context, snapshot) {
          Map<String, dynamic> data = {};
          if (snapshot.hasData && snapshot.data!.exists) {
            data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          }
          int cycleDay = _calcCycleDay(data);
          int cycleLength = (data['cycleLength'] as int?) ?? 28;

          return SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('\u0645\u0631\u062D\u0628\u0627\u064B ${user?.displayName ?? ""}!',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('\u0643\u064A\u0641 \u062D\u0627\u0644\u0643 \u0627\u0644\u064A\u0648\u0645\u061F', style: TextStyle(fontSize: 16, color: Colors.grey)),
                SizedBox(height: 24),
                // Quick status card
                if (data['lastPeriodStart'] != null)
                  Container(
                    width: double.infinity, padding: EdgeInsets.all(16),
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.pink.shade300, Colors.pink.shade100]),
                      borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      Icon(Icons.calendar_today, color: Colors.white, size: 32),
                      SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('\u0627\u0644\u064A\u0648\u0645 $cycleDay \u0645\u0646 $cycleLength',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text(cycleDay <= 5 ? '\u0641\u062A\u0631\u0629 \u0627\u0644\u062F\u0648\u0631\u0629' :
                             cycleDay >= 10 && cycleDay <= 16 ? '\u0641\u062A\u0631\u0629 \u0627\u0644\u062E\u0635\u0648\u0628\u0629' :
                             '\u0641\u062A\u0631\u0629 \u0639\u0627\u062F\u064A\u0629',
                          style: TextStyle(color: Colors.white70)),
                      ]),
                    ]),
                  ),
                Row(children: [
                  _buildCard('\u0645\u062A\u0627\u0628\u0639\u0629\n\u0627\u0644\u062F\u0648\u0631\u0629', Icons.calendar_month, Colors.pink.shade100, Colors.pink, () => onCardTap?.call(1)),
                  SizedBox(width: 12),
                  _buildCard('\u0645\u062A\u0627\u0628\u0639\u0629\n\u0627\u0644\u062D\u0645\u0644', Icons.pregnant_woman, Colors.purple.shade100, Colors.purple, () => onCardTap?.call(2)),
                ]),
                SizedBox(height: 12),
                Row(children: [
                  _buildCard('\u0631\u0639\u0627\u064A\u0629\n\u0627\u0644\u0637\u0641\u0644', Icons.child_care, Colors.blue.shade100, Colors.blue, () => onCardTap?.call(3)),
                  SizedBox(width: 12),
                  _buildCard('\u0627\u0644\u0645\u0633\u0627\u0639\u062F\n\u0627\u0644\u0630\u0643\u064A', Icons.smart_toy, Colors.teal.shade100, Colors.teal, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AIChatPage()));
                  }),
                ]),
                SizedBox(height: 24),
                Text('\u0646\u0635\u0627\u0626\u062D \u0633\u0631\u064A\u0639\u0629', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                _tipCard('\u0627\u0634\u0631\u0628\u064A 8 \u0623\u0643\u0648\u0627\u0628 \u0645\u0627\u0621 \u064A\u0648\u0645\u064A\u0627\u064B \u0644\u0644\u062D\u0641\u0627\u0638 \u0639\u0644\u0649 \u0631\u0637\u0648\u0628\u0629 \u062C\u0633\u0645\u0643', Icons.water_drop, Colors.blue),
                SizedBox(height: 8),
                _tipCard('\u0627\u062D\u0635\u0644\u064A \u0639\u0644\u0649 7 \u0633\u0627\u0639\u0627\u062A \u0646\u0648\u0645 \u0639\u0644\u0649 \u0627\u0644\u0623\u0642\u0644 \u0643\u0644 \u0644\u064A\u0644\u0629', Icons.bedtime, Colors.indigo),
                SizedBox(height: 8),
                _tipCard('\u0627\u0645\u0634\u064A 30 \u062F\u0642\u064A\u0642\u0629 \u064A\u0648\u0645\u064A\u0627\u064B \u0644\u0635\u062D\u0629 \u0623\u0641\u0636\u0644', Icons.directions_walk, Colors.green),
              ],
            ),
          );
        },
      ),
    );
  }

  int _calcCycleDay(Map<String, dynamic> data) {
    if (data['lastPeriodStart'] == null) return 1;
    try {
      Timestamp ts = data['lastPeriodStart'];
      int diff = DateTime.now().difference(ts.toDate()).inDays + 1;
      int len = (data['cycleLength'] as int?) ?? 28;
      return ((diff - 1) % len) + 1;
    } catch (_) { return 1; }
  }

  Widget _buildCard(String title, IconData icon, Color bg, Color fg, VoidCallback? onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Icon(icon, size: 40, color: fg), SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: fg)),
          ]),
        ),
      ),
    );
  }

  Widget _tipCard(String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3))),
      child: Row(children: [
        Icon(icon, color: color), SizedBox(width: 12),
        Expanded(child: Text(text, style: TextStyle(fontSize: 14))),
      ]),
    );
  }
}

// ==================== CYCLE PAGE (FIRESTORE) ====================
class CyclePage extends StatefulWidget {
  @override
  State<CyclePage> createState() => _CyclePageState();
}

class _CyclePageState extends State<CyclePage> {
  String mood = '';
  List<String> symptoms = [];
  final allSymptoms = ['\u062A\u0634\u0646\u062C\u0627\u062A', '\u0635\u062F\u0627\u0639', '\u0625\u0631\u0647\u0627\u0642', '\u0627\u0646\u062A\u0641\u0627\u062E', '\u0622\u0644\u0627\u0645 \u0627\u0644\u0638\u0647\u0631', '\u062A\u0642\u0644\u0628\u0627\u062A \u0645\u0632\u0627\u062C\u064A\u0629'];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadTodayLog();
  }

  Future<void> _loadTodayLog() async {
    try {
      var doc = await DB.cycleLogs.doc(DB.dateKey()).get();
      if (doc.exists) {
        var d = doc.data() as Map<String, dynamic>;
        setState(() {
          mood = d['mood'] ?? '';
          symptoms = List<String>.from(d['symptoms'] ?? []);
        });
      }
    } catch (_) {}
    _loaded = true;
  }

  Future<void> _saveTodayLog() async {
    await DB.cycleLogs.doc(DB.dateKey()).set({
      'date': DB.dateKey(),
      'mood': mood,
      'symptoms': symptoms,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _startPeriod() async {
    await DB.userDoc.set({'lastPeriodStart': Timestamp.now()}, SetOptions(merge: true));
    await DB.cycleLogs.doc(DB.dateKey()).set({
      'date': DB.dateKey(),
      'isPeriod': true,
      'mood': mood,
      'symptoms': symptoms,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('\u062A\u0645 \u062A\u0633\u062C\u064A\u0644 \u0628\u062F\u0627\u064A\u0629 \u0627\u0644\u062F\u0648\u0631\u0629'), backgroundColor: Colors.pink));
    }
  }

  Future<void> _endPeriod() async {
    await DB.cycleLogs.doc(DB.dateKey()).set({
      'date': DB.dateKey(),
      'isPeriod': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('\u062A\u0645 \u062A\u0633\u062C\u064A\u0644 \u0646\u0647\u0627\u064A\u0629 \u0627\u0644\u062F\u0648\u0631\u0629'), backgroundColor: Colors.grey));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('\u0645\u062A\u0627\u0628\u0639\u0629 \u0627\u0644\u062F\u0648\u0631\u0629'), backgroundColor: Colors.pink, foregroundColor: Colors.white),
      body: StreamBuilder<DocumentSnapshot>(
        stream: DB.userDoc.snapshots(),
        builder: (context, snapshot) {
          int cycleLength = 28;
          int cycleDay = 1;
          if (snapshot.hasData && snapshot.data!.exists) {
            var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            cycleLength = (data['cycleLength'] as int?) ?? 28;
            if (data['lastPeriodStart'] != null) {
              try {
                Timestamp ts = data['lastPeriodStart'];
                int diff = DateTime.now().difference(ts.toDate()).inDays + 1;
                cycleDay = ((diff - 1) % cycleLength) + 1;
              } catch (_) {}
            }
          }
          double progress = cycleDay / cycleLength;

          return SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(children: [
              // Circular progress
              Container(
                width: 200, height: 200,
                child: Stack(alignment: Alignment.center, children: [
                  SizedBox(width: 180, height: 180,
                    child: CircularProgressIndicator(value: progress, strokeWidth: 12,
                      backgroundColor: Colors.pink.shade50, color: Colors.pink)),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('\u0627\u0644\u064A\u0648\u0645 $cycleDay', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.pink)),
                    Text('\u0645\u0646 $cycleLength \u064A\u0648\u0645', style: TextStyle(color: Colors.grey)),
                  ]),
                ]),
              ),
              SizedBox(height: 24),
              // Action buttons
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _cycleBtn('\u0628\u062F\u0627\u064A\u0629 \u0627\u0644\u062F\u0648\u0631\u0629', Icons.play_arrow, Colors.red, _startPeriod),
                _cycleBtn('\u0646\u0647\u0627\u064A\u0629 \u0627\u0644\u062F\u0648\u0631\u0629', Icons.stop, Colors.grey, _endPeriod),
                _cycleBtn('\u062D\u0641\u0638 \u0627\u0644\u064A\u0648\u0645', Icons.save, Colors.pink, () async {
                  await _saveTodayLog();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('\u062A\u0645 \u062D\u0641\u0638 \u0628\u064A\u0627\u0646\u0627\u062A \u0627\u0644\u064A\u0648\u0645'), backgroundColor: Colors.green));
                }),
              ]),
              SizedBox(height: 24),
              // Mood
              Align(alignment: Alignment.centerRight,
                child: Text('\u0627\u0644\u0645\u0632\u0627\u062C \u0627\u0644\u064A\u0648\u0645', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _moodBtn('\u0645\u0645\u062A\u0627\u0632', '\u{1F60A}'), _moodBtn('\u062C\u064A\u062F', '\u{1F642}'),
                _moodBtn('\u0639\u0627\u062F\u064A', '\u{1F610}'), _moodBtn('\u0633\u064A\u0626', '\u{1F622}'), _moodBtn('\u0633\u064A\u0626 \u062C\u062F\u0627\u064B', '\u{1F62B}'),
              ]),
              SizedBox(height: 24),
              // Symptoms
              Align(alignment: Alignment.centerRight,
                child: Text('\u0627\u0644\u0623\u0639\u0631\u0627\u0636', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: allSymptoms.map((s) =>
                FilterChip(
                  label: Text(s),
                  selected: symptoms.contains(s),
                  onSelected: (v) => setState(() { v ? symptoms.add(s) : symptoms.remove(s); }),
                  selectedColor: Colors.pink.shade100,
                )).toList()),
              SizedBox(height: 24),
              // Cycle insights
              Container(
                width: double.infinity, padding: EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.pink.shade50, borderRadius: BorderRadius.circular(12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('\u0645\u0639\u0644\u0648\u0645\u0627\u062A \u0627\u0644\u062F\u0648\u0631\u0629', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('\u0627\u0644\u062F\u0648\u0631\u0629 \u0627\u0644\u0642\u0627\u062F\u0645\u0629: \u0628\u0639\u062F ~${cycleLength - cycleDay} \u064A\u0648\u0645'),
                  Text('\u0641\u062A\u0631\u0629 \u0627\u0644\u062E\u0635\u0648\u0628\u0629: \u0627\u0644\u064A\u0648\u0645 ${(cycleLength * 0.36).round()}-${(cycleLength * 0.57).round()}'),
                  Text('\u0627\u0644\u0625\u0628\u0627\u0636\u0629: ~\u0627\u0644\u064A\u0648\u0645 ${(cycleLength * 0.5).round()}'),
                ]),
              ),
              SizedBox(height: 16),
              // Cycle length setting
              Container(
                width: double.infinity, padding: EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Text('\u0637\u0648\u0644 \u0627\u0644\u062F\u0648\u0631\u0629:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Spacer(),
                  IconButton(icon: Icon(Icons.remove_circle_outline, color: Colors.pink),
                    onPressed: () async {
                      if (cycleLength > 20) {
                        await DB.userDoc.set({'cycleLength': cycleLength - 1}, SetOptions(merge: true));
                      }
                    }),
                  Text('$cycleLength \u064A\u0648\u0645', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: Icon(Icons.add_circle_outline, color: Colors.pink),
                    onPressed: () async {
                      if (cycleLength < 45) {
                        await DB.userDoc.set({'cycleLength': cycleLength + 1}, SetOptions(merge: true));
                      }
                    }),
                ]),
              ),
            ]),
          );
        },
      ),
    );
  }

  Widget _cycleBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        CircleAvatar(radius: 24, backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color)),
        SizedBox(height: 4), Text(label, style: TextStyle(fontSize: 11)),
      ]),
    );
  }

  Widget _moodBtn(String label, String emoji) {
    bool sel = mood == label;
    return GestureDetector(
      onTap: () => setState(() => mood = label),
      child: Column(children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: sel ? Colors.pink.shade100 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: sel ? Border.all(color: Colors.pink, width: 2) : null),
          child: Text(emoji, style: TextStyle(fontSize: 28))),
        SizedBox(height: 4), Text(label, style: TextStyle(fontSize: 11)),
      ]),
    );
  }
}

// ==================== PREGNANCY PAGE (FIRESTORE) ====================
class PregnancyPage extends StatefulWidget {
  @override
  State<PregnancyPage> createState() => _PregnancyPageState();
}

class _PregnancyPageState extends State<PregnancyPage> {
  int kickCount = 0;
  bool counting = false;
  Map<String, bool> checklist = {};

  // Baby development data by week
  static const weekData = {
    4: ['\u0628\u062D\u062C\u0645 \u0628\u0630\u0631\u0629 \u0627\u0644\u062E\u0634\u062E\u0627\u0634', '0.4 \u063A\u0631\u0627\u0645', '\u064A\u0628\u062F\u0623 \u0627\u0644\u0642\u0644\u0628 \u0628\u0627\u0644\u0646\u0628\u0636'],
    8: ['\u0628\u062D\u062C\u0645 \u062D\u0628\u0629 \u0627\u0644\u062A\u0648\u062A', '1 \u063A\u0631\u0627\u0645', '\u062A\u062A\u0634\u0643\u0644 \u0627\u0644\u0623\u0635\u0627\u0628\u0639'],
    12: ['\u0628\u062D\u062C\u0645 \u0627\u0644\u0644\u064A\u0645\u0648\u0646\u0629', '14 \u063A\u0631\u0627\u0645', '\u062A\u062A\u0634\u0643\u0644 \u0627\u0644\u0623\u0639\u0636\u0627\u0621'],
    16: ['\u0628\u062D\u062C\u0645 \u0627\u0644\u0623\u0641\u0648\u0643\u0627\u062F\u0648', '100 \u063A\u0631\u0627\u0645', '\u064A\u0628\u062F\u0623 \u0628\u0627\u0644\u062D\u0631\u0643\u0629'],
    20: ['\u0628\u062D\u062C\u0645 \u0627\u0644\u0645\u0648\u0632\u0629', '300 \u063A\u0631\u0627\u0645', '\u064A\u0633\u0645\u0639 \u0627\u0644\u0623\u0635\u0648\u0627\u062A'],
    24: ['\u0628\u062D\u062C\u0645 \u0643\u0648\u0632 \u0627\u0644\u0630\u0631\u0629', '600 \u063A\u0631\u0627\u0645', '\u064A\u0633\u062A\u062C\u064A\u0628 \u0644\u0644\u0636\u0648\u0621'],
    28: ['\u0628\u062D\u062C\u0645 \u0627\u0644\u0628\u0627\u0630\u0646\u062C\u0627\u0646', '1 \u0643\u063A', '\u064A\u0641\u062A\u062D \u0639\u064A\u0646\u064A\u0647'],
    32: ['\u0628\u062D\u062C\u0645 \u0627\u0644\u0628\u0637\u064A\u062E\u0629 \u0627\u0644\u0635\u063A\u064A\u0631\u0629', '1.7 \u0643\u063A', '\u064A\u062A\u0646\u0641\u0633 \u0628\u0627\u0646\u062A\u0638\u0627\u0645'],
    36: ['\u0628\u062D\u062C\u0645 \u0627\u0644\u0634\u0645\u0627\u0645', '2.6 \u0643\u063A', '\u0627\u0644\u0631\u0626\u062A\u0627\u0646 \u0645\u0643\u062A\u0645\u0644\u062A\u0627\u0646'],
    40: ['\u0628\u062D\u062C\u0645 \u0627\u0644\u0628\u0637\u064A\u062E\u0629', '3.4 \u0643\u063A', '\u062C\u0627\u0647\u0632 \u0644\u0644\u0648\u0644\u0627\u062F\u0629!'],
  };

  List<String> _getWeekInfo(int week) {
    int closest = weekData.keys.reduce((a, b) => (a - week).abs() <= (b - week).abs() ? a : b);
    return weekData[closest]!;
  }

  Future<void> _setPregnancyStart() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(Duration(days: 7 * 20)),
      firstDate: DateTime.now().subtract(Duration(days: 280)),
      lastDate: DateTime.now(),
      helpText: '\u0627\u062E\u062A\u0627\u0631\u064A \u062A\u0627\u0631\u064A\u062E \u0622\u062E\u0631 \u062F\u0648\u0631\u0629',
    );
    if (date != null) {
      await DB.userDoc.set({'pregnancyStartDate': Timestamp.fromDate(date)}, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('\u0645\u062A\u0627\u0628\u0639\u0629 \u0627\u0644\u062D\u0645\u0644'),
        backgroundColor: Colors.purple, foregroundColor: Colors.white,
        actions: [
          IconButton(icon: Icon(Icons.date_range), onPressed: _setPregnancyStart,
            tooltip: '\u062A\u062D\u062F\u064A\u062F \u062A\u0627\u0631\u064A\u062E \u0622\u062E\u0631 \u062F\u0648\u0631\u0629'),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: DB.userDoc.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _noPregnancy();
          }
          var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          if (data['pregnancyStartDate'] == null) return _noPregnancy();

          Timestamp ts = data['pregnancyStartDate'];
          int daysSinceLastPeriod = DateTime.now().difference(ts.toDate()).inDays;
          int week = (daysSinceLastPeriod / 7).floor();
          if (week < 1) week = 1;
          if (week > 42) week = 42;
          int daysLeft = (40 * 7) - daysSinceLastPeriod;
          if (daysLeft < 0) daysLeft = 0;
          double percent = (week / 40).clamp(0.0, 1.0);
          List<String> info = _getWeekInfo(week);

          return SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(children: [
              // Week header
              Container(
                width: double.infinity, padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.purple.shade300, Colors.purple.shade100]),
                  borderRadius: BorderRadius.circular(20)),
                child: Column(children: [
                  Text('\u0627\u0644\u0623\u0633\u0628\u0648\u0639 $week', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('$daysLeft \u064A\u0648\u0645 \u0645\u062A\u0628\u0642\u064A', style: TextStyle(fontSize: 16, color: Colors.white70)),
                  SizedBox(height: 12),
                  LinearProgressIndicator(value: percent, backgroundColor: Colors.white30, color: Colors.white, minHeight: 8),
                  SizedBox(height: 8),
                  Text('${(percent * 100).toInt()}% \u0645\u0643\u062A\u0645\u0644', style: TextStyle(color: Colors.white70)),
                ]),
              ),
              SizedBox(height: 20),
              _infoCard('\u062D\u062C\u0645 \u0627\u0644\u062C\u0646\u064A\u0646', info[0], Icons.straighten, Colors.orange),
              SizedBox(height: 12),
              _infoCard('\u0648\u0632\u0646 \u0627\u0644\u062C\u0646\u064A\u0646', info[1], Icons.monitor_weight, Colors.blue),
              SizedBox(height: 12),
              _infoCard('\u0627\u0644\u062A\u0637\u0648\u0631', info[2], Icons.hearing, Colors.green),
              SizedBox(height: 20),
              // Checklist from Firestore
              Text('\u0642\u0627\u0626\u0645\u0629 \u0627\u0644\u0645\u0647\u0627\u0645 \u0627\u0644\u0623\u0633\u0628\u0648\u0639\u064A\u0629', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              _interactiveCheck('\u062A\u0646\u0627\u0648\u0644 \u0641\u064A\u062A\u0627\u0645\u064A\u0646\u0627\u062A \u0645\u0627 \u0642\u0628\u0644 \u0627\u0644\u0648\u0644\u0627\u062F\u0629', 'vitamins'),
              _interactiveCheck('\u0634\u0631\u0628 \u0643\u0645\u064A\u0629 \u0643\u0627\u0641\u064A\u0629 \u0645\u0646 \u0627\u0644\u0645\u0627\u0621', 'water'),
              _interactiveCheck('\u062D\u062C\u0632 \u0645\u0648\u0639\u062F \u0641\u062D\u0635 \u0627\u0644\u0633\u0643\u0631', 'glucose'),
              _interactiveCheck('\u0645\u0645\u0627\u0631\u0633\u0629 \u062A\u0645\u0627\u0631\u064A\u0646 \u0627\u0644\u062A\u0646\u0641\u0633', 'breathing'),
              _interactiveCheck('\u0627\u0644\u0645\u0634\u064A 30 \u062F\u0642\u064A\u0642\u0629', 'walking'),
              SizedBox(height: 20),
              // Kick counter
              Container(
                width: double.infinity, padding: EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  Text('\u0639\u062F\u0627\u062F \u062D\u0631\u0643\u0627\u062A \u0627\u0644\u062C\u0646\u064A\u0646', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 12),
                  Text('$kickCount', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.purple)),
                  Text('\u062D\u0631\u0643\u0629', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    ElevatedButton.icon(
                      onPressed: () => setState(() => kickCount++),
                      icon: Icon(Icons.touch_app), label: Text('\u0631\u0643\u0644\u0629!'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white)),
                    SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () async {
                        await DB.userDoc.collection('kick_logs').doc(DB.dateKey()).set({
                          'count': kickCount, 'date': DB.dateKey(), 'updatedAt': FieldValue.serverTimestamp()
                        });
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('\u062A\u0645 \u062D\u0641\u0638 $kickCount \u062D\u0631\u0643\u0629'), backgroundColor: Colors.purple));
                        setState(() => kickCount = 0);
                      },
                      child: Text('\u062D\u0641\u0638 \u0648\u0625\u0639\u0627\u062F\u0629')),
                  ]),
                ]),
              ),
            ]),
          );
        },
      ),
    );
  }

  Widget _noPregnancy() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.pregnant_woman, size: 80, color: Colors.purple.shade200),
          SizedBox(height: 20),
          Text('\u0644\u0645 \u064A\u062A\u0645 \u062A\u062D\u062F\u064A\u062F \u062A\u0627\u0631\u064A\u062E \u0627\u0644\u062D\u0645\u0644',
            style: TextStyle(fontSize: 18, color: Colors.grey), textAlign: TextAlign.center),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _setPregnancyStart,
            icon: Icon(Icons.date_range),
            label: Text('\u062D\u062F\u062F\u064A \u062A\u0627\u0631\u064A\u062E \u0622\u062E\u0631 \u062F\u0648\u0631\u0629'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white)),
        ]),
      ),
    );
  }

  Widget _interactiveCheck(String text, String key) {
    return StreamBuilder<DocumentSnapshot>(
      stream: DB.userDoc.collection('weekly_checklist').doc('${DB.dateKey().substring(0, 7)}_$key').snapshots(),
      builder: (context, snap) {
        bool done = false;
        if (snap.hasData && snap.data!.exists) {
          done = (snap.data!.data() as Map<String, dynamic>?)?['done'] ?? false;
        }
        return InkWell(
          onTap: () {
            DB.userDoc.collection('weekly_checklist').doc('${DB.dateKey().substring(0, 7)}_$key').set({
              'text': text, 'done': !done, 'key': key, 'updatedAt': FieldValue.serverTimestamp()
            });
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Icon(done ? Icons.check_circle : Icons.circle_outlined,
                color: done ? Colors.green : Colors.grey, size: 28),
              SizedBox(width: 10),
              Expanded(child: Text(text, style: TextStyle(
                fontSize: 15,
                decoration: done ? TextDecoration.lineThrough : null,
                color: done ? Colors.grey : Colors.black))),
            ]),
          ),
        );
      },
    );
  }

  Widget _infoCard(String title, String desc, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, color: color, size: 36), SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(desc, style: TextStyle(color: Colors.grey.shade700)),
        ])),
      ]),
    );
  }
}

// ==================== BABY PAGE (FIRESTORE) ====================
class BabyPage extends StatefulWidget {
  @override
  State<BabyPage> createState() => _BabyPageState();
}

class _BabyPageState extends State<BabyPage> {
  Future<void> _setBabyInfo() async {
    final nameC = TextEditingController();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('\u0645\u0639\u0644\u0648\u0645\u0627\u062A \u0627\u0644\u0637\u0641\u0644'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameC,
            decoration: InputDecoration(labelText: '\u0627\u0633\u0645 \u0627\u0644\u0637\u0641\u0644',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final date = await showDatePicker(
                context: ctx,
                initialDate: DateTime.now().subtract(Duration(days: 90)),
                firstDate: DateTime.now().subtract(Duration(days: 365 * 3)),
                lastDate: DateTime.now(),
                helpText: '\u062A\u0627\u0631\u064A\u062E \u0627\u0644\u0645\u064A\u0644\u0627\u062F',
              );
              if (date != null) {
                Navigator.pop(ctx, {'name': nameC.text, 'birthDate': date});
              }
            },
            child: Text('\u0627\u062E\u062A\u0627\u0631\u064A \u062A\u0627\u0631\u064A\u062E \u0627\u0644\u0645\u064A\u0644\u0627\u062F'),
          ),
        ]),
      ),
    );
    if (result != null) {
      await DB.userDoc.set({
        'babyName': result['name'],
        'babyBirthDate': Timestamp.fromDate(result['birthDate']),
      }, SetOptions(merge: true));
    }
  }

  Future<void> _addLog(String type) async {
    final doc = DB.babyLogs.doc(DB.dateKey());
    final snap = await doc.get();
    Map<String, dynamic> data = {};
    if (snap.exists) data = snap.data() as Map<String, dynamic>? ?? {};

    int current = (data[type] as int?) ?? 0;
    data[type] = current + 1;
    data['date'] = DB.dateKey();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await doc.set(data, SetOptions(merge: true));
  }

  Future<void> _updateGrowth(String field, double value) async {
    await DB.userDoc.set({
      'baby_$field': value,
      'baby_${field}_date': DB.dateKey(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('\u0631\u0639\u0627\u064A\u0629 \u0627\u0644\u0637\u0641\u0644'),
        backgroundColor: Colors.blue, foregroundColor: Colors.white,
        actions: [
          IconButton(icon: Icon(Icons.edit), onPressed: _setBabyInfo,
            tooltip: '\u062A\u0639\u062F\u064A\u0644 \u0645\u0639\u0644\u0648\u0645\u0627\u062A \u0627\u0644\u0637\u0641\u0644'),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: DB.userDoc.snapshots(),
        builder: (context, userSnap) {
          Map<String, dynamic> userData = {};
          if (userSnap.hasData && userSnap.data!.exists) {
            userData = userSnap.data!.data() as Map<String, dynamic>? ?? {};
          }
          String babyName = userData['babyName'] ?? '';
          String ageText = '';
          if (userData['babyBirthDate'] != null) {
            try {
              Timestamp ts = userData['babyBirthDate'];
              int days = DateTime.now().difference(ts.toDate()).inDays;
              if (days < 30) ageText = '$days \u064A\u0648\u0645';
              else if (days < 365) ageText = '${(days / 30).floor()} \u0623\u0634\u0647\u0631';
              else ageText = '${(days / 365).floor()} \u0633\u0646\u0629 \u0648 ${((days % 365) / 30).floor()} \u0623\u0634\u0647\u0631';
            } catch (_) {}
          }
          double weight = (userData['baby_weight'] as num?)?.toDouble() ?? 0;
          double height = (userData['baby_height'] as num?)?.toDouble() ?? 0;

          if (babyName.isEmpty && userData['babyBirthDate'] == null) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.child_care, size: 80, color: Colors.blue.shade200),
                  SizedBox(height: 20),
                  Text('\u0644\u0645 \u064A\u062A\u0645 \u0625\u0636\u0627\u0641\u0629 \u0645\u0639\u0644\u0648\u0645\u0627\u062A \u0627\u0644\u0637\u0641\u0644',
                    style: TextStyle(fontSize: 18, color: Colors.grey), textAlign: TextAlign.center),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _setBabyInfo,
                    icon: Icon(Icons.add),
                    label: Text('\u0623\u0636\u064A\u0641\u064A \u0645\u0639\u0644\u0648\u0645\u0627\u062A \u0627\u0644\u0637\u0641\u0644'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white)),
                ]),
              ),
            );
          }

          return StreamBuilder<DocumentSnapshot>(
            stream: DB.babyLogs.doc(DB.dateKey()).snapshots(),
            builder: (context, logSnap) {
              Map<String, dynamic> log = {};
              if (logSnap.hasData && logSnap.data!.exists) {
                log = logSnap.data!.data() as Map<String, dynamic>? ?? {};
              }
              int feeding = (log['feeding'] as int?) ?? 0;
              int sleep = (log['sleep'] as int?) ?? 0;
              int diaper = (log['diaper'] as int?) ?? 0;

              return SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Baby header
                  Container(
                    width: double.infinity, padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.blue.shade300, Colors.blue.shade100]),
                      borderRadius: BorderRadius.circular(20)),
                    child: Row(children: [
                      Icon(Icons.child_care, size: 60, color: Colors.white),
                      SizedBox(width: 16),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(babyName.isEmpty ? '\u0637\u0641\u0644\u064A' : babyName,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        if (ageText.isNotEmpty)
                          Text('\u0627\u0644\u0639\u0645\u0631: $ageText', style: TextStyle(color: Colors.white70)),
                      ]),
                    ]),
                  ),
                  SizedBox(height: 20),
                  // Growth
                  Text('\u0645\u062A\u0627\u0628\u0639\u0629 \u0627\u0644\u0646\u0645\u0648', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Row(children: [
                    _growthCard('\u0627\u0644\u0648\u0632\u0646', weight > 0 ? '${weight.toStringAsFixed(1)} \u0643\u063A' : '-- \u0643\u063A',
                      Icons.monitor_weight, Colors.orange, () => _showGrowthInput('\u0627\u0644\u0648\u0632\u0646 (\u0643\u063A)', 'weight')),
                    SizedBox(width: 12),
                    _growthCard('\u0627\u0644\u0637\u0648\u0644', height > 0 ? '${height.toStringAsFixed(0)} \u0633\u0645' : '-- \u0633\u0645',
                      Icons.height, Colors.green, () => _showGrowthInput('\u0627\u0644\u0637\u0648\u0644 (\u0633\u0645)', 'height')),
                  ]),
                  SizedBox(height: 20),
                  // Daily log
                  Text('\u0627\u0644\u0633\u062C\u0644 \u0627\u0644\u064A\u0648\u0645\u064A', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  _logItem('\u0627\u0644\u0631\u0636\u0627\u0639\u0629', '$feeding \u0645\u0631\u0629', Icons.restaurant, Colors.orange, () => _addLog('feeding')),
                  _logItem('\u0627\u0644\u0646\u0648\u0645', '$sleep \u0633\u0627\u0639\u0629', Icons.bedtime, Colors.indigo, () => _addLog('sleep')),
                  _logItem('\u0627\u0644\u062D\u0641\u0627\u0636', '$diaper \u062A\u063A\u064A\u064A\u0631', Icons.baby_changing_station, Colors.teal, () => _addLog('diaper')),
                  SizedBox(height: 20),
                  // Vaccines
                  Text('\u0627\u0644\u062A\u0637\u0639\u064A\u0645\u0627\u062A', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  _vaccineItem('\u0644\u0642\u0627\u062D \u0627\u0644\u062A\u0647\u0627\u0628 \u0627\u0644\u0643\u0628\u062F \u0628', 'hepb'),
                  _vaccineItem('\u0644\u0642\u0627\u062D BCG', 'bcg'),
                  _vaccineItem('\u0627\u0644\u0644\u0642\u0627\u062D \u0627\u0644\u062B\u0644\u0627\u062B\u064A', 'dtap'),
                  _vaccineItem('\u0644\u0642\u0627\u062D \u0634\u0644\u0644 \u0627\u0644\u0623\u0637\u0641\u0627\u0644', 'polio'),
                  _vaccineItem('\u0644\u0642\u0627\u062D \u0627\u0644\u062D\u0635\u0628\u0629', 'mmr'),
                ]),
              );
            },
          );
        },
      ),
    );
  }

  void _showGrowthInput(String label, String field) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('\u0625\u0644\u063A\u0627\u0621')),
          ElevatedButton(
            onPressed: () {
              double? val = double.tryParse(controller.text);
              if (val != null) {
                _updateGrowth(field, val);
                Navigator.pop(ctx);
              }
            },
            child: Text('\u062D\u0641\u0638')),
        ],
      ),
    );
  }

  Widget _growthCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Icon(icon, color: color, size: 32), SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: TextStyle(color: Colors.grey)),
            SizedBox(height: 4),
            Text('\u0627\u0636\u063A\u0637\u064A \u0644\u0644\u062A\u062D\u062F\u064A\u062B', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ]),
        ),
      ),
    );
  }

  Widget _logItem(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color, size: 20)),
            SizedBox(width: 14),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            Spacer(),
            Text(value, style: TextStyle(color: Colors.grey.shade700)),
            SizedBox(width: 8),
            Icon(Icons.add_circle, color: color, size: 24),
          ]),
        ),
      ),
    );
  }

  Widget _vaccineItem(String name, String key) {
    return StreamBuilder<DocumentSnapshot>(
      stream: DB.userDoc.collection('vaccines').doc(key).snapshots(),
      builder: (context, snap) {
        bool done = false;
        if (snap.hasData && snap.data!.exists) {
          done = (snap.data!.data() as Map<String, dynamic>?)?['done'] ?? false;
        }
        return InkWell(
          onTap: () {
            DB.userDoc.collection('vaccines').doc(key).set({
              'name': name, 'done': !done, 'updatedAt': FieldValue.serverTimestamp()
            });
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: done ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Icon(done ? Icons.check_circle : Icons.schedule,
                  color: done ? Colors.green : Colors.orange),
                SizedBox(width: 10),
                Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
                Spacer(),
                Text(done ? '\u0645\u0643\u062A\u0645\u0644' : '\u0642\u0627\u062F\u0645',
                  style: TextStyle(fontSize: 12, color: done ? Colors.green : Colors.orange)),
              ]),
            ),
          ),
        );
      },
    );
  }
}

// ==================== PROFILE PAGE (FIRESTORE) ====================
class ProfilePage extends StatelessWidget {
  Future<void> _editName(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final controller = TextEditingController(text: user?.displayName ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('\u062A\u0639\u062F\u064A\u0644 \u0627\u0644\u0627\u0633\u0645'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: '\u0627\u0644\u0627\u0633\u0645', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('\u0625\u0644\u063A\u0627\u0621')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text), child: Text('\u062D\u0641\u0638')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await user?.updateDisplayName(result);
      await DB.userDoc.set({'name': result}, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: Text('\u062D\u0633\u0627\u0628\u064A'), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: StreamBuilder<DocumentSnapshot>(
        stream: DB.userDoc.snapshots(),
        builder: (context, snapshot) {
          String name = user?.displayName ?? '\u0645\u0633\u062A\u062E\u062F\u0645\u0629';
          if (snapshot.hasData && snapshot.data!.exists) {
            var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            if (data['name'] != null && (data['name'] as String).isNotEmpty) {
              name = data['name'];
            }
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(children: [
              SizedBox(height: 20),
              CircleAvatar(radius: 50, backgroundColor: Colors.teal.shade100,
                child: Icon(Icons.person, size: 60, color: Colors.teal)),
              SizedBox(height: 12),
              Text(name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(user?.email ?? '', style: TextStyle(color: Colors.grey)),
              SizedBox(height: 30),
              _menuItem('\u062A\u0639\u062F\u064A\u0644 \u0627\u0644\u0627\u0633\u0645', Icons.edit, Colors.teal, () => _editName(context)),
              _menuItem('\u0625\u0639\u0627\u062F\u0629 \u062A\u0639\u064A\u064A\u0646 \u0627\u0644\u0628\u064A\u0627\u0646\u0627\u062A', Icons.refresh, Colors.orange, () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('\u062A\u0623\u0643\u064A\u062F'),
                    content: Text('\u0647\u0644 \u062A\u0631\u064A\u062F\u064A\u0646 \u062D\u0630\u0641 \u062C\u0645\u064A\u0639 \u0627\u0644\u0628\u064A\u0627\u0646\u0627\u062A\u061F \u0644\u0627 \u064A\u0645\u0643\u0646 \u0627\u0644\u062A\u0631\u0627\u062C\u0639'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('\u0625\u0644\u063A\u0627\u0621')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        child: Text('\u062D\u0630\u0641')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await DB.userDoc.set({
                    'lastPeriodStart': null,
                    'pregnancyStartDate': null,
                    'babyName': '',
                    'babyBirthDate': null,
                    'baby_weight': null,
                    'baby_height': null,
                  }, SetOptions(merge: true));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('\u062A\u0645 \u0625\u0639\u0627\u062F\u0629 \u062A\u0639\u064A\u064A\u0646 \u0627\u0644\u0628\u064A\u0627\u0646\u0627\u062A'), backgroundColor: Colors.orange));
                  }
                }
              }),
              _menuItem('\u0627\u0644\u0625\u0634\u0639\u0627\u0631\u0627\u062A', Icons.notifications, Colors.blue, null),
              _menuItem('\u0627\u0644\u062E\u0635\u0648\u0635\u064A\u0629', Icons.lock, Colors.purple, null),
              _menuItem('\u0627\u0644\u0645\u0633\u0627\u0639\u062F\u0629', Icons.help, Colors.green, null),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  icon: Icon(Icons.logout),
                  label: Text('\u062A\u0633\u062C\u064A\u0644 \u0627\u0644\u062E\u0631\u0648\u062C', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }

  Widget _menuItem(String title, IconData icon, Color color, VoidCallback? onTap) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
        title: Text(title),
        trailing: Icon(Icons.chevron_left),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: Colors.grey.shade50,
      ),
    );
  }
}

// ==================== AI CHAT PAGE (GEMINI) ====================
class AIChatPage extends StatefulWidget {
  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, String>> messages = [];
  List<Map<String, dynamic>> _chatHistory = [];
  bool _isLoading = false;
  final String _apiKey = 'AIzaSyB09gZH8igVPtC0yfPA5Twfp3KU0dC-kTI';

  // Quick suggestion buttons
  final quickQuestions = [
    '\u0645\u0627 \u0647\u064A \u0623\u0639\u0631\u0627\u0636 \u0627\u0644\u062D\u0645\u0644 \u0627\u0644\u0645\u0628\u0643\u0631\u061F',
    '\u0643\u064A\u0641 \u0623\u062E\u0641\u0641 \u0622\u0644\u0627\u0645 \u0627\u0644\u062F\u0648\u0631\u0629\u061F',
    '\u0645\u0627 \u0647\u064A \u0627\u0644\u0623\u0637\u0639\u0645\u0629 \u0627\u0644\u0645\u0641\u064A\u062F\u0629 \u0644\u0644\u062D\u0627\u0645\u0644\u061F',
    '\u0643\u064A\u0641 \u0623\u0639\u062A\u0646\u064A \u0628\u0637\u0641\u0644\u064A \u0627\u0644\u0631\u0636\u064A\u0639\u061F',
    '\u0645\u062A\u0649 \u064A\u062C\u0628 \u0632\u064A\u0627\u0631\u0629 \u0627\u0644\u0637\u0628\u064A\u0628\u061F',
    '\u0646\u0635\u0627\u0626\u062D \u0644\u0644\u0631\u0636\u0627\u0639\u0629 \u0627\u0644\u0637\u0628\u064A\u0639\u064A\u0629',
  ];

  @override
  void initState() {
    super.initState();
    // Welcome message
    messages.add({
      'role': 'assistant',
      'text': '\u0645\u0631\u062D\u0628\u0627\u064B! \u0623\u0646\u0627 \u0627\u0644\u0645\u0633\u0627\u0639\u062F \u0627\u0644\u0630\u0643\u064A \u0644\u062A\u0637\u0628\u064A\u0642 \u0646\u0628\u0636\u0629. \u064A\u0645\u0643\u0646\u0646\u064A \u0645\u0633\u0627\u0639\u062F\u062A\u0643 \u0641\u064A \u0623\u0633\u0626\u0644\u0629 \u0635\u062D\u0629 \u0627\u0644\u0645\u0631\u0623\u0629 \u0648\u0627\u0644\u062D\u0645\u0644 \u0648\u0631\u0639\u0627\u064A\u0629 \u0627\u0644\u0637\u0641\u0644.\n\n\u0627\u062E\u062A\u0627\u0631\u064A \u0633\u0624\u0627\u0644\u0627\u064B \u0623\u0648 \u0627\u0643\u062A\u0628\u064A \u0633\u0624\u0627\u0644\u0643 \u0628\u0627\u0644\u0623\u0633\u0641\u0644 \u{1F49C}',
    });
  }

  // ===== Smart Health Knowledge Base =====
  static final Map<String, String> _healthKB = {
    // Period / Cycle
    '\u0622\u0644\u0627\u0645 \u0627\u0644\u062F\u0648\u0631\u0629|\u062A\u0634\u0646\u062C\u0627\u062A|\u0623\u0644\u0645 \u0627\u0644\u062F\u0648\u0631\u0629|\u062A\u062E\u0641\u064A\u0641 \u0627\u0644\u062F\u0648\u0631\u0629':
      '\u0644\u062A\u062E\u0641\u064A\u0641 \u0622\u0644\u0627\u0645 \u0627\u0644\u062F\u0648\u0631\u0629 \u0627\u0644\u0634\u0647\u0631\u064A\u0629:\n\n\u2022 \u0636\u0639\u064A \u0643\u0645\u0627\u062F\u0629 \u062F\u0627\u0641\u0626\u0629 \u0639\u0644\u0649 \u0623\u0633\u0641\u0644 \u0627\u0644\u0628\u0637\u0646 \u0644\u0645\u062F\u0629 15-20 \u062F\u0642\u064A\u0642\u0629\n\u2022 \u0645\u0627\u0631\u0633\u064A \u0631\u064A\u0627\u0636\u0629 \u062E\u0641\u064A\u0641\u0629 \u0643\u0627\u0644\u0645\u0634\u064A \u0623\u0648 \u0627\u0644\u064A\u0648\u063A\u0627\n\u2022 \u0627\u0634\u0631\u0628\u064A \u0645\u0634\u0631\u0648\u0628\u0627\u062A \u062F\u0627\u0641\u0626\u0629 \u0643\u0627\u0644\u0628\u0627\u0628\u0648\u0646\u062C \u0648\u0627\u0644\u0632\u0646\u062C\u0628\u064A\u0644 \u0648\u0627\u0644\u0642\u0631\u0641\u0629\n\u2022 \u062A\u062C\u0646\u0628\u064A \u0627\u0644\u0643\u0627\u0641\u064A\u064A\u0646 \u0648\u0627\u0644\u0623\u0637\u0639\u0645\u0629 \u0627\u0644\u0645\u0627\u0644\u062D\u0629\n\u2022 \u062F\u0644\u0643\u064A \u0645\u0646\u0637\u0642\u0629 \u0627\u0644\u0628\u0637\u0646 \u0628\u062D\u0631\u0643\u0627\u062A \u062F\u0627\u0626\u0631\u064A\u0629\n\u2022 \u064A\u0645\u0643\u0646 \u062A\u0646\u0627\u0648\u0644 \u0645\u0633\u0643\u0646 \u062E\u0641\u064A\u0641 \u0639\u0646\u062F \u0627\u0644\u062D\u0627\u062C\u0629\n\n\u0625\u0630\u0627 \u0643\u0627\u0646 \u0627\u0644\u0623\u0644\u0645 \u0634\u062F\u064A\u062F\u0627\u064B \u062C\u062F\u0627\u064B \u0623\u0648 \u064A\u0645\u0646\u0639\u0643 \u0645\u0646 \u0645\u0645\u0627\u0631\u0633\u0629 \u062D\u064A\u0627\u062A\u0643 \u0627\u0644\u0637\u0628\u064A\u0639\u064A\u0629\u060C \u0627\u0633\u062A\u0634\u064A\u0631\u064A \u0637\u0628\u064A\u0628\u062A\u0643.',
    '\u0627\u0646\u062A\u0638\u0627\u0645 \u0627\u0644\u062F\u0648\u0631\u0629|\u062A\u0623\u062E\u0631 \u0627\u0644\u062F\u0648\u0631\u0629|\u0639\u062F\u0645 \u0627\u0646\u062A\u0638\u0627\u0645|\u062F\u0648\u0631\u0629 \u063A\u064A\u0631 \u0645\u0646\u062A\u0638\u0645\u0629':
      '\u0639\u062F\u0645 \u0627\u0646\u062A\u0638\u0627\u0645 \u0627\u0644\u062F\u0648\u0631\u0629 \u0642\u062F \u064A\u0643\u0648\u0646 \u0628\u0633\u0628\u0628:\n\n\u2022 \u0627\u0644\u062A\u0648\u062A\u0631 \u0648\u0627\u0644\u0636\u063A\u0637 \u0627\u0644\u0646\u0641\u0633\u064A\n\u2022 \u062A\u063A\u064A\u0631 \u0627\u0644\u0648\u0632\u0646 \u0627\u0644\u0645\u0641\u0627\u062C\u0626\n\u2022 \u0627\u0636\u0637\u0631\u0627\u0628\u0627\u062A \u0647\u0631\u0645\u0648\u0646\u064A\u0629 \u0645\u062B\u0644 \u062A\u0643\u064A\u0633 \u0627\u0644\u0645\u0628\u0627\u064A\u0636\n\u2022 \u0645\u0634\u0627\u0643\u0644 \u0627\u0644\u063A\u062F\u0629 \u0627\u0644\u062F\u0631\u0642\u064A\u0629\n\u2022 \u0627\u0644\u0631\u064A\u0627\u0636\u0629 \u0627\u0644\u0645\u0641\u0631\u0637\u0629\n\n\u0627\u0644\u062F\u0648\u0631\u0629 \u0627\u0644\u0637\u0628\u064A\u0639\u064A\u0629 \u0628\u064A\u0646 21-35 \u064A\u0648\u0645\u0627\u064B. \u0625\u0630\u0627 \u062A\u0623\u062E\u0631\u062A \u0623\u0643\u062B\u0631 \u0645\u0646 3 \u0623\u0634\u0647\u0631\u060C \u0631\u0627\u062C\u0639\u064A \u0627\u0644\u0637\u0628\u064A\u0628\u0629.',
    '\u0627\u0644\u062A\u0628\u0648\u064A\u0636|\u0625\u0628\u0627\u0636\u0629|\u062E\u0635\u0648\u0628\u0629|\u0623\u064A\u0627\u0645 \u0627\u0644\u062A\u0628\u0648\u064A\u0636':
      '\u0641\u062A\u0631\u0629 \u0627\u0644\u062A\u0628\u0648\u064A\u0636 \u0647\u064A \u0627\u0644\u0641\u062A\u0631\u0629 \u0627\u0644\u062A\u064A \u062A\u0643\u0648\u0646 \u0641\u064A\u0647\u0627 \u0627\u0644\u062E\u0635\u0648\u0628\u0629 \u0641\u064A \u0623\u0639\u0644\u0649 \u0645\u0633\u062A\u0648\u064A\u0627\u062A\u0647\u0627:\n\n\u2022 \u062A\u062D\u062F\u062B \u0639\u0627\u062F\u0629 \u0641\u064A \u0627\u0644\u064A\u0648\u0645 14 \u0645\u0646 \u0627\u0644\u062F\u0648\u0631\u0629 (\u0644\u0644\u062F\u0648\u0631\u0629 28 \u064A\u0648\u0645\u0627\u064B)\n\u2022 \u0639\u0644\u0627\u0645\u0627\u062A\u0647\u0627: \u0625\u0641\u0631\u0627\u0632\u0627\u062A \u0634\u0641\u0627\u0641\u0629\u060C \u0627\u0631\u062A\u0641\u0627\u0639 \u0637\u0641\u064A\u0641 \u0641\u064A \u062F\u0631\u062C\u0629 \u0627\u0644\u062D\u0631\u0627\u0631\u0629\n\u2022 \u0623\u064A\u0627\u0645 \u0627\u0644\u062E\u0635\u0648\u0628\u0629: 5 \u0623\u064A\u0627\u0645 \u0642\u0628\u0644 \u0627\u0644\u062A\u0628\u0648\u064A\u0636 + \u064A\u0648\u0645 \u0627\u0644\u062A\u0628\u0648\u064A\u0636\n\u2022 \u062A\u0637\u0628\u064A\u0642 \u0646\u0628\u0636\u0629 \u064A\u0633\u0627\u0639\u062F\u0643 \u0641\u064A \u062A\u062A\u0628\u0639 \u0647\u0630\u0647 \u0627\u0644\u0623\u064A\u0627\u0645 \u062A\u0644\u0642\u0627\u0626\u064A\u0627\u064B',
    // Pregnancy
    '\u0623\u0639\u0631\u0627\u0636 \u0627\u0644\u062D\u0645\u0644|\u0639\u0644\u0627\u0645\u0627\u062A \u0627\u0644\u062D\u0645\u0644|\u062D\u0645\u0644 \u0645\u0628\u0643\u0631':
      '\u0623\u0639\u0631\u0627\u0636 \u0627\u0644\u062D\u0645\u0644 \u0627\u0644\u0645\u0628\u0643\u0631\u0629 \u062A\u0634\u0645\u0644:\n\n\u2022 \u062A\u0623\u062E\u0631 \u0627\u0644\u062F\u0648\u0631\u0629 \u0627\u0644\u0634\u0647\u0631\u064A\u0629 (\u0623\u0648\u0644 \u0639\u0644\u0627\u0645\u0629)\n\u2022 \u063A\u062B\u064A\u0627\u0646 \u0648\u062A\u0642\u064A\u0624 (\u062E\u0627\u0635\u0629 \u0635\u0628\u0627\u062D\u0627\u064B)\n\u2022 \u062A\u0639\u0628 \u0648\u0625\u0631\u0647\u0627\u0642 \u063A\u064A\u0631 \u0639\u0627\u062F\u064A\n\u2022 \u0627\u0646\u062A\u0641\u0627\u062E \u0648\u062D\u0633\u0627\u0633\u064A\u0629 \u0627\u0644\u062B\u062F\u064A\n\u2022 \u0643\u062B\u0631\u0629 \u0627\u0644\u062A\u0628\u0648\u0644\n\u2022 \u062A\u0642\u0644\u0628\u0627\u062A \u0645\u0632\u0627\u062C\u064A\u0629\n\u2022 \u0646\u0641\u0648\u0631 \u0645\u0646 \u0628\u0639\u0636 \u0627\u0644\u0623\u0637\u0639\u0645\u0629 \u0648\u0627\u0644\u0631\u0648\u0627\u0626\u062D\n\n\u0644\u0644\u062A\u0623\u0643\u062F\u060C \u0627\u0639\u0645\u0644\u064A \u0627\u062E\u062A\u0628\u0627\u0631 \u062D\u0645\u0644 \u0645\u0646\u0632\u0644\u064A \u0623\u0648 \u062A\u062D\u0644\u064A\u0644 \u062F\u0645.',
    '\u063A\u0630\u0627\u0621 \u0627\u0644\u062D\u0627\u0645\u0644|\u0623\u0637\u0639\u0645\u0629 \u0627\u0644\u062D\u0627\u0645\u0644|\u062A\u063A\u0630\u064A\u0629 \u0627\u0644\u062D\u0627\u0645\u0644|\u0623\u0643\u0644 \u0627\u0644\u062D\u0627\u0645\u0644':
      '\u0627\u0644\u062A\u063A\u0630\u064A\u0629 \u0627\u0644\u0633\u0644\u064A\u0645\u0629 \u0644\u0644\u062D\u0627\u0645\u0644:\n\n\u2714\uFE0F \u0623\u0637\u0639\u0645\u0629 \u0645\u0641\u064A\u062F\u0629:\n\u2022 \u0627\u0644\u062E\u0636\u0631\u0648\u0627\u062A \u0627\u0644\u0648\u0631\u0642\u064A\u0629 (\u0627\u0644\u0633\u0628\u0627\u0646\u062E\u060C \u0627\u0644\u0628\u0631\u0648\u0643\u0644\u064A)\n\u2022 \u0627\u0644\u0641\u0648\u0627\u0643\u0647 \u0627\u0644\u0637\u0627\u0632\u062C\u0629 \u0648\u0627\u0644\u0645\u0643\u0633\u0631\u0627\u062A\n\u2022 \u0627\u0644\u0628\u0631\u0648\u062A\u064A\u0646 (\u062F\u062C\u0627\u062C\u060C \u0633\u0645\u0643\u060C \u0628\u064A\u0636\u060C \u0628\u0642\u0648\u0644\u064A\u0627\u062A)\n\u2022 \u0627\u0644\u062D\u0644\u064A\u0628 \u0648\u0645\u0634\u062A\u0642\u0627\u062A\u0647\n\u2022 \u0627\u0644\u062D\u0628\u0648\u0628 \u0627\u0644\u0643\u0627\u0645\u0644\u0629\n\n\u274C \u062A\u062C\u0646\u0628\u064A:\n\u2022 \u0627\u0644\u0623\u0633\u0645\u0627\u0643 \u0627\u0644\u0639\u0627\u0644\u064A\u0629 \u0628\u0627\u0644\u0632\u0626\u0628\u0642\n\u2022 \u0627\u0644\u0644\u062D\u0648\u0645 \u0627\u0644\u0646\u064A\u0626\u0629\n\u2022 \u0627\u0644\u0643\u0627\u0641\u064A\u064A\u0646 \u0628\u0643\u0645\u064A\u0627\u062A \u0643\u0628\u064A\u0631\u0629\n\u2022 \u0627\u0644\u0623\u062C\u0628\u0627\u0646 \u0627\u0644\u0637\u0631\u064A\u0629 \u063A\u064A\u0631 \u0627\u0644\u0645\u0628\u0633\u062A\u0631\u0629\n\n\u0644\u0627 \u062A\u0646\u0633\u064A \u062A\u0646\u0627\u0648\u0644 \u062D\u0645\u0636 \u0627\u0644\u0641\u0648\u0644\u064A\u0643 \u0648\u0627\u0644\u062D\u062F\u064A\u062F \u062D\u0633\u0628 \u062A\u0648\u062C\u064A\u0647\u0627\u062A \u0637\u0628\u064A\u0628\u062A\u0643.',
    '\u063A\u062B\u064A\u0627\u0646|\u0648\u062D\u0627\u0645|\u062A\u0642\u064A\u0624|\u063A\u062B\u064A\u0627\u0646 \u0627\u0644\u062D\u0645\u0644':
      '\u0644\u062A\u062E\u0641\u064A\u0641 \u0627\u0644\u063A\u062B\u064A\u0627\u0646 \u0623\u062B\u0646\u0627\u0621 \u0627\u0644\u062D\u0645\u0644:\n\n\u2022 \u0643\u0644\u064A \u0648\u062C\u0628\u0627\u062A \u0635\u063A\u064A\u0631\u0629 \u0648\u0645\u062A\u0643\u0631\u0631\u0629 (5-6 \u0645\u0631\u0627\u062A \u064A\u0648\u0645\u064A\u0627\u064B)\n\u2022 \u062A\u062C\u0646\u0628\u064A \u0627\u0644\u0645\u0639\u062F\u0629 \u0627\u0644\u0641\u0627\u0631\u063A\u0629 - \u0643\u0644\u064A \u0628\u0633\u0643\u0648\u064A\u062A \u062C\u0627\u0641 \u0642\u0628\u0644 \u0627\u0644\u0642\u064A\u0627\u0645 \u0645\u0646 \u0627\u0644\u0633\u0631\u064A\u0631\n\u2022 \u0627\u0634\u0631\u0628\u064A \u0627\u0644\u0632\u0646\u062C\u0628\u064A\u0644 \u0623\u0648 \u0627\u0644\u0646\u0639\u0646\u0627\u0639\n\u2022 \u062A\u062C\u0646\u0628\u064A \u0627\u0644\u0631\u0648\u0627\u0626\u062D \u0627\u0644\u0642\u0648\u064A\u0629 \u0648\u0627\u0644\u0623\u0637\u0639\u0645\u0629 \u0627\u0644\u062F\u0633\u0645\u0629\n\u2022 \u0627\u0633\u062A\u0631\u064A\u062D\u064A \u0628\u0639\u062F \u0627\u0644\u0623\u0643\u0644\n\n\u0627\u0644\u063A\u062B\u064A\u0627\u0646 \u0637\u0628\u064A\u0639\u064A \u0641\u064A \u0627\u0644\u0623\u0634\u0647\u0631 \u0627\u0644\u062B\u0644\u0627\u062B\u0629 \u0627\u0644\u0623\u0648\u0644\u0649 \u0648\u064A\u062E\u0641 \u062A\u062F\u0631\u064A\u062C\u064A\u0627\u064B. \u0625\u0630\u0627 \u0643\u0627\u0646 \u0634\u062F\u064A\u062F\u0627\u064B \u062C\u062F\u0627\u064B \u0631\u0627\u062C\u0639\u064A \u0627\u0644\u0637\u0628\u064A\u0628\u0629.',
    // Baby Care
    '\u0631\u0636\u064A\u0639|\u0631\u0636\u0627\u0639\u0629|\u062D\u0644\u064A\u0628 \u0627\u0644\u0623\u0645|\u0627\u0644\u0631\u0636\u0627\u0639\u0629 \u0627\u0644\u0637\u0628\u064A\u0639\u064A\u0629':
      '\u0646\u0635\u0627\u0626\u062D \u0644\u0644\u0631\u0636\u0627\u0639\u0629 \u0627\u0644\u0637\u0628\u064A\u0639\u064A\u0629:\n\n\u2022 \u0627\u0628\u062F\u0626\u064A \u0627\u0644\u0631\u0636\u0627\u0639\u0629 \u062E\u0644\u0627\u0644 \u0627\u0644\u0633\u0627\u0639\u0629 \u0627\u0644\u0623\u0648\u0644\u0649 \u0628\u0639\u062F \u0627\u0644\u0648\u0644\u0627\u062F\u0629\n\u2022 \u0623\u0631\u0636\u0639\u064A 8-12 \u0645\u0631\u0629 \u064A\u0648\u0645\u064A\u0627\u064B (\u0643\u0644 2-3 \u0633\u0627\u0639\u0627\u062A)\n\u2022 \u062A\u0623\u0643\u062F\u064A \u0645\u0646 \u0627\u0644\u062A\u0642\u0627\u0645 \u0627\u0644\u0637\u0641\u0644 \u0627\u0644\u0635\u062D\u064A\u062D (\u0627\u0644\u0641\u0645 \u064A\u063A\u0637\u064A \u0627\u0644\u0647\u0627\u0644\u0629)\n\u2022 \u0627\u0644\u0631\u0636\u0627\u0639\u0629 \u0627\u0644\u0637\u0628\u064A\u0639\u064A\u0629 \u062D\u0635\u0631\u064A\u0627\u064B \u0644\u0645\u062F\u0629 6 \u0623\u0634\u0647\u0631\n\u2022 \u0627\u0634\u0631\u0628\u064A \u0645\u0627\u0621 \u0643\u062B\u064A\u0631 \u0648\u062A\u063A\u0630\u064A \u062C\u064A\u062F\u0627\u064B\n\u2022 \u0627\u0633\u062A\u0634\u064A\u0631\u064A \u0645\u062E\u062A\u0635\u0629 \u0631\u0636\u0627\u0639\u0629 \u0625\u0630\u0627 \u0648\u0627\u062C\u0647\u062A \u0635\u0639\u0648\u0628\u0627\u062A',
    '\u0646\u0648\u0645 \u0627\u0644\u0637\u0641\u0644|\u0646\u0648\u0645 \u0627\u0644\u0631\u0636\u064A\u0639|\u0628\u0643\u0627\u0621 \u0627\u0644\u0637\u0641\u0644':
      '\u0646\u0635\u0627\u0626\u062D \u0644\u0646\u0648\u0645 \u0627\u0644\u0637\u0641\u0644:\n\n\u2022 \u0646\u0648\u0645\u064A \u0627\u0644\u0637\u0641\u0644 \u0639\u0644\u0649 \u0638\u0647\u0631\u0647 (\u0627\u0644\u0623\u0643\u062B\u0631 \u0623\u0645\u0627\u0646\u0627\u064B)\n\u2022 \u0623\u0646\u0634\u0626\u064A \u0631\u0648\u062A\u064A\u0646 \u0646\u0648\u0645 \u062B\u0627\u0628\u062A (\u062D\u0645\u0627\u0645\u060C \u062A\u062F\u0644\u064A\u0643\u060C \u0631\u0636\u0627\u0639\u0629)\n\u2022 \u0627\u0644\u063A\u0631\u0641\u0629 \u0645\u0638\u0644\u0645\u0629 \u0648\u0647\u0627\u062F\u0626\u0629 \u0648\u062F\u0631\u062C\u0629 \u062D\u0631\u0627\u0631\u0629 \u0645\u0646\u0627\u0633\u0628\u0629\n\u2022 \u0627\u0644\u0645\u0648\u0644\u0648\u062F \u064A\u0646\u0627\u0645 16-17 \u0633\u0627\u0639\u0629 \u064A\u0648\u0645\u064A\u0627\u064B\n\u2022 \u0644\u0627 \u062A\u0636\u0639\u064A \u0648\u0633\u0627\u0626\u062F \u0623\u0648 \u0623\u0644\u0639\u0627\u0628 \u0641\u064A \u0627\u0644\u0633\u0631\u064A\u0631\n\n\u0627\u0644\u0628\u0643\u0627\u0621 \u0637\u0628\u064A\u0639\u064A - \u062A\u0623\u0643\u062F\u064A \u0645\u0646: \u0627\u0644\u062C\u0648\u0639\u060C \u0627\u0644\u062D\u0641\u0627\u0636\u060C \u0627\u0644\u062D\u0631\u0627\u0631\u0629\u060C \u0627\u0644\u062D\u0627\u062C\u0629 \u0644\u0644\u062D\u0636\u0646.',
    '\u062A\u0637\u0639\u064A\u0645|\u0644\u0642\u0627\u062D|\u062A\u0637\u0639\u064A\u0645\u0627\u062A \u0627\u0644\u0637\u0641\u0644':
      '\u062C\u062F\u0648\u0644 \u0627\u0644\u062A\u0637\u0639\u064A\u0645\u0627\u062A \u0627\u0644\u0623\u0633\u0627\u0633\u064A\u0629:\n\n\u2022 \u0639\u0646\u062F \u0627\u0644\u0648\u0644\u0627\u062F\u0629: BCG + \u0627\u0644\u062A\u0647\u0627\u0628 \u0627\u0644\u0643\u0628\u062F B\n\u2022 \u0634\u0647\u0631\u064A\u0646: \u0627\u0644\u062B\u0644\u0627\u062B\u064A + \u0634\u0644\u0644 \u0627\u0644\u0623\u0637\u0641\u0627\u0644 + \u0627\u0644\u0631\u0648\u062A\u0627\n\u2022 4 \u0623\u0634\u0647\u0631: \u062C\u0631\u0639\u0629 \u062B\u0627\u0646\u064A\u0629\n\u2022 6 \u0623\u0634\u0647\u0631: \u062C\u0631\u0639\u0629 \u062B\u0627\u0644\u062B\u0629\n\u2022 9 \u0623\u0634\u0647\u0631: \u0627\u0644\u062D\u0635\u0628\u0629\n\u2022 12 \u0634\u0647\u0631: MMR\n\u2022 18 \u0634\u0647\u0631: \u062C\u0631\u0639\u0627\u062A \u062A\u0646\u0634\u064A\u0637\u064A\u0629\n\n\u0627\u0644\u062A\u0632\u0645\u064A \u0628\u062C\u062F\u0648\u0644 \u0627\u0644\u062A\u0637\u0639\u064A\u0645\u0627\u062A \u0644\u062D\u0645\u0627\u064A\u0629 \u0637\u0641\u0644\u0643. \u0631\u0627\u062C\u0639\u064A \u0637\u0628\u064A\u0628 \u0627\u0644\u0623\u0637\u0641\u0627\u0644 \u0644\u0644\u062C\u062F\u0648\u0644 \u0627\u0644\u0643\u0627\u0645\u0644.',
    // General Health
    '\u0632\u064A\u0627\u0631\u0629 \u0627\u0644\u0637\u0628\u064A\u0628|\u0645\u062A\u0649 \u0623\u0632\u0648\u0631 \u0627\u0644\u0637\u0628\u064A\u0628|\u0627\u0633\u062A\u0634\u0627\u0631\u0629 \u0637\u0628\u064A\u0629':
      '\u064A\u062C\u0628 \u0632\u064A\u0627\u0631\u0629 \u0627\u0644\u0637\u0628\u064A\u0628\u0629 \u0641\u064A \u0647\u0630\u0647 \u0627\u0644\u062D\u0627\u0644\u0627\u062A:\n\n\u2022 \u0622\u0644\u0627\u0645 \u0634\u062F\u064A\u062F\u0629 \u063A\u064A\u0631 \u0637\u0628\u064A\u0639\u064A\u0629 \u0623\u062B\u0646\u0627\u0621 \u0627\u0644\u062F\u0648\u0631\u0629\n\u2022 \u0646\u0632\u064A\u0641 \u063A\u0632\u064A\u0631 \u0623\u0648 \u063A\u064A\u0631 \u0637\u0628\u064A\u0639\u064A\n\u2022 \u062A\u0623\u062E\u0631 \u0627\u0644\u062F\u0648\u0631\u0629 \u0623\u0643\u062B\u0631 \u0645\u0646 3 \u0623\u0634\u0647\u0631\n\u2022 \u0623\u0644\u0645 \u0623\u062B\u0646\u0627\u0621 \u0627\u0644\u062D\u0645\u0644 \u0623\u0648 \u0646\u0632\u064A\u0641\n\u2022 \u062D\u0631\u0627\u0631\u0629 \u0627\u0644\u0637\u0641\u0644 \u0623\u0643\u062B\u0631 \u0645\u0646 38.5\n\u2022 \u0627\u0644\u0641\u062D\u0635 \u0627\u0644\u062F\u0648\u0631\u064A \u0627\u0644\u0633\u0646\u0648\u064A \u0644\u0644\u0646\u0633\u0627\u0621\n\n\u0644\u0627 \u062A\u062A\u0631\u062F\u062F\u064A \u0641\u064A \u0627\u0633\u062A\u0634\u0627\u0631\u0629 \u0627\u0644\u0637\u0628\u064A\u0628\u0629 \u0639\u0646\u062F \u0627\u0644\u0634\u0643.',
    '\u0641\u064A\u062A\u0627\u0645\u064A\u0646|\u0645\u0643\u0645\u0644\u0627\u062A|\u062D\u062F\u064A\u062F|\u0641\u0648\u0644\u064A\u0643|\u0643\u0627\u0644\u0633\u064A\u0648\u0645':
      '\u0627\u0644\u0641\u064A\u062A\u0627\u0645\u064A\u0646\u0627\u062A \u0627\u0644\u0645\u0647\u0645\u0629 \u0644\u0644\u0645\u0631\u0623\u0629:\n\n\u2022 \u062D\u0645\u0636 \u0627\u0644\u0641\u0648\u0644\u064A\u0643: \u0636\u0631\u0648\u0631\u064A \u0642\u0628\u0644 \u0648\u0623\u062B\u0646\u0627\u0621 \u0627\u0644\u062D\u0645\u0644\n\u2022 \u0627\u0644\u062D\u062F\u064A\u062F: \u0644\u0645\u0646\u0639 \u0641\u0642\u0631 \u0627\u0644\u062F\u0645 (\u062E\u0627\u0635\u0629 \u0623\u062B\u0646\u0627\u0621 \u0627\u0644\u062F\u0648\u0631\u0629 \u0648\u0627\u0644\u062D\u0645\u0644)\n\u2022 \u0627\u0644\u0643\u0627\u0644\u0633\u064A\u0648\u0645: \u0644\u0635\u062D\u0629 \u0627\u0644\u0639\u0638\u0627\u0645\n\u2022 \u0641\u064A\u062A\u0627\u0645\u064A\u0646 D: \u0644\u0627\u0645\u062A\u0635\u0627\u0635 \u0627\u0644\u0643\u0627\u0644\u0633\u064A\u0648\u0645\n\u2022 \u0623\u0648\u0645\u064A\u063A\u0627 3: \u0644\u0635\u062D\u0629 \u0627\u0644\u0642\u0644\u0628 \u0648\u0627\u0644\u062F\u0645\u0627\u063A\n\n\u0627\u0633\u062A\u0634\u064A\u0631\u064A \u0637\u0628\u064A\u0628\u062A\u0643 \u0642\u0628\u0644 \u062A\u0646\u0627\u0648\u0644 \u0623\u064A \u0645\u0643\u0645\u0644\u0627\u062A.',
    '\u0631\u064A\u0627\u0636\u0629|\u062A\u0645\u0627\u0631\u064A\u0646|\u0631\u064A\u0627\u0636\u0629 \u0627\u0644\u062D\u0627\u0645\u0644|\u0645\u0634\u064A':
      '\u0627\u0644\u0631\u064A\u0627\u0636\u0629 \u0623\u062B\u0646\u0627\u0621 \u0627\u0644\u062D\u0645\u0644:\n\n\u2714\uFE0F \u0622\u0645\u0646\u0629 \u0648\u0645\u0641\u064A\u062F\u0629:\n\u2022 \u0627\u0644\u0645\u0634\u064A 30 \u062F\u0642\u064A\u0642\u0629 \u064A\u0648\u0645\u064A\u0627\u064B\n\u2022 \u0627\u0644\u0633\u0628\u0627\u062D\u0629\n\u2022 \u064A\u0648\u063A\u0627 \u0627\u0644\u062D\u0648\u0627\u0645\u0644\n\u2022 \u062A\u0645\u0627\u0631\u064A\u0646 \u0643\u064A\u062C\u0644\n\n\u274C \u062A\u062C\u0646\u0628\u064A:\n\u2022 \u0627\u0644\u0631\u064A\u0627\u0636\u0627\u062A \u0627\u0644\u0639\u0646\u064A\u0641\u0629\n\u2022 \u0627\u0644\u0642\u0641\u0632 \u0648\u0627\u0644\u062C\u0631\u064A \u0627\u0644\u0633\u0631\u064A\u0639\n\u2022 \u062D\u0645\u0644 \u0627\u0644\u0623\u062B\u0642\u0627\u0644\n\n\u0627\u0633\u062A\u0634\u064A\u0631\u064A \u0637\u0628\u064A\u0628\u062A\u0643 \u0642\u0628\u0644 \u0627\u0644\u0628\u062F\u0621.',
    '\u0646\u0641\u0633\u064A\u0629|\u0627\u0643\u062A\u0626\u0627\u0628|\u0642\u0644\u0642|\u0627\u0643\u062A\u0626\u0627\u0628 \u0645\u0627 \u0628\u0639\u062F \u0627\u0644\u0648\u0644\u0627\u062F\u0629':
      '\u0627\u0644\u0635\u062D\u0629 \u0627\u0644\u0646\u0641\u0633\u064A\u0629 \u0645\u0647\u0645\u0629 \u062C\u062F\u0627\u064B:\n\n\u0627\u0643\u062A\u0626\u0627\u0628 \u0645\u0627 \u0628\u0639\u062F \u0627\u0644\u0648\u0644\u0627\u062F\u0629 \u0634\u0627\u0626\u0639 \u0648\u0639\u0644\u0627\u0645\u0627\u062A\u0647:\n\u2022 \u062D\u0632\u0646 \u0645\u0633\u062A\u0645\u0631 \u0648\u0628\u0643\u0627\u0621\n\u2022 \u0635\u0639\u0648\u0628\u0629 \u0627\u0644\u062A\u0631\u0627\u0628\u0637 \u0645\u0639 \u0627\u0644\u0637\u0641\u0644\n\u2022 \u0623\u0631\u0642 \u0623\u0648 \u0646\u0648\u0645 \u0645\u0641\u0631\u0637\n\u2022 \u0641\u0642\u062F\u0627\u0646 \u0627\u0644\u0634\u0647\u064A\u0629\n\n\u0644\u0644\u0639\u0646\u0627\u064A\u0629 \u0628\u0646\u0641\u0633\u0643:\n\u2022 \u0627\u0637\u0644\u0628\u064A \u0627\u0644\u0645\u0633\u0627\u0639\u062F\u0629 \u0645\u0646 \u0627\u0644\u0639\u0627\u0626\u0644\u0629\n\u2022 \u062E\u0630\u064A \u0648\u0642\u062A\u0627\u064B \u0644\u0646\u0641\u0633\u0643\n\u2022 \u062A\u062D\u062F\u062B\u064A \u0645\u0639 \u0635\u062F\u064A\u0642\u0629 \u0623\u0648 \u0645\u062E\u062A\u0635\u0629\n\n\u0644\u0627 \u062A\u062A\u0631\u062F\u062F\u064A \u0641\u064A \u0637\u0644\u0628 \u0627\u0644\u0645\u0633\u0627\u0639\u062F\u0629 \u0627\u0644\u0645\u062A\u062E\u0635\u0635\u0629. \u0635\u062D\u062A\u0643 \u0627\u0644\u0646\u0641\u0633\u064A\u0629 \u0623\u0648\u0644\u0648\u064A\u0629!',
  };

  String _getSmartReply(String question) {
    final q = question.toLowerCase();
    for (final entry in _healthKB.entries) {
      final keywords = entry.key.split('|');
      for (final kw in keywords) {
        if (q.contains(kw)) return entry.value;
      }
    }
    return '\u0634\u0643\u0631\u0627\u064B \u0639\u0644\u0649 \u0633\u0624\u0627\u0644\u0643! \u0647\u0630\u0627 \u0627\u0644\u0645\u0648\u0636\u0648\u0639 \u064A\u062D\u062A\u0627\u062C \u0627\u0633\u062A\u0634\u0627\u0631\u0629 \u0637\u0628\u064A\u0629 \u0645\u062A\u062E\u0635\u0635\u0629. \u0623\u0646\u0635\u062D\u0643 \u0628\u0645\u0631\u0627\u062C\u0639\u0629 \u0637\u0628\u064A\u0628\u062A\u0643 \u0644\u0644\u062D\u0635\u0648\u0644 \u0639\u0644\u0649 \u0625\u062C\u0627\u0628\u0629 \u062F\u0642\u064A\u0642\u0629 \u0648\u0645\u062E\u0635\u0635\u0629 \u0644\u062D\u0627\u0644\u062A\u0643.\n\n\u064A\u0645\u0643\u0646\u0643 \u0633\u0624\u0627\u0644\u064A \u0639\u0646:\n\u2022 \u0622\u0644\u0627\u0645 \u0627\u0644\u062F\u0648\u0631\u0629 \u0648\u0627\u0646\u062A\u0638\u0627\u0645\u0647\u0627\n\u2022 \u0623\u0639\u0631\u0627\u0636 \u0627\u0644\u062D\u0645\u0644 \u0648\u0627\u0644\u062A\u063A\u0630\u064A\u0629\n\u2022 \u0627\u0644\u0631\u0636\u0627\u0639\u0629 \u0648\u0631\u0639\u0627\u064A\u0629 \u0627\u0644\u0637\u0641\u0644\n\u2022 \u0627\u0644\u062A\u0637\u0639\u064A\u0645\u0627\u062A \u0648\u0627\u0644\u0641\u064A\u062A\u0627\u0645\u064A\u0646\u0627\u062A';
  }

  Future<String> _callGemini(String userMessage) async {
    _chatHistory.add({'role': 'user', 'parts': [{'text': userMessage}]});

    final sysText = '\u0623\u0646\u062A \u0645\u0633\u0627\u0639\u062F \u0635\u062D\u064A \u0630\u0643\u064A \u0627\u0633\u0645\u0643 \u0646\u0628\u0636\u0629\u060C \u0645\u062A\u062E\u0635\u0635 \u0641\u064A \u0635\u062D\u0629 \u0627\u0644\u0645\u0631\u0623\u0629. \u0623\u062C\u0628 \u062F\u0627\u0626\u0645\u0627\u064B \u0628\u0627\u0644\u0639\u0631\u0628\u064A\u0629. \u062A\u062E\u0635\u0635\u0627\u062A\u0643: \u0627\u0644\u062F\u0648\u0631\u0629\u060C \u0627\u0644\u062D\u0645\u0644\u060C \u0627\u0644\u0648\u0644\u0627\u062F\u0629\u060C \u0631\u0639\u0627\u064A\u0629 \u0627\u0644\u0637\u0641\u0644\u060C \u0627\u0644\u062A\u063A\u0630\u064A\u0629. \u0623\u062C\u0628 \u0628\u0625\u064A\u062C\u0627\u0632. \u0625\u0630\u0627 \u062A\u0637\u0644\u0628 \u0627\u0644\u0633\u0624\u0627\u0644 \u062A\u0634\u062E\u064A\u0635\u0627\u064B \u0637\u0628\u064A\u0627\u064B \u0627\u0646\u0635\u062D\u064A \u0628\u0632\u064A\u0627\u0631\u0629 \u0627\u0644\u0637\u0628\u064A\u0628.';

    try {
      final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey';
      final body = jsonEncode({
        'systemInstruction': {'parts': [{'text': sysText}]},
        'contents': _chatHistory,
      });

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String reply = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '\u0644\u0645 \u0623\u062A\u0645\u0643\u0646 \u0645\u0646 \u0627\u0644\u0625\u062C\u0627\u0628\u0629';
        _chatHistory.add({'role': 'model', 'parts': [{'text': reply}]});
        return reply;
      }
    } catch (_) {}

    // Fallback: smart local replies
    return _getSmartReply(userMessage);
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _msgController.clear();

    setState(() {
      messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      String reply = await _callGemini(text);
      setState(() {
        messages.add({'role': 'assistant', 'text': reply});
        _isLoading = false;
      });
      DB.userDoc.collection('chat_history').add({
        'question': text,
        'answer': reply,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      setState(() {
        messages.add({
          'role': 'assistant',
          'text': _getSmartReply(text),
        });
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('\u0627\u0644\u0645\u0633\u0627\u0639\u062F \u0627\u0644\u0630\u0643\u064A'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: Icon(Icons.delete_outline),
              onPressed: () {
                setState(() {
                  messages.clear();
                  messages.add({
                    'role': 'assistant',
                    'text': '\u062A\u0645 \u0645\u0633\u062D \u0627\u0644\u0645\u062D\u0627\u062F\u062B\u0629. \u0643\u064A\u0641 \u064A\u0645\u0643\u0646\u0646\u064A \u0645\u0633\u0627\u0639\u062F\u062A\u0643\u061F \u{1F49C}'
                  });
                });
                _chatHistory.clear();
              },
              tooltip: '\u0645\u0633\u062D \u0627\u0644\u0645\u062D\u0627\u062F\u062B\u0629',
            ),
          ],
        ),
        body: Column(children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length && _isLoading) {
                  return _typingIndicator();
                }
                final msg = messages[index];
                bool isUser = msg['role'] == 'user';
                return _chatBubble(msg['text']!, isUser);
              },
            ),
          ),
          // Quick suggestions (show only at start)
          if (messages.length <= 1)
            Container(
              height: 44,
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: quickQuestions.map((q) => Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: ActionChip(
                    label: Text(q, style: TextStyle(fontSize: 12)),
                    backgroundColor: Colors.teal.shade50,
                    onPressed: () => _sendMessage(q),
                  ),
                )).toList(),
              ),
            ),
          if (messages.length <= 1) SizedBox(height: 8),
          // Input bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -1))],
            ),
            child: SafeArea(
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                      hintText: '\u0627\u0643\u062A\u0628\u064A \u0633\u0624\u0627\u0644\u0643 \u0647\u0646\u0627...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: _sendMessage,
                    textInputAction: TextInputAction.send,
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: () => _sendMessage(_msgController.text),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _chatBubble(String text, bool isUser) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.teal.shade100,
              child: Icon(Icons.smart_toy, size: 18, color: Colors.teal),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? Colors.teal.shade100 : Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: isUser ? Radius.circular(16) : Radius.circular(4),
                  bottomRight: isUser ? Radius.circular(4) : Radius.circular(16),
                ),
              ),
              child: Text(text, style: TextStyle(fontSize: 15, height: 1.5)),
            ),
          ),
          if (isUser) ...[
            SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.teal,
              child: Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _typingIndicator() {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(radius: 16, backgroundColor: Colors.teal.shade100,
          child: Icon(Icons.smart_toy, size: 18, color: Colors.teal)),
        SizedBox(width: 8),
        Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal)),
            SizedBox(width: 10),
            Text('\u062C\u0627\u0631\u064A \u0627\u0644\u062A\u0641\u0643\u064A\u0631...', style: TextStyle(color: Colors.grey)),
          ]),
        ),
      ]),
    );
  }
}