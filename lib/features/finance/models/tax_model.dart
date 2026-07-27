class TaxRate {
  final String id;
  final String jurisdiction;
  final double rate;

  TaxRate({
    required this.id,
    required this.jurisdiction,
    required this.rate,
  });

  factory TaxRate.fromJson(Map<String, dynamic> json) {
    return TaxRate(
      id: json['id'],
      jurisdiction: json['jurisdiction'],
      rate: json['rate']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jurisdiction': jurisdiction,
      'rate': rate,
    };
  }
}

class CurrencyExchange {
  final String baseCurrency;
  final String targetCurrency;
  final double rate;

  CurrencyExchange({
    required this.baseCurrency,
    required this.targetCurrency,
    required this.rate,
  });

  factory CurrencyExchange.fromJson(Map<String, dynamic> json) {
    return CurrencyExchange(
      baseCurrency: json['baseCurrency'],
      targetCurrency: json['targetCurrency'],
      rate: json['rate']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baseCurrency': baseCurrency,
      'targetCurrency': targetCurrency,
      'rate': rate,
    };
  }
}
