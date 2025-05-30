import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class RandevularimSayfasi extends StatefulWidget {
  const RandevularimSayfasi({super.key});

  @override
  _RandevularimSayfasiState createState() => _RandevularimSayfasiState();
}

class _RandevularimSayfasiState extends State<RandevularimSayfasi> 
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _randevular = [];
  AnimationController? _particleController;
  List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _generateParticles();
    _fetchApprovedRandevular();
  }

  void _initAnimations() {
    try {
      _particleController = AnimationController(
        duration: Duration(seconds: 30),
        vsync: this,
      )..repeat();
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

  Future<void> _fetchApprovedRandevular() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('randevular')
        .where('patientUid', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'approved')
        .orderBy('date', descending: false)
        .get();

    setState(() {
      _randevular = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['docId'] = doc.id;
        return data;
      }).toList();
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
                  child: _randevular.isEmpty
                      ? _buildEmptyState()
                      : _buildRandevuListesi(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
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
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Randevularım',
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
              Icons.calendar_month,
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

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(24),
        margin: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 50,
              color: Colors.white.withOpacity(0.6),
            ),
            SizedBox(height: 20),
            Text(
              "Onaylanmış randevunuz bulunmamaktadır",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              "Yeni randevu oluşturmak için randevu al sayfasını ziyaret edin",
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ).animate()
        .fadeIn(duration: 800.ms)
        .scale(begin: Offset(0.9, 0.9)),
    );
  }

  Widget _buildRandevuListesi() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Onaylanmış Randevular',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.8),
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 16),
          ..._randevular.asMap().entries.map((entry) {
            final index = entry.key;
            final randevu = entry.value;
            final tarih = (randevu['date'] as Timestamp).toDate();
            
            return Container(
              margin: EdgeInsets.only(bottom: 16),
              child: _buildRandevuCard(index, tarih, randevu),
            ).animate(delay: Duration(milliseconds: 100 * index))
              .fadeIn(duration: 400.ms)
              .slideX(begin: 0.3);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRandevuCard(int index, DateTime tarih, Map<String, dynamic> randevu) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Randevu #${index + 1}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${tarih.day}/${tarih.month}/${tarih.year} ${tarih.hour}:${tarih.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (randevu['notes'] != null && randevu['notes'].toString().isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Not:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  randevu['notes'].toString(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _particleController?.dispose();
    super.dispose();
  }
}

// Particle System
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