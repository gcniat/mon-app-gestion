class AppCurrency {
  final String code;
  final String symbol;
  final String name;

  const AppCurrency({
    required this.code,
    required this.symbol,
    required this.name,
  });

  static const List<AppCurrency> all = [
    AppCurrency(code: 'USD', symbol: '\$',    name: 'Dollar américain (USD)'),
    AppCurrency(code: 'CAD', symbol: 'CA\$',  name: 'Dollar canadien (CAD)'),
    AppCurrency(code: 'EUR', symbol: '€',     name: 'Euro (EUR)'),
    AppCurrency(code: 'GBP', symbol: '£',     name: 'Livre sterling (GBP)'),
    AppCurrency(code: 'CHF', symbol: 'CHF',   name: 'Franc suisse (CHF)'),
    AppCurrency(code: 'XOF', symbol: 'FCFA',  name: 'Franc CFA UEMOA (XOF)'),
    AppCurrency(code: 'XAF', symbol: 'FCFA',  name: 'Franc CFA CEMAC (XAF)'),
    AppCurrency(code: 'MAD', symbol: 'MAD',   name: 'Dirham marocain (MAD)'),
    AppCurrency(code: 'DZD', symbol: 'DA',    name: 'Dinar algérien (DZD)'),
    AppCurrency(code: 'TND', symbol: 'DT',    name: 'Dinar tunisien (TND)'),
    AppCurrency(code: 'HTG', symbol: 'G',     name: 'Gourde haïtienne (HTG)'),
    AppCurrency(code: 'CDF', symbol: 'FC',    name: 'Franc congolais (CDF)'),
  ];

  static AppCurrency fromCode(String code) =>
      all.firstWhere((c) => c.code == code, orElse: () => all.first);

  @override
  bool operator ==(Object other) => other is AppCurrency && other.code == code;

  @override
  int get hashCode => code.hashCode;
}
