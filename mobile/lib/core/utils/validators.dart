String? validateRequired(String? value, {String fieldName = 'Bu alan'}) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName boş bırakılamaz';
  }
  return null;
}

String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'E-posta boş bırakılamaz';
  }
  final String email = value.trim();
  final RegExp emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!emailRegex.hasMatch(email)) {
    return 'Geçerli bir e-posta adresi girin';
  }
  return null;
}

String? validatePassword(String? value, {int minLength = 8}) {
  if (value == null || value.isEmpty) {
    return 'Şifre boş bırakılamaz';
  }
  if (value.length < minLength) {
    return 'Şifre en az $minLength karakter olmalıdır';
  }
  // Backend requirement: must contain at least one letter
  if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
    return 'Şifre en az bir harf içermelidir';
  }
  // Backend requirement: must contain at least one number
  if (!RegExp(r'[0-9]').hasMatch(value)) {
    return 'Şifre en az bir rakam içermelidir';
  }
  return null;
}

String? validateStudentNumber(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Öğrenci numarası gerekli';
  }
  if (value.length != 9) {
    return '9 haneli olmalı';
  }
  if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
    return 'Sadece rakam içermelidir';
  }
  return null;
}
