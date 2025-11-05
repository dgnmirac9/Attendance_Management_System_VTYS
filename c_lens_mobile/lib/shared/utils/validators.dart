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

String? validatePassword(String? value, {int minLength = 6}) {
  if (value == null || value.isEmpty) {
    return 'Şifre boş bırakılamaz';
  }
  if (value.length < minLength) {
    return 'Şifre en az $minLength karakter olmalıdır';
  }
  return null;
}


