String formatLastTwoWords(String fullName) {
  final words = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((item) => item.isNotEmpty)
      .toList();

  if (words.isEmpty) return 'Nguoi dung';
  if (words.length == 1) return words.first;
  return '${words[words.length - 2]} ${words.last}';
}

String formatReadableAddress({
  String fullAddress = '',
  String preferredLocation = '',
  String district = '',
  String province = '',
}) {
  if (fullAddress.trim().isNotEmpty) {
    return fullAddress.trim();
  }

  if (preferredLocation.trim().isNotEmpty) {
    return preferredLocation.trim();
  }

  final parts = <String>[
    if (district.trim().isNotEmpty) district.trim(),
    if (province.trim().isNotEmpty) province.trim(),
  ];

  if (parts.isEmpty) return 'Chua cap nhat dia chi';
  return parts.join(', ');
}
