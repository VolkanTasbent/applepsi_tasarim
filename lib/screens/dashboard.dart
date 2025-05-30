import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import 'package:applepsi_tasarim/screens/RandevularimSayfasi.dart';
import 'package:applepsi_tasarim/screens/giris_ekrani.dart';
import 'package:applepsi_tasarim/screens/randevu_al_sayfasi.dart';

class DashboardEkrani extends StatefulWidget {
  final String userId;

  const DashboardEkrani({Key? key, required this.userId}) : super(key: key);

  @override
  _DashboardEkraniState createState() => _DashboardEkraniState();
}

class _DashboardEkraniState extends State<DashboardEkrani>
    with TickerProviderStateMixin {
  
  // Animation controllers
  AnimationController? _particleController;
  AnimationController? _cardController;
  List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _generateParticles();
  }

  void _initAnimations() {
    try {
      _particleController = AnimationController(
        duration: Duration(seconds: 30),
        vsync: this,
      );

      _cardController = AnimationController(
        duration: Duration(milliseconds: 1500),
        vsync: this,
      );

      _particleController?.repeat();
      _cardController?.forward();
    } catch (e) {
      print('Animation initialization error: $e');
    }
  }

  void _generateParticles() {
    _particles = List.generate(8, (index) {
      return Particle(
        x: math.Random().nextDouble(),
        y: math.Random().nextDouble(),
        size: math.Random().nextDouble() * 2 + 1,
        speed: math.Random().nextDouble() * 0.2 + 0.05,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurpleAccent,
      body: Stack(
        children: [
          // Animated Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1565C0),
                    Color(0xFF7B1FA2),
                    Color(0xFF4A148C),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          
          // Animated Particles
          if (_particleController != null)
            AnimatedBuilder(
              animation: _particleController!,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticlePainter(_particles, _particleController!.value),
                  size: Size.infinite,
                );
              },
            ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                _buildCustomAppBar(),
                
                // Body Content
                Expanded(
                  child: _buildBody(),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: _buildModernDrawer(context),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Builder(
            builder: (context) => GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Icon(
                  Icons.menu,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 600.ms)
      .slideY(begin: -0.5);
  }

  Widget _buildBody() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('hastalar').doc(widget.userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                    strokeWidth: 3,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Bilgiler yükleniyor...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Container(
              margin: EdgeInsets.all(20),
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 50, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Hata oluştu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(
            child: Container(
              margin: EdgeInsets.all(20),
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 50, color: Colors.orange),
                  SizedBox(height: 16),
                  Text(
                    'Kullanıcı bilgileri bulunamadı',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;

        if (userData == null || userData['ad'] == null || userData['soyad'] == null) {
          return Center(
            child: Container(
              margin: EdgeInsets.all(20),
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 50, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Kullanıcı bilgileri eksik',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return _buildProfile(userData, context);
      },
    );
  }

  Widget _buildProfile(Map<String, dynamic> userData, BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // Welcome Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber, Colors.orange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.3),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      "${userData['ad'][0]}${userData['soyad'][0]}".toUpperCase(),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Hoş Geldiniz',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '${userData['ad']} ${userData['soyad']}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  userData['email'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ).animate(controller: _cardController)
            .fadeIn(duration: 600.ms)
            .slideY(begin: 0.3)
            .then()
            .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.1)),

          SizedBox(height: 24),

          // Quick Actions
          _buildQuickActions(context)
            .animate(controller: _cardController)
            .fadeIn(duration: 600.ms, delay: 200.ms)
            .slideY(begin: 0.3),

          SizedBox(height: 24),

          // Doctor Info Card
          if (userData['doktorUid'] != null)
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('doktorlar')
                  .doc(userData['doktorUid'])
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Colors.amber),
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return SizedBox.shrink();
                }

                final doctor = snapshot.data!.data() as Map<String, dynamic>;
                return _buildDoctorCard(doctor)
                  .animate(controller: _cardController)
                  .fadeIn(duration: 600.ms, delay: 400.ms)
                  .slideY(begin: 0.3);
              },
            ),
        ],
      ),
    );
  }

Widget _buildQuickActions(BuildContext context) {
  final actions = [
    {
      'icon': Icons.calendar_today,
      'title': 'Randevu Al',
      'subtitle': 'Yeni randevu oluştur',
      'color': Colors.blue,
      'onTap': () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RandevuAlSayfasi()),
      ),
    },
    {
      'icon': Icons.list_alt,
      'title': 'Randevularım',
      'subtitle': 'Mevcut randevular',
      'color': Colors.green,
      'onTap': () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RandevularimSayfasi()),
      ),
    },
    {
      'icon': Icons.history,
      'title': 'Geçmiş',
      'subtitle': 'Nöbet geçmişi',
      'color': Colors.orange,
      'onTap': () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GecmisNobetler(userId: widget.userId)),
      ),
    },
    {
      'icon': Icons.person,
      'title': 'Profil',
      'subtitle': 'Bilgilerim',
      'color': Colors.purple,
      'onTap': () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfilSayfasi(userId: widget.userId)),
      ),
    },
  ];

  return Padding(
    padding: const EdgeInsets.only(bottom: 24.0), // Alt boşluk overflow'u önler
    child: GridView.builder(
      shrinkWrap: true, // Önemli: Column içinde GridView kullanımı için
      physics: NeverScrollableScrollPhysics(), // Scroll çakışmasını önler
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return GestureDetector(
          onTap: action['onTap'] as VoidCallback,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (action['color'] as Color).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    action['icon'] as IconData,
                    color: action['color'] as Color,
                    size: 28,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  action['title'] as String,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  action['subtitle'] as String,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: 100 * index))
          .fadeIn(duration: 400.ms)
          .scale(begin: Offset(0.8, 0.8));
      },
    ),
  );
}


  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.medical_services,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Doktorunuz',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Dr. ${doctor['name']} ${doctor['surname']}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_hospital,
                  color: Colors.white.withOpacity(0.8),
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  doctor['specialty'] ?? 'Uzmanlık belirtilmemiş',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDrawer(BuildContext context) {
    return Drawer(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1565C0),
              Color(0xFF7B1FA2),
              Color(0xFF4A148C),
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildModernDrawerHeader(),
            SizedBox(height: 20),
            _buildDrawerItem(
              icon: Icons.person_outline,
              title: 'Profil Bilgileri',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilSayfasi(userId: widget.userId),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.calendar_today,
              title: 'Randevu Al',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RandevuAlSayfasi(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.list_alt,
              title: 'Randevularım',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RandevularimSayfasi(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.history_toggle_off,
              title: 'Geçmiş Nöbetler',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GecmisNobetler(userId: widget.userId),
                  ),
                );
              },
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: 1,
              color: Colors.white.withOpacity(0.2),
            ),
            _buildDrawerItem(
              icon: Icons.exit_to_app,
              title: 'Çıkış Yap',
              onTap: () async {
                try {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => GirisEkrani()),
                    (Route<dynamic> route) => false,
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Çıkış yapılırken hata oluştu: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernDrawerHeader() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('hastalar').doc(widget.userId).get(),
      builder: (context, snapshot) {
        String name = "Kullanıcı";
        String email = "email@example.com";
        
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          name = "${data['ad'] ?? 'Kullanıcı'} ${data['soyad'] ?? ''}";
          email = data['email'] ?? "email@example.com";
        }

        return Container(
          padding: EdgeInsets.fromLTRB(20, 60, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber, Colors.orange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.3),
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : "K",
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                email,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        hoverColor: Colors.white.withOpacity(0.1),
      ),
    );
  }

  @override
  void dispose() {
    _particleController?.dispose();
    _cardController?.dispose();
    super.dispose();
  }
}

