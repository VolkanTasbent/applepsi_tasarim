import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import 'dashboard.dart';
import 'kayit_ekrani.dart';

class GirisEkrani extends StatefulWidget {
  @override
  _GirisEkraniState createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> 
    with TickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool isLoading = false;
  bool _showSuccess = false;
  bool _rememberMe = false;
  String? doktorAdi;
  
  // Validation states
  bool _isEmailValid = false;
  bool _isPasswordValid = false;
  int _currentStep = 0;

  // Animation controllers - nullable to prevent late initialization error
  AnimationController? _particleController;
  AnimationController? _successController;
  AnimationController? _shakeController;
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
        duration: Duration(seconds: 25),
        vsync: this,
      );
      
      _successController = AnimationController(
        duration: Duration(milliseconds: 2000),
        vsync: this,
      );

      _shakeController = AnimationController(
        duration: Duration(milliseconds: 500),
        vsync: this,
      );

      // Start particle animation
      _particleController?.repeat();
    } catch (e) {
      print('Animation initialization error: $e');
    }
  }

  void _generateParticles() {
    _particles = List.generate(12, (index) {
      return Particle(
        x: math.Random().nextDouble(),
        y: math.Random().nextDouble(),
        size: math.Random().nextDouble() * 3 + 1.5,
        speed: math.Random().nextDouble() * 0.3 + 0.1,
      );
    });
  }

  void _validateInputs() {
    setState(() {
      _isEmailValid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
          .hasMatch(emailController.text);
      _isPasswordValid = passwordController.text.length >= 6;
      
      // Update progress
      int validFields = 0;
      if (_isEmailValid) validFields++;
      if (_isPasswordValid) validFields++;
      _currentStep = validFields;
    });
  }

  void girisYap() async {
    if (!_formKey.currentState!.validate()) {
      _shakeController?.forward().then((_) => _shakeController?.reset());
      return;
    }

    setState(() => isLoading = true);
    
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('hastalar')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        var data = userDoc.data() as Map<String, dynamic>?;
        if (data != null) {
          String? doktorUid = data['doktorUid'];
          if (doktorUid != null) {
            DocumentSnapshot doktorDoc = await FirebaseFirestore.instance
                .collection('doktorlar')
                .doc(doktorUid)
                .get();

            if (doktorDoc.exists) {
              var doktorData = doktorDoc.data() as Map<String, dynamic>?;
              setState(() {
                doktorAdi = doktorData?['name'] ?? 'Doktor Adı Bulunamadı';
              });
            }
          }

          // Success animation
          setState(() => _showSuccess = true);
          _successController?.forward();
          
          await Future.delayed(Duration(milliseconds: 2000));

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DashboardEkrani(userId: userCredential.user!.uid),
              ),
            );
          }
        }
      } else {
        _showSnackBar('Kullanıcı bilgileri bulunamadı', Colors.orange);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Giriş başarısız";
      Color errorColor = Colors.red;
      
      if (e.code == 'user-not-found') {
        errorMessage = "Bu e-posta ile kayıtlı kullanıcı bulunamadı";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Hatalı şifre girdiniz";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Geçersiz e-posta adresi";
      } else if (e.code == 'too-many-requests') {
        errorMessage = "Çok fazla başarısız deneme. Lütfen daha sonra tekrar deneyin";
        errorColor = Colors.orange;
      }
      
      _showSnackBar(errorMessage, errorColor);
      _shakeController?.forward().then((_) => _shakeController?.reset());
    } catch (e) {
      _showSnackBar('Beklenmeyen bir hata oluştu', Colors.red);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                color == Colors.red ? Icons.error : Icons.warning,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  Widget _buildProgressIndicator() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            'Giriş İlerlemesi',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(2, (index) {
              bool isActive = index < _currentStep;
              bool isCurrent = index == _currentStep;
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 6),
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
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
          SizedBox(height: 6),
          Text(
            '${_currentStep}/2 Alan Tamamlandı',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 11,
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
      margin: EdgeInsets.symmetric(vertical: 10),
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
          fillColor: Colors.white.withOpacity(0.12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.amber, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.8)),
          suffixIcon: controller.text.isNotEmpty
              ? Icon(
                  isValid ? Icons.check_circle : Icons.error,
                  color: isValid ? Colors.green : Colors.red,
                )
              : null,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
          return null;
        },
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
          
          // Animated Particles - Safe check
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
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: AnimatedBuilder(
                  animation: _shakeController ?? AnimationController(duration: Duration.zero, vsync: this),
                  builder: (context, child) {
                    double shake = _shakeController != null 
                        ? math.sin(_shakeController!.value * math.pi * 8) * 5 
                        : 0;
                    return Transform.translate(
                      offset: Offset(shake, 0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header Section
                            Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.login,
                                    size: 48,
                                    color: Colors.white,
                                  ),
                                ).animate()
                                  .scale(duration: 800.ms, curve: Curves.elasticOut),
                                
                                SizedBox(height: 24),
                                
                                Text(
                                  'Applepsi',
                                  style: const TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 2,
                                  ),
                                ).animate()
                                  .fadeIn(duration: 600.ms)
                                  .slideY(begin: -0.5, curve: Curves.easeOut),
                                
                                SizedBox(height: 8),
                                
                                Text(
                                  'Hesabınıza giriş yapın',
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

                            // Login Form
                            Container(
                              padding: EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                  width: 1,
                                ),
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
                                  // Email Field
                                  _buildFloatingTextField(
                                    controller: emailController,
                                    label: 'E-posta Adresi',
                                    icon: Icons.email_outlined,
                                    isValid: _isEmailValid,
                                    isEmail: true,
                                  ).animate()
                                    .fadeIn(duration: 500.ms, delay: 600.ms)
                                    .slideX(begin: -0.5),

                                  // Password Field
                                  _buildFloatingTextField(
                                    controller: passwordController,
                                    label: 'Şifre',
                                    icon: Icons.lock_outline,
                                    isValid: _isPasswordValid,
                                    isPassword: true,
                                  ).animate()
                                    .fadeIn(duration: 500.ms, delay: 700.ms)
                                    .slideX(begin: 0.5),

                                  SizedBox(height: 16),

                                  // Remember Me & Forgot Password
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: _rememberMe,
                                            onChanged: (value) {
                                              setState(() => _rememberMe = value ?? false);
                                            },
                                            activeColor: Colors.amber,
                                            checkColor: Colors.black87,
                                          ),
                                          Text(
                                            'Beni Hatırla',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.8),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _showSnackBar('Şifre sıfırlama özelliği yakında eklenecek', Colors.blue);
                                        },
                                        child: Text(
                                          'Şifremi Unuttum',
                                          style: TextStyle(
                                            color: Colors.amber,
                                            fontSize: 14,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ).animate()
                                    .fadeIn(duration: 500.ms, delay: 800.ms),
                                ],
                              ),
                            ).animate()
                              .fadeIn(duration: 600.ms, delay: 500.ms)
                              .slideY(begin: 0.3),

                            SizedBox(height: 32),

                            // Login Button
                            Container(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : girisYap,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.black87,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 8,
                                  shadowColor: Colors.amber.withOpacity(0.4),
                                ),
                                child: isLoading
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
                                            'Giriş Yapılıyor...',
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
                                          Icon(Icons.login, size: 20),
                                          SizedBox(width: 8),
                                          Text(
                                            'Giriş Yap',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ).animate()
                              .fadeIn(duration: 400.ms, delay: 900.ms)
                              .slideY(begin: 0.5)
                              .then()
                              .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.3)),

                            SizedBox(height: 24),

                            // Register Link
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => KayitOlSayfasi()),
                                );
                              },
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(fontSize: 14),
                                  children: [
                                    TextSpan(
                                      text: 'Hesabınız yok mu? ',
                                      style: TextStyle(color: Colors.white.withOpacity(0.8)),
                                    ),
                                    TextSpan(
                                      text: 'Kayıt Olun',
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
                              .fadeIn(duration: 600.ms, delay: 1000.ms),

                            // Doctor Info
                            if (doktorAdi != null)
                              Container(
                                margin: EdgeInsets.only(top: 20),
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.medical_services, color: Colors.green),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Seçilen Doktor: $doktorAdi',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate()
                                .fadeIn(duration: 500.ms)
                                .slideY(begin: 0.3),
                          ],
                        ),
                      ),
                    );
                  },
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
                        'Giriş Başarılı!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ).animate(controller: _successController)
                        .fadeIn(duration: 800.ms, delay: 600.ms)
                        .slideY(begin: 0.5),
                      
                      SizedBox(height: 10),
                      
                      Text(
                        'Dashboard\'a yönlendiriliyorsunuz...',
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
    emailController.dispose();
    passwordController.dispose();
    _particleController?.dispose();
    _successController?.dispose();
    _shakeController?.dispose();
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
      ..color = Colors.white.withOpacity(0.08)
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