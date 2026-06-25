/// Cambodian phone number utilities — formatting, carrier detection, E.164 conversion.
class KhPhoneUtil {
  static const _carriers = {
    'Cellcard': [
      '012',
      '017',
      '061',
      '077',
      '078',
      '085',
      '089',
      '092',
      '095',
      '099',
    ],
    'Smart': [
      '010',
      '015',
      '016',
      '069',
      '070',
      '081',
      '086',
      '087',
      '093',
      '096',
      '098',
    ],
    'Metfone': ['088', '097', '071', '031', '060', '066', '067', '068', '090'],
    'Seatel': ['018'],
    'Cootel': ['038'],
  };

  /// Detect carrier from a local number (with or without leading 0).
  /// e.g. "012345678" → "Cellcard", "0961234567" → "Smart"
  static String? detectCarrier(String localDigits) {
    final d = localDigits.replaceAll(RegExp(r'[^\d]'), '');
    if (d.length < 3) return null;
    final prefix3 = d.substring(0, 3);
    for (final entry in _carriers.entries) {
      if (entry.value.contains(prefix3)) return entry.key;
    }
    return null;
  }

  /// Format a local number with spaces: "012345678" → "012 345 678"
  static String formatLocal(String digits) {
    final d = digits.replaceAll(RegExp(r'[^\d]'), '');
    if (d.isEmpty) return '';
    if (d.length <= 3) return d;
    if (d.length <= 6) return '${d.substring(0, 3)} ${d.substring(3)}';
    return '${d.substring(0, 3)} ${d.substring(3, 6)} ${d.substring(6, d.length > 9 ? 9 : d.length)}';
  }

  /// Convert a Cambodian local number to E.164.
  /// "012 345 678" → "+85512345678"
  static String toE164(String localDigits) {
    final d = localDigits.replaceAll(RegExp(r'[^\d]'), '');
    if (d.startsWith('855')) return '+$d';
    if (d.startsWith('0')) return '+855${d.substring(1)}';
    return '+855$d';
  }
}