// Particle System (Same as login/register)
class Particle {
  double x, y, size, speed;
  Particle({required this.x, required this.y, required this.size, required this.speed});
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;

  ParticlePainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.fill;

    for (var particle in particles) {
      double currentY = (particle.y + animationValue * particle.speed) % 1.0;
      double currentX = particle.x + math.sin(animationValue * 2 * math.pi + particle.y * 10) * 0.02;
      
      canvas.drawCircle(
        Offset(currentX * size.width, currentY * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Profile Page with Modern Design
class ProfilSayfasi extends StatefulWidget {
  final String userId;

  const ProfilSayfasi({Key? key, required this.userId}) : super(key: key);

  @override
  _ProfilSayfasiState createState() => _ProfilSayfasiState();
}

class _ProfilSayfasiState extends State<ProfilSayfasi>
    with TickerProviderStateMixin {
  
  AnimationController? _animationController;
  List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _generateParticles();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: Duration(seconds: 25),
      vsync: this,
    );
    _animationController?.repeat();
  }

  void _generateParticles() {
    _particles = List.generate(6, (index) {
      return Particle(
        x: math.Random().nextDouble(),
        y: math.Random().nextDouble(),
        size: math.Random().nextDouble() * 2 + 1,
        speed: math.Random().nextDouble() * 0.15 + 0.05,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurpleAccent,
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1565C0),
                    Color(0xFF7B1FA2),
                    Color(0xFF4A148C),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          
          // Particles
          if (_animationController != null)
            AnimatedBuilder(
              animation: _animationController!,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticlePainter(_particles, _animationController!.value),
                  size: Size.infinite,
                );
              },
            ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Profil Bilgileri',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 44), // Balance the back button
                    ],
                  ),
                ),
                
                // Profile Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('hastalar')
                          .doc(widget.userId)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(Colors.amber),
                            ),
                          );
                        }

                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return Center(
                            child: Text(
                              'Veri bulunamadı',
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        }

                        final user = snapshot.data!.data() as Map<String, dynamic>;
                        return Column(
                          children: [
                            // Profile Header
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.amber, Colors.orange],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        "${user['ad'][0]}${user['soyad'][0]}".toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    '${user['ad']} ${user['soyad']}',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ).animate()
                              .fadeIn(duration: 600.ms)
                              .slideY(begin: 0.3),

                            SizedBox(height: 24),

                            // Profile Details
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Kişisel Bilgiler',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  _buildProfileItem(Icons.person, 'Ad', user['ad'] ?? ''),
                                  _buildProfileItem(Icons.person_outline, 'Soyad', user['soyad'] ?? ''),
                                  _buildProfileItem(Icons.email, 'Email', user['email'] ?? ''),
                                ],
                              ),
                            ).animate()
                              .fadeIn(duration: 600.ms, delay: 200.ms)
                              .slideY(begin: 0.3),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.amber, size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }
}

