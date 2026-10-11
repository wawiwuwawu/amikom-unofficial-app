class ValueLabelOption {
  final String value;
  final String label;

  ValueLabelOption({
    required this.value,
    required this.label,
  });

  factory ValueLabelOption.fromJson(Map<String, dynamic> json) =>
      ValueLabelOption(
        value: json['value']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
      );
}
