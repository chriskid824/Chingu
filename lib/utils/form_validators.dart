class FormValidators {
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '請輸入電子郵件';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return '請輸入有效的電子郵件';
    }
    return null;
  }

  static String? validatePassword(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return '請輸入密碼';
    }
    if (value.length < minLength) {
      return '密碼至少需要 $minLength 個字元';
    }
    return null;
  }

  static String? validateRequired(String? value, String errorMessage) {
    if (value == null || value.trim().isEmpty) {
      return errorMessage;
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return '請再次輸入密碼';
    }
    if (value != password) {
      return '密碼不一致';
    }
    return null;
  }

  static String? validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '請輸入年齡';
    }
    final age = int.tryParse(value);
    if (age == null || age < 18 || age > 100) {
      return '請輸入有效的年齡 (18-100)';
    }
    return null;
  }
}
