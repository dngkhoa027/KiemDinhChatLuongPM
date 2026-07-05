/// ============================================================
/// DỮ LIỆU ĐỊA GIỚI HÀNH CHÍNH VIỆT NAM (bản trước sáp nhập 2025)
/// ------------------------------------------------------------
/// Cấu trúc 3 cấp quen thuộc: Tỉnh/Thành phố -> Quận/Huyện -> Phường/Xã.
/// Danh sách 63 tỉnh/thành là chính xác. Danh sách quận/huyện, phường/xã
/// bên dưới là DỮ LIỆU MẪU (curated cho các thành phố lớn, phần còn lại
/// dùng dữ liệu rút gọn) để phục vụ chọn nhanh trong app demo, tương tự
/// cách MockData mô phỏng sản phẩm/đơn hàng ở nơi khác trong dự án.
/// ============================================================
class VnDistrict {
  final String name;
  final List<String> wards;
  const VnDistrict({required this.name, required this.wards});
}

class VnProvince {
  final String name;
  final List<VnDistrict> districts;
  const VnProvince({required this.name, required this.districts});
}

class VnLocationData {
  static final List<VnProvince> provinces = _build();

  static List<String> get provinceNames => provinces.map((p) => p.name).toList();

  static List<String> districtsOf(String provinceName) {
    final match = provinces.where((p) => p.name == provinceName);
    return match.isEmpty ? const [] : match.first.districts.map((d) => d.name).toList();
  }

  static List<String> wardsOf(String provinceName, String districtName) {
    final province = provinces.where((p) => p.name == provinceName);
    if (province.isEmpty) return const [];
    final district = province.first.districts.where((d) => d.name == districtName);
    return district.isEmpty ? const [] : district.first.wards;
  }

  // ---- 63 tỉnh/thành trước sáp nhập ----
  static const List<String> _allProvinceNames = [
    'An Giang', 'Bà Rịa - Vũng Tàu', 'Bạc Liêu', 'Bắc Giang', 'Bắc Kạn', 'Bắc Ninh',
    'Bến Tre', 'Bình Dương', 'Bình Định', 'Bình Phước', 'Bình Thuận', 'Cà Mau',
    'Cao Bằng', 'Cần Thơ', 'Đà Nẵng', 'Đắk Lắk', 'Đắk Nông', 'Điện Biên', 'Đồng Nai',
    'Đồng Tháp', 'Gia Lai', 'Hà Giang', 'Hà Nam', 'Hà Nội', 'Hà Tĩnh', 'Hải Dương',
    'Hải Phòng', 'Hậu Giang', 'Hòa Bình', 'Hưng Yên', 'Khánh Hòa', 'Kiên Giang',
    'Kon Tum', 'Lai Châu', 'Lâm Đồng', 'Lạng Sơn', 'Lào Cai', 'Long An', 'Nam Định',
    'Nghệ An', 'Ninh Bình', 'Ninh Thuận', 'Phú Thọ', 'Phú Yên', 'Quảng Bình',
    'Quảng Nam', 'Quảng Ngãi', 'Quảng Ninh', 'Quảng Trị', 'Sóc Trăng', 'Sơn La',
    'Tây Ninh', 'Thái Bình', 'Thái Nguyên', 'Thanh Hóa', 'Thừa Thiên Huế', 'Tiền Giang',
    'TP. Hồ Chí Minh', 'Trà Vinh', 'Tuyên Quang', 'Vĩnh Long', 'Vĩnh Phúc', 'Yên Bái',
  ];

