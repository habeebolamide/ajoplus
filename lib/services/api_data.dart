import 'api_client.dart';

class ApiData {
  static Map<String, Object?> object(Object? value) {
    if (value is! Map) {
      throw const ApiException('The server returned invalid data.');
    }
    try {
      return Map<String, Object?>.from(value);
    } on TypeError {
      throw const ApiException('The server returned invalid data.');
    }
  }

  static List<Object?> array(Object? value) {
    if (value is! List) {
      throw const ApiException('The server returned invalid data.');
    }
    return value;
  }

  static String string(Map<String, Object?> data, String key) {
    final value = data[key];
    if (value is! String) {
      throw const ApiException('The server returned invalid data.');
    }
    return value;
  }

  static String id(Map<String, Object?> data, String key) {
    final value = data[key];
    if (value is int && value > 0) return value.toString();
    throw const ApiException('The server returned invalid data.');
  }

  static int integer(Map<String, Object?> data, String key) {
    final value = data[key];
    if (value is int) return value;
    throw const ApiException('The server returned invalid data.');
  }

  static int kobo(Map<String, Object?> data, String key) {
    final amount = integer(data, key);
    if (amount < 0) {
      throw const ApiException('The server returned an invalid amount.');
    }
    return amount;
  }

  static String oneOf(
    Map<String, Object?> data,
    String key,
    List<String> allowed,
  ) {
    final value = string(data, key);
    if (!allowed.contains(value)) {
      throw const ApiException('The server returned an unsupported value.');
    }
    return value;
  }

  static DateTime date(Map<String, Object?> data, String key) {
    final parsed = DateTime.tryParse(string(data, key));
    if (parsed == null) {
      throw const ApiException('The server returned invalid dates.');
    }
    return parsed;
  }

  static DateTime? optionalDate(Map<String, Object?> data, String key) {
    if (data[key] == null) return null;
    return date(data, key);
  }

  static String optionalString(Map<String, Object?> data, String key) {
    if (data[key] == null) return '';
    return string(data, key);
  }
}
