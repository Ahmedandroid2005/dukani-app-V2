import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A payment rail specific to one or more countries (mada, KNET, Fawry...) —
/// distinct from the generic "card" option every country already gets.
class LocalPaymentMethod {
  const LocalPaymentMethod({required this.id, required this.label, required this.icon});
  final String id;
  final String label;
  final IconData icon;
}

const _mada = LocalPaymentMethod(id: 'mada', label: 'مدى', icon: LucideIcons.creditCard);
const _stcPay = LocalPaymentMethod(id: 'stc_pay', label: 'STC Pay', icon: LucideIcons.smartphone);
const _knet = LocalPaymentMethod(id: 'knet', label: 'KNET', icon: LucideIcons.creditCard);
const _benefit = LocalPaymentMethod(id: 'benefit', label: 'Benefit', icon: LucideIcons.creditCard);
const _omanNet = LocalPaymentMethod(id: 'omannet', label: 'OmanNet', icon: LucideIcons.creditCard);
const _fawry = LocalPaymentMethod(id: 'fawry', label: 'فوري', icon: LucideIcons.store);
const _meeza = LocalPaymentMethod(id: 'meeza', label: 'ميزة', icon: LucideIcons.creditCard);
const _eWallet = LocalPaymentMethod(id: 'e_wallet', label: 'محفظة إلكترونية', icon: LucideIcons.wallet);

/// Local payment rails per country, on top of the cash/card/Apple Pay/
/// Google Pay/split every store already gets regardless of location. Only
/// lists rails Dukani's target gateways (Tap, PayTabs, Paymob) actually
/// route in that country — no invented or unconfirmed methods.
const Map<String, List<LocalPaymentMethod>> localPaymentMethodsByCountry = {
  'SA': [_mada, _stcPay],
  'AE': [],
  'KW': [_knet],
  'BH': [_benefit],
  'OM': [_omanNet],
  'QA': [],
  'EG': [_fawry, _meeza, _eWallet],
  'JO': [],
};

List<LocalPaymentMethod> localPaymentMethodsFor(String countryCode) => localPaymentMethodsByCountry[countryCode] ?? const [];
