// Lấy 2 từ cuối của họ tên (VD: "Nguyễn Văn An" → "Văn An") để hiển thị gọn trên card
String formatLastTwoWords(String fullName) {
  final words = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((item) => item.isNotEmpty)
      .toList();

  if (words.isEmpty) return 'Người dùng';
  if (words.length == 1) return words.first;
  return '${words[words.length - 2]} ${words.last}';
}

// Tạo địa chỉ hiển thị từ nhiều nguồn: ưu tiên fullAddress → preferredLocation → district+province
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

  if (parts.isEmpty) return 'Chưa cập nhật địa chỉ';
  return parts.join(', ');
}