  static List<VnProvince> _build() {
    // Dữ liệu quận/huyện + phường/xã đầy đủ cho các thành phố lớn, hay được
    // dùng để đặt hàng nhất trong app demo.
    final curated = <VnProvince>[
      VnProvince(name: 'TP. Hồ Chí Minh', districts: [
        VnDistrict(name: 'Quận 1', wards: ['Phường Bến Nghé', 'Phường Bến Thành', 'Phường Đa Kao', 'Phường Nguyễn Thái Bình']),
        VnDistrict(name: 'Quận 3', wards: ['Phường Võ Thị Sáu', 'Phường 4', 'Phường 5', 'Phường 14']),
        VnDistrict(name: 'Quận 7', wards: ['Phường Tân Phong', 'Phường Tân Phú', 'Phường Phú Thuận']),
        VnDistrict(name: 'Bình Thạnh', wards: ['Phường 1', 'Phường 13', 'Phường 25', 'Phường 26']),
        VnDistrict(name: 'Tân Bình', wards: ['Phường 1', 'Phường 4', 'Phường 15']),
        VnDistrict(name: 'Thủ Đức', wards: ['Phường Linh Trung', 'Phường Hiệp Bình Chánh', 'Phường Trường Thọ']),
        VnDistrict(name: 'Bình Chánh', wards: ['Thị trấn Tân Túc', 'Xã Vĩnh Lộc A', 'Xã Bình Hưng']),
      ]),
      VnProvince(name: 'Hà Nội', districts: [
        VnDistrict(name: 'Hoàn Kiếm', wards: ['Phường Hàng Trống', 'Phường Hàng Bạc', 'Phường Cửa Nam']),
        VnDistrict(name: 'Ba Đình', wards: ['Phường Điện Biên', 'Phường Ngọc Hà', 'Phường Kim Mã']),
        VnDistrict(name: 'Đống Đa', wards: ['Phường Cát Linh', 'Phường Khâm Thiên', 'Phường Trung Liệt']),
        VnDistrict(name: 'Cầu Giấy', wards: ['Phường Dịch Vọng', 'Phường Nghĩa Đô', 'Phường Yên Hòa']),
        VnDistrict(name: 'Hà Đông', wards: ['Phường Mộ Lao', 'Phường Yết Kiêu', 'Phường Vạn Phúc']),
        VnDistrict(name: 'Long Biên', wards: ['Phường Ngọc Thụy', 'Phường Bồ Đề', 'Phường Việt Hưng']),
      ]),
      VnProvince(name: 'Đà Nẵng', districts: [
        VnDistrict(name: 'Hải Châu', wards: ['Phường Thạch Thang', 'Phường Hải Châu 1', 'Phường Nam Dương']),
        VnDistrict(name: 'Thanh Khê', wards: ['Phường Thanh Khê Đông', 'Phường Xuân Hà', 'Phường Tam Thuận']),
        VnDistrict(name: 'Sơn Trà', wards: ['Phường An Hải Bắc', 'Phường Mân Thái', 'Phường Nại Hiên Đông']),
        VnDistrict(name: 'Ngũ Hành Sơn', wards: ['Phường Mỹ An', 'Phường Khuê Mỹ']),
      ]),
      VnProvince(name: 'Hải Phòng', districts: [
        VnDistrict(name: 'Hồng Bàng', wards: ['Phường Quang Trung', 'Phường Hoàng Văn Thụ']),
        VnDistrict(name: 'Lê Chân', wards: ['Phường An Biên', 'Phường Cát Dài']),
        VnDistrict(name: 'Ngô Quyền', wards: ['Phường Máy Tơ', 'Phường Cầu Đất']),
      ]),
      VnProvince(name: 'Cần Thơ', districts: [
        VnDistrict(name: 'Ninh Kiều', wards: ['Phường Tân An', 'Phường An Hòa', 'Phường Xuân Khánh']),
        VnDistrict(name: 'Cái Răng', wards: ['Phường Lê Bình', 'Phường Hưng Phú']),
      ]),
      VnProvince(name: 'Bình Dương', districts: [
        VnDistrict(name: 'Thủ Dầu Một', wards: ['Phường Phú Cường', 'Phường Hiệp Thành']),
        VnDistrict(name: 'Dĩ An', wards: ['Phường Dĩ An', 'Phường Tân Đông Hiệp']),
        VnDistrict(name: 'Thuận An', wards: ['Phường Lái Thiêu', 'Phường An Phú']),
      ]),
      VnProvince(name: 'Đồng Nai', districts: [
        VnDistrict(name: 'Biên Hòa', wards: ['Phường Tân Phong', 'Phường Trảng Dài', 'Phường Hố Nai']),
        VnDistrict(name: 'Long Khánh', wards: ['Phường Xuân An', 'Phường Xuân Trung']),
      ]),
      VnProvince(name: 'Khánh Hòa', districts: [
        VnDistrict(name: 'Nha Trang', wards: ['Phường Vĩnh Hải', 'Phường Phước Long', 'Phường Lộc Thọ']),
        VnDistrict(name: 'Cam Ranh', wards: ['Phường Cam Nghĩa', 'Phường Cam Phú']),
      ]),
      VnProvince(name: 'Thừa Thiên Huế', districts: [
        VnDistrict(name: 'TP. Huế', wards: ['Phường Phú Nhuận', 'Phường Vĩnh Ninh', 'Phường Thuận Lộc']),
      ]),
    ];

    final curatedNames = curated.map((p) => p.name).toSet();
    final generated = _allProvinceNames.where((n) => !curatedNames.contains(n)).map((name) {
      return VnProvince(name: name, districts: [
        VnDistrict(name: 'Thành phố $name', wards: ['Phường 1', 'Phường 2', 'Phường 3']),
        VnDistrict(name: 'Huyện Trung Tâm', wards: ['Thị trấn Trung Tâm', 'Xã Trung Tâm 1', 'Xã Trung Tâm 2']),
        VnDistrict(name: 'Huyện Ngoại Ô', wards: ['Xã Ngoại Ô 1', 'Xã Ngoại Ô 2', 'Xã Ngoại Ô 3']),
      ]);
    });

    final all = [...curated, ...generated];
    all.sort((a, b) => a.name.compareTo(b.name));
    return all;
  }
}
