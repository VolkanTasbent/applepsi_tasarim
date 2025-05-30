import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class RandevuAlSayfasi extends StatefulWidget {
  @override
  _RandevuAlSayfasiState createState() => _RandevuAlSayfasiState();
}

class _RandevuAlSayfasiState extends State<RandevuAlSayfasi>
    with TickerProviderStateMixin {
  String? _selectedDoctorUid;
  DateTime? _selectedDate;
  String? _notes;
  List<Map<String, dynamic>> _doctors = [];
  
  // Animation controllers
  AnimationController? _particleController;
  AnimationController? _cardController;
  List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _generateParticles();
    _fetchDoctors();
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

  // Firestore'dan doktorları alıyoruz
  Future<void> _fetchDoctors() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('doktorlar').get();
      setState(() {
        _doctors = querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['docId'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Doktorlar yüklenirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Randevu kaydetme işlemi
  void _randevuAl() async {
    String? patientUid = FirebaseAuth.instance.currentUser?.uid;

    if (_selectedDoctorUid != null && _selectedDate != null && _notes != null && patientUid != null) {
      try {
        await FirebaseFirestore.instance.collection('randevular').add({
          'createdAt': FieldValue.serverTimestamp(),
          'date': Timestamp.fromDate(_selectedDate!),
          'doctorUid': _selectedDoctorUid,
          'notes': _notes,
          'patientUid': patientUid,
          'status': 'pending',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Randevunuz başarıyla alındı!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Randevu alırken bir hata oluştu: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lütfen tüm alanları doldurun'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
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
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Randevu Al',
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
              Icons.calendar_today,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 600.ms)
      .slideY(begin: -0.5);
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // Header Card
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
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.medical_services,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Randevu Oluştur',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Doktorunuzla randevu almak için formu doldurun',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).animate(controller: _cardController)
            .fadeIn(duration: 600.ms)
            .slideY(begin: 0.3),

          SizedBox(height: 24),

          // Doctor Selection Card
          _buildDoctorSelectionCard()
            .animate(controller: _cardController)
            .fadeIn(duration: 600.ms, delay: 200.ms)
            .slideY(begin: 0.3),

          SizedBox(height: 20),

          // Date and Time Selection
          Row(
            children: [
              Expanded(
                child: _buildDateSelectionCard()
                  .animate(controller: _cardController)
                  .fadeIn(duration: 600.ms, delay: 400.ms)
                  .slideX(begin: -0.3),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildTimeSelectionCard()
                  .animate(controller: _cardController)
                  .fadeIn(duration: 600.ms, delay: 500.ms)
                  .slideX(begin: 0.3),
              ),
            ],
          ),

          SizedBox(height: 20),

          // Notes Card
          _buildNotesCard()
            .animate(controller: _cardController)
            .fadeIn(duration: 600.ms, delay: 600.ms)
            .slideY(begin: 0.3),

          SizedBox(height: 24),

          // Submit Button
          _buildSubmitButton()
            .animate(controller: _cardController)
            .fadeIn(duration: 600.ms, delay: 800.ms)
            .scale(begin: Offset(0.8, 0.8)),
        ],
      ),
    );
  }

  Widget _buildDoctorSelectionCard() {
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
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person, color: Colors.blue, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Doktor Seçimi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedDoctorUid,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedDoctorUid = newValue;
                });
              },
              items: _doctors.map<DropdownMenuItem<String>>((Map<String, dynamic> doctor) {
                return DropdownMenuItem<String>(
                  value: doctor['docId'],
                  child: Text(
                    'Dr. ${doctor['name']} ${doctor['surname']} - ${doctor['specialty']}',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              decoration: InputDecoration(
                hintText: 'Doktor seçin',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              dropdownColor: Color(0xFF4A148C),
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelectionCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.calendar_today, color: Colors.green, size: 20),
          ),
          SizedBox(height: 12),
          Text(
            'Tarih',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              DateTime? selectedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(Duration(days: 365)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: Color(0xFF7B1FA2),
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: Colors.black,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (selectedDate != null) {
                setState(() {
                  _selectedDate = selectedDate;
                });
              }
            },
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Text(
                _selectedDate == null
                    ? 'Seçin'
                    : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelectionCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.access_time, color: Colors.orange, size: 20),
          ),
          SizedBox(height: 12),
          Text(
            'Saat',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              if (_selectedDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Önce tarih seçin'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              
              TimeOfDay? selectedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: Color(0xFF7B1FA2),
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: Colors.black,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (selectedTime != null) {
                setState(() {
                  _selectedDate = DateTime(
                    _selectedDate!.year,
                    _selectedDate!.month,
                    _selectedDate!.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );
                });
              }
            },
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Text(
                _selectedDate == null
                    ? 'Seçin'
                    : '${_selectedDate!.hour.toString().padLeft(2, '0')}:${_selectedDate!.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
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
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.note_alt, color: Colors.purple, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Notlar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: TextField(
              onChanged: (value) {
                _notes = value;
              },
              maxLines: 3,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Randevu ile ilgili notlarınızı yazın...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber, Colors.orange],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _randevuAl,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          'Randevu Al',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
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

// Particle System (Same as dashboard)
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