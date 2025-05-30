import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import 'giris_ekrani.dart';

class KayitOlSayfasi extends StatefulWidget {
  @override
  _KayitOlSayfasiState createState() => _KayitOlSayfasiState();
}

class _KayitOlSayfasiState extends State<KayitOlSayfasi> 
    with TickerProviderStateMixin {
  final TextEditingController _adController = TextEditingController();
  final TextEditingController _soyadController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedDoctorUid;
  List<Map<String, dynamic>> _doctors = [];
  bool _isLoading = false;
  bool _isDoctorsLoading = true;
  bool _showSuccess = false;
  int _currentStep = 0;
  
  // Validation states
  bool _isNameValid = false;
  bool _isSurnameValid = false;
  bool _isEmailValid = false;
  bool _isPasswordValid = false;
  int _passwordStrength = 0;

  // Animation controllers
  late AnimationController _particleController;
  late AnimationController _successController;
  late List<Particle> _particles;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
    _initAnimations();
    _generateParticles();
  }

  void _initAnimations() {
    _particleController = AnimationController(
      duration: Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _successController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
  }

  void _generateParticles() {
    _particles = List.generate(15, (index) {
      return Particle(
        x: math.Random().nextDouble(),
        y: math.Random().nextDouble(),
        size: math.Random().nextDouble() * 4 + 2,
        speed: math.Random().nextDouble() * 0.5 + 0.1,
      );
    });
  }

  Future<void> _fetchDoctors() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('doktorlar').get();
      setState(() {
        _doctors = querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['docId'] = doc.id;
          return data;
        }).toList();
        _isDoctorsLoading = false;
      });
    } catch (e) {
      setState(() => _isDoctorsLoading = false);
    }
  }

  void _validateInputs() {
    setState(() {
      _isNameValid = _adController.text.trim().length >= 2;
      _isSurnameValid = _soyadController.text.trim().length >= 2;
      _isEmailValid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
          .hasMatch(_emailController.text);
      _isPasswordValid = _passwordController.text.length >= 6;
      _passwordStrength = _calculatePasswordStrength(_passwordController.text);
      
      // Update progress
      int validFields = 0;
      if (_isNameValid && _isSurnameValid) validFields++;
      if (_isEmailValid) validFields++;
      if (_isPasswordValid) validFields++;
      if (_selectedDoctorUid != null) validFields++;
      _currentStep = validFields;
    });
  }

  int _calculatePasswordStrength(String password) {
    int strength = 0;
    if (password.length >= 6) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;
    return strength;
  }

  Color _getPasswordStrengthColor() {
    switch (_passwordStrength) {
      case 0:
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow;
      case 4:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getPasswordStrengthText() {
    switch (_passwordStrength) {
      case 0:
      case 1:
        return 'Zayıf';
      case 2:
        return 'Orta';
      case 3:
        return 'İyi';
      case 4:
        return 'Güçlü';
      default:
        return '';
    }
  }

  void _kayitOl() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDoctorUid == null) {
      _showSnackBar('Lütfen bir doktor seçiniz', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await FirebaseFirestore.instance
          .collection('hastalar')
          .doc(userCredential.user!.uid)
          .set({
        'ad': _adController.text.trim(),
        'soyad': _soyadController.text.trim(),
        'email': _emailController.text.trim(),
        'uid': userCredential.user!.uid,
        'doktorUid': _selectedDoctorUid,
        'kayitTarihi': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('doktorlar')
          .doc(_selectedDoctorUid)
          .update({
        'hastalar': FieldValue.arrayUnion([userCredential.user!.uid]),
      });

      // Success animation
      setState(() => _showSuccess = true);
      _successController.forward();
      
      await Future.delayed(Duration(milliseconds: 2500));
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => GirisEkrani()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Kayıt işlemi başarısız oldu';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'Bu e-posta adresi zaten kayıtlı';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Lütfen daha güçlü bir şifre seçiniz';
      }
      _showSnackBar(errorMessage, Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Text(
            'Kayıt İlerlemesi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              bool isActive = index < _currentStep;
              bool isCurrent = index == _currentStep;
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                width: 40,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: isActive 
                      ? Colors.amber 
                      : isCurrent 
                          ? Colors.amber.withOpacity(0.5)
                          : Colors.white.withOpacity(0.3),
                ),
              ).animate(target: isActive ? 1 : 0)
                .scaleX(duration: 300.ms, curve: Curves.easeOut);
            }),
          ),
          SizedBox(height: 8),
          Text(
            '${_currentStep}/4 Adım Tamamlandı',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isValid,
    bool isPassword = false,
    bool isEmail = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        style: TextStyle(color: Colors.white, fontSize: 16),
        onChanged: (_) => _validateInputs(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.amber, width: 2),
          ),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.8)),
          suffixIcon: controller.text.isNotEmpty
              ? Icon(
                  isValid ? Icons.check_circle : Icons.error,
                  color: isValid ? Colors.green : Colors.red,
                )
              : null,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '$label gereklidir';
          }
          if (isEmail && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Geçerli bir e-posta adresi giriniz';
          }
          if (isPassword && value.length < 6) {
            return 'Şifre en az 6 karakter olmalıdır';
          }
          if (!isPassword && !isEmail && value.trim().length < 2) {
            return '$label en az 2 karakter olmalıdır';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    if (_passwordController.text.isEmpty) return SizedBox.shrink();
    
    return Container(
      margin: EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Şifre Gücü: ',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
              ),
              Text(
                _getPasswordStrengthText(),
                style: TextStyle(
                  color: _getPasswordStrengthColor(),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          LinearProgressIndicator(
            value: _passwordStrength / 4,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(_getPasswordStrengthColor()),
          ),
        ],
      ),
    );
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
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlePainter(_particles, _particleController.value),
                size: Size.infinite,
              );
            },
          ),

          // Main Content
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person_add_alt_1,
                              size: 40,
                              color: Colors.white,
                            ),
                          ).animate()
                            .scale(duration: 600.ms, curve: Curves.elasticOut),
                          
                          SizedBox(height: 20),
                          
                          Text(
                            'Hesap Oluşturun',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ).animate()
                            .fadeIn(duration: 600.ms)
                            .slideY(begin: -0.5, curve: Curves.easeOut),
                          
                          SizedBox(height: 8),
                          
                          Text(
                            'Applepsi platformuna katılın',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8),
                              letterSpacing: 0.5,
                            ),
                          ).animate()
                            .fadeIn(duration: 800.ms, delay: 200.ms),
                        ],
                      ),

                      // Progress Indicator
                      _buildProgressIndicator()
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 400.ms),

                      SizedBox(height: 20),

                      // Form Fields
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Name Fields
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFloatingTextField(
                                    controller: _adController,
                                    label: 'Ad',
                                    icon: Icons.person_outline,
                                    isValid: _isNameValid,
                                  ).animate()
                                    .fadeIn(duration: 500.ms, delay: 600.ms)
                                    .slideX(begin: -0.5),
                                ),
                                SizedBox(width: 15),
                                Expanded(
                                  child: _buildFloatingTextField(
                                    controller: _soyadController,
                                    label: 'Soyad',
                                    icon: Icons.person,
                                    isValid: _isSurnameValid,
                                  ).animate()
                                    .fadeIn(duration: 500.ms, delay: 700.ms)
                                    .slideX(begin: 0.5),
                                ),
                              ],
                            ),

                            // Email
                            _buildFloatingTextField(
                              controller: _emailController,
                              label: 'E-posta Adresi',
                              icon: Icons.email_outlined,
                              isValid: _isEmailValid,
                              isEmail: true,
                            ).animate()
                              .fadeIn(duration: 500.ms, delay: 800.ms)
                              .slideX(begin: -0.5),

                            // Password
                            _buildFloatingTextField(
                              controller: _passwordController,
                              label: 'Şifre',
                              icon: Icons.lock_outline,
                              isValid: _isPasswordValid,
                              isPassword: true,
                            ).animate()
                              .fadeIn(duration: 500.ms, delay: 900.ms)
                              .slideX(begin: 0.5),

                            // Password Strength
                            _buildPasswordStrengthIndicator(),

                            SizedBox(height: 16),

                            // Doctor Selection
                            _isDoctorsLoading
                                ? Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.medical_services_outlined, 
                                             color: Colors.white.withOpacity(0.8)),
                                        SizedBox(width: 12),
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation(Colors.amber),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Doktorlar yükleniyor...',
                                          style: TextStyle(color: Colors.white.withOpacity(0.8)),
                                        ),
                                      ],
                                    ),
                                  )
                                : DropdownButtonFormField<String>(
                                    value: _selectedDoctorUid,
                                    decoration: InputDecoration(
                                      labelText: "Doktor Seçiniz",
                                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.15),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: BorderSide(color: Colors.amber, width: 2),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.medical_services_outlined,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                      suffixIcon: _selectedDoctorUid != null
                                          ? Icon(Icons.check_circle, color: Colors.green)
                                          : null,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                    ),
                                    dropdownColor: Color(0xFF4A148C),
                                    style: TextStyle(color: Colors.white),
                                    items: _doctors.map((doctor) {
                                      return DropdownMenuItem<String>(
                                        value: doctor['docId'],
                                        child: Text(
                                          'Dr. ${doctor['name']} ${doctor['surname']}\n${doctor['specialty']}',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() => _selectedDoctorUid = value);
                                      _validateInputs();
                                    },
                                    validator: (value) {
                                      if (value == null) return 'Lütfen bir doktor seçiniz';
                                      return null;
                                    },
                                  ).animate()
                                    .fadeIn(duration: 500.ms, delay: 1000.ms)
                                    .slideY(begin: 0.5),
                          ],
                        ),
                      ).animate()
                        .fadeIn(duration: 600.ms, delay: 500.ms)
                        .slideY(begin: 0.3),

                      SizedBox(height: 30),

                      // Register Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _kayitOl,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 8,
                            shadowColor: Colors.amber.withOpacity(0.4),
                          ),
                          child: _isLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(Colors.black87),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Hesap Oluşturuluyor...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.person_add_alt_1, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Hesap Oluştur',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ).animate()
                        .fadeIn(duration: 400.ms, delay: 1200.ms)
                        .slideY(begin: 0.5)
                        .then()
                        .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.3)),

                      SizedBox(height: 20),

                      // Login Link
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 14),
                            children: [
                              TextSpan(
                                text: 'Zaten hesabınız var mı? ',
                                style: TextStyle(color: Colors.white.withOpacity(0.8)),
                              ),
                              TextSpan(
                                text: 'Giriş Yapın',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate()
                        .fadeIn(duration: 600.ms, delay: 1400.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Success Animation Overlay
          if (_showSuccess)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.8),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          size: 60,
                          color: Colors.white,
                        ),
                      ).animate(controller: _successController)
                        .scale(duration: 600.ms, curve: Curves.elasticOut)
                        .then()
                        .shake(duration: 400.ms),
                      
                      SizedBox(height: 30),
                      
                      Text(
                        'Hesabınız Başarıyla Oluşturuldu!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ).animate(controller: _successController)
                        .fadeIn(duration: 800.ms, delay: 600.ms)
                        .slideY(begin: 0.5),
                      
                      SizedBox(height: 10),
                      
                      Text(
                        'Giriş ekranına yönlendiriliyorsunuz...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ).animate(controller: _successController)
                        .fadeIn(duration: 600.ms, delay: 1000.ms),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _adController.dispose();
    _soyadController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _particleController.dispose();
    _successController.dispose();
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
      ..color = Colors.white.withOpacity(0.1)
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