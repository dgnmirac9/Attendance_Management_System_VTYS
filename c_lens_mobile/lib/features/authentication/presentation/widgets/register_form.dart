import 'package:flutter/material.dart';
import '../../../../shared/utils/validators.dart';
import '../../../../routes.dart' as app_routes;

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isStudent = false;
  bool _faceDataAdded = false;
  String? _faceImagePath;
  List<String> _faceImages = <String>[];
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;

  bool get _faceImagesAtLeastThree => _faceImages.length >= 3;
  String get _faceImagesCountStr => '${_faceImages.length}/5';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            color: Colors.white,
            shadowColor: Colors.black.withValues(alpha: 0.25),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final double padding = 4;
                        final double trackHeight = 56;
                        final double segmentWidth = (constraints.maxWidth - (padding * 2)) / 2;
                        return Container(
                          height: trackHeight,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.transparent),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Labels and tap areas
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => setState(() {
                                        _isStudent = false;
                                      }),
                                      child: Center(
                                        child: Text(
                                          'Öğretim Görevlisi',
                                          style: TextStyle(
                                            color: !_isStudent ? Colors.blue.shade800 : Colors.blue.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => setState(() {
                                        _isStudent = true;
                                      }),
                                      child: Center(
                                        child: Text(
                                          'Öğrenci',
                                          style: TextStyle(
                                            color: _isStudent ? Colors.blue.shade800 : Colors.blue.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Sliding empty rounded-rectangle that wraps selected label area
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                                top: padding,
                                bottom: padding,
                                left: _isStudent ? (segmentWidth + padding) : padding,
                                width: segmentWidth,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.blue.shade600, width: 2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            decoration: InputDecoration(
                              labelText: 'Ad',
                              labelStyle: TextStyle(color: Colors.blue.shade800),
                              prefixIcon: Icon(Icons.person, color: Colors.blue.shade600),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(color: Colors.transparent),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(color: Colors.transparent),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.blue.shade50,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            ),
                            validator: (value) => validateRequired(value, fieldName: 'Ad'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration: InputDecoration(
                              labelText: 'Soyad',
                              labelStyle: TextStyle(color: Colors.blue.shade800),
                              prefixIcon: Icon(Icons.person_outline, color: Colors.blue.shade600),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(color: Colors.transparent),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(color: Colors.transparent),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.blue.shade50,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            ),
                            validator: (value) => validateRequired(value, fieldName: 'Soyad'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'E-posta',
                        labelStyle: TextStyle(color: Colors.blue.shade800),
                        prefixIcon: Icon(Icons.email, color: Colors.blue.shade600),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.transparent),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.transparent),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.blue.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: validateEmail,
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        labelStyle: TextStyle(color: Colors.blue.shade800),
                        prefixIcon: Icon(Icons.lock, color: Colors.blue.shade600),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.transparent),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.transparent),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.blue.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                      obscureText: _obscurePassword,
                      validator: validatePassword,
                    ),

                    // Şifre altına: Öğrenciler için yüz verisi ekleme
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordConfirmController,
                      decoration: InputDecoration(
                        labelText: 'Şifre (Tekrar)',
                        labelStyle: TextStyle(color: Colors.blue.shade800),
                        prefixIcon: Icon(Icons.lock, color: Colors.blue.shade600),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePasswordConfirm ? Icons.visibility_off : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _obscurePasswordConfirm = !_obscurePasswordConfirm;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.transparent),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.transparent),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.blue.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                      obscureText: _obscurePasswordConfirm,
                      validator: (value) {
                        final String? v = validatePassword(value);
                        if (v != null) return v;
                        if (value != _passwordController.text) {
                          return 'Şifreler eşleşmiyor';
                        }
                        return null;
                      },
                    ),

                    if (_isStudent) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final dynamic result = await Navigator.pushNamed(
                                  context,
                                  app_routes.Routes.faceCapture,
                                );
                                if (result is List<String> && mounted) {
                                  setState(() {
                                    _faceImages = result;
                                    _faceDataAdded = _faceImages.length >= 3;
                                  });
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('$_faceImagesCountStr yakalandı.')),
                                  );
                                }
                              },
                              icon: Icon(_faceDataAdded ? Icons.check_circle : Icons.face),
                              label: Text(_faceDataAdded ? 'Yüz Verisi Eklendi ($_faceImagesCountStr)' : 'Yüz Verisi Ekle ($_faceImagesCountStr)'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue.shade800,
                                side: BorderSide(color: Colors.blue.shade400),
                                minimumSize: const Size.fromHeight(48),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () {
                          if (!_formKey.currentState!.validate()) {
                            debugPrint('Formda hatalar var.');
                            return;
                          }
                          if (_isStudent && !_faceImagesAtLeastThree) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Lütfen en az 3 yüz verisi ekleyin.')),
                            );
                            return;
                          }
                          final String selectedRole = _isStudent ? 'Öğrenci' : 'Öğretim Görevlisi';
                          debugPrint('Form geçerli. Kayıt işlemi başlıyor...');
                          debugPrint('Seçilen rol: $selectedRole');
                          if (_faceImages.isNotEmpty) {
                            debugPrint('Yüz verisi sayısı: ${_faceImages.length}');
                            for (final String p in _faceImages) {
                              debugPrint(' - $p');
                            }
                          }
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.how_to_reg),
                            SizedBox(width: 8.0),
                            Text(
                              'Kayıt Ol',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


