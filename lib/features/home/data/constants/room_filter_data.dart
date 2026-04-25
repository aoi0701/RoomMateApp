class RoomFilterData {
  static const List<String> provinces = [
    'Thành phố Hồ Chí Minh',
    'Thành phố Cần Thơ',
    'Tỉnh Bình Dương',
    'Thành phố Đà Nẵng',
    'Thành phố Hà Nội',
    'Tỉnh Long An',
    'Tỉnh Vĩnh Long',
    'Tỉnh Tây Ninh',
    'Tỉnh Thừa Thiên Huế',
  ];

  static const Map<String, List<String>> districtsByProvince = {
    'Thành phố Hồ Chí Minh': [
      'Huyện Bình Chánh',
      'Huyện Hóc Môn',
      'Huyện Nhà Bè',
      'Quận 1',
      'Quận 2',
      'Quận 3',
      'Quận 7',
      'Quận 10',
      'Quận 11',
      'Quận 12',
      'Quận Bình Thạnh',
      'Quận Gò Vấp',
      'Quận Phú Nhuận',
      'Thành phố Thủ Đức',
    ],
    'Thành phố Cần Thơ': [
      'Ninh Kiều',
      'Bình Thủy',
      'Cái Răng',
    ],
    'Tỉnh Bình Dương': [
      'Dĩ An',
      'Thuận An',
      'Thủ Dầu Một',
    ],
    'Thành phố Đà Nẵng': [
      'Hải Châu',
      'Thanh Khê',
      'Sơn Trà',
    ],
    'Thành phố Hà Nội': [
      'Ba Đình',
      'Cầu Giấy',
      'Đống Đa',
      'Hai Bà Trưng',
    ],
    'Tỉnh Long An': [
      'Tân An',
      'Bến Lức',
      'Đức Hòa',
    ],
    'Tỉnh Vĩnh Long': [
      'Thành phố Vĩnh Long',
      'Long Hồ',
    ],
    'Tỉnh Tây Ninh': [
      'Thành phố Tây Ninh',
      'Hòa Thành',
    ],
    'Tỉnh Thừa Thiên Huế': [
      'Thành phố Huế',
      'Hương Thủy',
    ],
  };

  static const List<String> roomTypes = [
    'Phòng trọ',
    'Phòng trong nhà nguyên căn',
    'Căn hộ / Chung cư',
    'Phòng master',
    'Phòng thường',
    'Phòng có gác',
    'Phòng không gác',
    'Phòng có nội thất',
    'Phòng không nội thất',
    'Studio (Phòng có nội thất)',
    'Duplex (Phòng có gác và nội thất)',
  ];

  static const List<String> amenities = [
    'Có máy lạnh',
    'Không máy lạnh',
    'Nuôi thú cưng',
    'Có gác',
    'Không gác',
    'Có ban công',
    'Có chỗ để xe',
    'Có nội thất',
    'Có máy giặt',
    'Có bếp',
  ];
}
