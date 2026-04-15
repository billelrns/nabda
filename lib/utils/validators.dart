class AppValidators {
  // Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال البريد الإلكتروني';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (\!emailRegex.hasMatch(value)) {
      return 'البريد الإلكتروني غير صحيح';
    }

    return null;
  }

  // Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال كلمة المرور';
    }

    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }

    return null;
  }

  // Validate name
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال الاسم';
    }

    if (value.length < 2) {
      return 'الاسم يجب أن يكون حرفين على الأقل';
    }

    return null;
  }

  // Validate phone number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال رقم الهاتف';
    }

    final phoneRegex = RegExp(r'^[0-9]{10,}$');
    if (\!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[^0-9]'), ''))) {
      return 'رقم الهاتف غير صحيح';
    }

    return null;
  }

  // Validate field is not empty
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال $fieldName';
    }
    return null;
  }

  // Validate confirm password matches
  static String? validatePasswordMatch(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'الرجاء تأكيد كلمة المرور';
    }

    if (value \!= password) {
      return 'كلمات المرور غير متطابقة';
    }

    return null;
  }

  // Validate age
  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال العمر';
    }

    final age = int.tryParse(value);
    if (age == null || age < 13 || age > 120) {
      return 'الرجاء إدخال عمر صحيح';
    }

    return null;
  }

  // Validate cycle length
  static String? validateCycleLength(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال طول الدورة';
    }

    final length = int.tryParse(value);
    if (length == null || length < 21 || length > 35) {
      return 'طول الدورة يجب أن يكون بين 21 و 35 يوم';
    }

    return null;
  }
}