// Past Appointments with Modern Design
class GecmisNobetler extends StatefulWidget {
  final String userId;

  const GecmisNobetler({Key? key, required this.userId}) : super(key: key);

  @override
  _GecmisNobetlerState createState() => _GecmisNobetlerState();
}

class _GecmisNobetlerState extends State<GecmisNobetler>
    with TickerProviderStateMixin {
  
  AnimationController? _animationController;
  List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _generateParticles();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: Duration(seconds: 25),
      vsync: this,
    );
    _animationController?.repeat();
  }

  void _generateParticles() {
    _particles = List.generate(6, (index) {
      return Particle(
        x: math.Random().nextDouble(),
        y: math.Random().nextDouble(),
        size: math.Random().nextDouble() * 2 + 1,
        speed: math.Random().nextDouble() * 0.15 + 0.05,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.deepPurpleAccent,
        body: Stack(
          children: [
            // Background
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1565C0),
                      Color(0xFF7B1FA2),
                      Color(0xFF4A148C),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            
            // Particles
            if (_animationController != null)
              AnimatedBuilder(
                animation: _animationController!,
                builder: (context, child) {
                  return CustomPaint(
                    painter: ParticlePainter(_particles, _animationController!.value),
                    size: Size.infinite,
                  );
                },
              ),

            // Content
            SafeArea(
              child: Column(
                children: [
                  // Custom App Bar
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Geçmiş Nöbetler',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 44),
                      ],
                    ),
                  ),

                  // Tab Bar
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      indicator: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelColor: Colors.black87,
                      unselectedLabelColor: Colors.white,
                      tabs: [
                        Tab(text: "Normal Nöbetler"),
                        Tab(text: "Kritik Nöbetler"),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // Tab Content
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildNobetListesi('gerceklesen_nobet', false),
                        _buildNobetListesi('kritik_nobet', true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNobetListesi(String fieldName, bool isKritik) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('hastalar').doc(widget.userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.amber),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Hata: ${snapshot.error}',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(
            child: Text(
              'Veri bulunamadı',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final nobetler = userData[fieldName] as List<dynamic>?;

        if (nobetler == null || nobetler.isEmpty) {
          return Center(
            child: Container(
              padding: EdgeInsets.all(24),
              margin: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history,
                    size: 50,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  SizedBox(height: 16),
                  Text(
                    isKritik 
                        ? 'Kayıtlı kritik nöbet bulunamadı'
                        : 'Kayıtlı nöbet bulunamadı',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(20),
          itemCount: nobetler.length,
          itemBuilder: (context, index) {
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isKritik 
                      ? Colors.red.withOpacity(0.3)
                      : Colors.white.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isKritik
                          ? Colors.red.withOpacity(0.2)
                          : Colors.amber.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isKritik ? Colors.red : Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      nobetler[index].toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: isKritik ? Colors.red : Colors.amber,
                  ),
                ],
              ),
            ).animate(delay: Duration(milliseconds: 100 * index))
              .fadeIn(duration: 400.ms)
              .slideX(begin: 0.3);
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }
}