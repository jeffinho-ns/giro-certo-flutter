import 'package:flutter/services.dart';

class DocumentValidators {
  static String normalizeDigits(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  static bool isValidCpf(String cpf) {
    final digits = normalizeDigits(cpf);
    if (digits.length != 11) return false;
    if (RegExp(r'^(\d)\1{10}$').hasMatch(digits)) return false;

    final nums = digits.split('').map(int.parse).toList();

    int sum1 = 0;
    for (int i = 0; i < 9; i++) {
      sum1 += nums[i] * (10 - i);
    }
    int d1 = (sum1 * 10) % 11;
    if (d1 == 10) d1 = 0;

    int sum2 = 0;
    for (int i = 0; i < 10; i++) {
      sum2 += nums[i] * (11 - i);
    }
    int d2 = (sum2 * 10) % 11;
    if (d2 == 10) d2 = 0;

    return nums[9] == d1 && nums[10] == d2;
  }

  static bool isValidCnh(String cnh) {
    final digits = normalizeDigits(cnh);
    if (digits.length != 11) return false;
    if (RegExp(r'^(\d)\1{10}$').hasMatch(digits)) return false;

    final nums = digits.split('').map(int.parse).toList();

    int sum1 = 0;
    for (int i = 0; i < 9; i++) {
      sum1 += nums[i] * (9 - i);
    }
    int d1 = sum1 % 11;
    if (d1 >= 10) d1 = 0;

    int sum2 = 0;
    for (int i = 0; i < 9; i++) {
      sum2 += nums[i] * (i + 1);
    }
    sum2 += d1 * 2;
    int d2 = sum2 % 11;
    if (d2 >= 10) d2 = 0;

    return nums[9] == d1 && nums[10] == d2;
  }

  static String? validateCpfOrCnh(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe CPF ou CNH';
    }
    final digits = normalizeDigits(value);
    if (digits.length != 11) {
      return 'CPF/CNH deve ter 11 digitos';
    }
    if (isValidCpf(digits) || isValidCnh(digits)) {
      return null;
    }
    return 'CPF/CNH invalido';
  }
}

class CpfCnhInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = DocumentValidators.normalizeDigits(newValue.text);
    final buffer = StringBuffer();
    final maxLength = digits.length > 11 ? 11 : digits.length;

    for (int i = 0; i < maxLength; i++) {
      if (i == 3 || i == 6) {
        buffer.write('.');
      }
      if (i == 9) {
        buffer.write('-');
      }
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
