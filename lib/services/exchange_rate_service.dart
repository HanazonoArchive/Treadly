import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Fetches and caches the live USD-to-PHP exchange rate from free,
/// unauthenticated currency APIs so USD tire prices convert accurately.
class ExchangeRateService {
  static final ExchangeRateService instance = ExchangeRateService._internal();
  ExchangeRateService._internal();

  static const double defaultFallbackUsdToPhp = 63.70;
  static const Duration cacheTtl = Duration(hours: 6);
  static const double _minValidRate = 40.0;
  static const double _maxValidRate = 95.0;

  static const String _prefRateKey = 'treadly_usd_php_rate';
  static const String _prefUpdatedAtKey = 'treadly_usd_php_updated_at';
  static const String _prefSourceKey = 'treadly_usd_php_source';

  static const List<({String name, String url})> _providers = [
    (
      name: 'open.er-api.com',
      url: 'https://open.er-api.com/v6/latest/USD',
    ),
    (
      name: 'frankfurter.dev',
      url: 'https://api.frankfurter.dev/v1/latest?base=USD&symbols=PHP',
    ),
    (
      name: 'fawazahmed0/currency-api',
      url:
          'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/usd.json',
    ),
  ];

  final RxDouble usdToPhpRate = defaultFallbackUsdToPhp.obs;
  final Rxn<DateTime> lastUpdatedAt = Rxn<DateTime>();
  final RxString activeSource = 'Offline default'.obs;

  Future<double>? _inFlight;

  double get rate => usdToPhpRate.value;

  static bool isValidRate(double? value) =>
      value != null &&
      value.isFinite &&
      value >= _minValidRate &&
      value <= _maxValidRate;

  /// Parses USD -> PHP from open.er-api.com, frankfurter.dev, or
  /// fawazahmed0/currency-api payloads.
  @visibleForTesting
  static double? parseUsdToPhpRate(dynamic decoded) {
    if (decoded is! Map<String, dynamic>) return null;

    final rates = decoded['rates'];
    if (rates is Map<String, dynamic>) {
      final php = rates['PHP'] ?? rates['php'];
      if (php is num) {
        final val = php.toDouble();
        return isValidRate(val) ? val : null;
      }
    }

    final usd = decoded['usd'];
    if (usd is Map<String, dynamic>) {
      final php = usd['php'] ?? usd['PHP'];
      if (php is num) {
        final val = php.toDouble();
        return isValidRate(val) ? val : null;
      }
    }

    return null;
  }

  /// Ensures a recent live USD -> PHP rate is loaded (using cache when fresh).
  Future<double> ensureLoaded({
    bool forceRefresh = false,
    http.Client? client,
  }) {
    if (!forceRefresh && _inFlight != null) {
      return _inFlight!;
    }
    final future = _loadInternal(forceRefresh: forceRefresh, client: client);
    _inFlight = future.whenComplete(() => _inFlight = null);
    return _inFlight!;
  }

  Future<double> _loadInternal({
    required bool forceRefresh,
    http.Client? client,
  }) async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      final cachedRate = prefs.getDouble(_prefRateKey);
      final cachedAtIso = prefs.getString(_prefUpdatedAtKey);
      final cachedSource = prefs.getString(_prefSourceKey);
      final cachedAt =
          cachedAtIso != null ? DateTime.tryParse(cachedAtIso) : null;

      if (isValidRate(cachedRate)) {
        usdToPhpRate.value = cachedRate!;
        lastUpdatedAt.value = cachedAt;
        activeSource.value = cachedSource ?? 'Cached FX';

        if (!forceRefresh &&
            cachedAt != null &&
            DateTime.now().difference(cachedAt) < cacheTtl) {
          return cachedRate;
        }
      }
    } catch (e) {
      debugPrint('[ExchangeRateService] Cache read note: $e');
    }

    final ownsClient = client == null;
    final httpClient = client ?? http.Client();

    try {
      for (final provider in _providers) {
        try {
          final response = await httpClient
              .get(Uri.parse(provider.url))
              .timeout(const Duration(seconds: 6));

          if (response.statusCode != 200) continue;

          final decoded = jsonDecode(response.body);
          final parsed = parseUsdToPhpRate(decoded);
          if (parsed == null) continue;

          final now = DateTime.now();
          usdToPhpRate.value = parsed;
          lastUpdatedAt.value = now;
          activeSource.value = provider.name;

          try {
            prefs ??= await SharedPreferences.getInstance();
            await prefs.setDouble(_prefRateKey, parsed);
            await prefs.setString(_prefUpdatedAtKey, now.toIso8601String());
            await prefs.setString(_prefSourceKey, provider.name);
          } catch (_) {}

          debugPrint(
            '[ExchangeRateService] Live USD/PHP = $parsed (${provider.name})',
          );
          return parsed;
        } catch (e) {
          debugPrint('[ExchangeRateService] ${provider.name} failed: $e');
        }
      }
    } finally {
      if (ownsClient) {
        httpClient.close();
      }
    }

    return usdToPhpRate.value;
  }

  @visibleForTesting
  void setRateForTest(double rate, {String source = 'Test'}) {
    if (isValidRate(rate)) {
      usdToPhpRate.value = rate;
      activeSource.value = source;
      lastUpdatedAt.value = DateTime.now();
    }
  }

  @visibleForTesting
  void resetForTest() {
    usdToPhpRate.value = defaultFallbackUsdToPhp;
    activeSource.value = 'Offline default';
    lastUpdatedAt.value = null;
    _inFlight = null;
  }
}
