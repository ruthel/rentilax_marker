class Currency {
  final String name;
  final String code;
  final String symbol;

  const Currency({required this.name, required this.code, required this.symbol});

  @override
  String toString() => '$name ($code)';
}

const List<Currency> currencies = [
  Currency(name: 'US Dollar', code: 'USD', symbol: '\$'),
  Currency(name: 'Euro', code: 'EUR', symbol: '€'),
  Currency(name: 'Japanese Yen', code: 'JPY', symbol: '¥'),
  Currency(name: 'British Pound', code: 'GBP', symbol: '£'),
  Currency(name: 'Australian Dollar', code: 'AUD', symbol: '\$'),
  Currency(name: 'Canadian Dollar', code: 'CAD', symbol: '\$'),
  Currency(name: 'Swiss Franc', code: 'CHF', symbol: 'CHF'),
  Currency(name: 'Chinese Yuan', code: 'CNY', symbol: '¥'),
  Currency(name: 'Swedish Krona', code: 'SEK', symbol: 'kr'),
  Currency(name: 'New Zealand Dollar', code: 'NZD', symbol: '\$'),
  Currency(name: 'Mexican Peso', code: 'MXN', symbol: '\$'),
  Currency(name: 'Singapore Dollar', code: 'SGD', symbol: '\$'),
  Currency(name: 'Hong Kong Dollar', code: 'HKD', symbol: '\$'),
  Currency(name: 'Norwegian Krone', code: 'NOK', symbol: 'kr'),
  Currency(name: 'South Korean Won', code: 'KRW', symbol: '₩'),
  Currency(name: 'Turkish Lira', code: 'TRY', symbol: '₺'),
  Currency(name: 'Russian Ruble', code: 'RUB', symbol: '₽'),
  Currency(name: 'Indian Rupee', code: 'INR', symbol: '₹'),
  Currency(name: 'Brazilian Real', code: 'BRL', symbol: 'R\$'),
  Currency(name: 'South African Rand', code: 'ZAR', symbol: 'R'),
  Currency(name: 'Philippine Peso', code: 'PHP', symbol: '₱'),
  Currency(name: 'Czech Koruna', code: 'CZK', symbol: 'Kč'),
  Currency(name: 'Indonesian Rupiah', code: 'IDR', symbol: 'Rp'),
  Currency(name: 'Malaysian Ringgit', code: 'MYR', symbol: 'RM'),
  Currency(name: 'Hungarian Forint', code: 'HUF', symbol: 'Ft'),
  Currency(name: 'Icelandic Króna', code: 'ISK', symbol: 'kr'),
  Currency(name: 'Croatian Kuna', code: 'HRK', symbol: 'kn'),
  Currency(name: 'Bulgarian Lev', code: 'BGN', symbol: 'лв'),
  Currency(name: 'Danish Krone', code: 'DKK', symbol: 'kr'),
  Currency(name: 'Polish Złoty', code: 'PLN', symbol: 'zł'),
  Currency(name: 'Romanian Leu', code: 'RON', symbol: 'lei'),
  Currency(name: 'Thai Baht', code: 'THB', symbol: '฿'),
  Currency(name: 'Israeli New Shekel', code: 'ILS', symbol: '₪'),
  Currency(name: 'CFA Franc BCEAO', code: 'XOF', symbol: 'CFA'),
  Currency(name: 'CFA Franc BEAC', code: 'XAF', symbol: 'CFA'),
];
