// lib/providers/remittance_rate_store.dart
// Today's rate for India and Indonesia. Used as default for new remittance transactions.

import 'package:decimal/decimal.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemittanceRateStore {
  RemittanceRateStore._();
  static final RemittanceRateStore _instance = RemittanceRateStore._();
  static RemittanceRateStore get instance => _instance;

  // Both rates stored as MYR per 1 unit of foreign (INR or IDR).
  static const _keyIndiaExchange = 'rem_rate_india_exchange';
  static const _keyIndiaFixed = 'rem_rate_india_fixed';
  static const _keyIndonesiaExchange = 'rem_rate_indonesia_exchange';
  static const _keyIndonesiaFixed = 'rem_rate_indonesia_fixed';

  // India: MYR per INR. 0.043 => 1000 INR = 43 MYR.
  Decimal _indiaCustomerRate = Decimal.parse('0.043');
  Decimal _indiaCostRate = Decimal.parse('0.042');
  // Indonesia: MYR per IDR (6 decimals). 0.000230 => 1,000,000 IDR = 230 MYR.
  Decimal _indonesiaCustomerRate = Decimal.parse('0.000230');
  Decimal _indonesiaCostRate = Decimal.parse('0.000229');

  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final ie = prefs.getString(_keyIndiaExchange);
    if (ie != null) _indiaCustomerRate = Decimal.parse(ie);
    final iff = prefs.getString(_keyIndiaFixed);
    if (iff != null) _indiaCostRate = Decimal.parse(iff);
    final ioe = prefs.getString(_keyIndonesiaExchange);
    if (ioe != null) _indonesiaCustomerRate = Decimal.parse(ioe);
    final iof = prefs.getString(_keyIndonesiaFixed);
    if (iof != null) _indonesiaCostRate = Decimal.parse(iof);
    _loaded = true;
  }

  /// Customer rate = MYR per 1 unit foreign (for conversion: MYR = Foreign × Rate).
  Decimal get indiaCustomerRate => _indiaCustomerRate;
  Decimal get indonesiaCustomerRate => _indonesiaCustomerRate;
  /// Cost rate = MYR per 1 unit foreign (for cost & profit: Profit = (Customer - Cost) × Foreign).
  Decimal get indiaCostRate => _indiaCostRate;
  Decimal get indonesiaCostRate => _indonesiaCostRate;

  Future<void> setIndiaRates({required Decimal customer, required Decimal cost}) async {
    _indiaCustomerRate = customer;
    _indiaCostRate = cost;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyIndiaExchange, customer.toString());
    await prefs.setString(_keyIndiaFixed, cost.toString());
  }

  Future<void> setIndonesiaRates({required Decimal customer, required Decimal cost}) async {
    _indonesiaCustomerRate = customer;
    _indonesiaCostRate = cost;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyIndonesiaExchange, customer.toString());
    await prefs.setString(_keyIndonesiaFixed, cost.toString());
  }

  /// Sync in-memory from storage (e.g. after another screen updated).
  Future<void> reload() async {
    _loaded = false;
    await _ensureLoaded();
  }
}
