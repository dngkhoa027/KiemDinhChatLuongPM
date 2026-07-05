import 'package:flutter/material.dart';
import '../../data/vn_location_data.dart';

/// Kết quả trả về sau khi chọn xong Tỉnh/Thành + Quận/Huyện + Phường/Xã.
class LocationPickResult {
  final String province;
  final String district;
  final String ward;
  const LocationPickResult({required this.province, required this.district, required this.ward});
}

/// Bottom sheet chọn địa chỉ 3 bước kiểu Shopee: Tỉnh/Thành phố -> Quận/Huyện
/// -> Phường/Xã, mỗi bước tự chuyển sang bước tiếp theo sau khi chọn.
class LocationPickerSheet extends StatefulWidget {
  final String? initialProvince;
  final String? initialDistrict;

  const LocationPickerSheet({super.key, this.initialProvince, this.initialDistrict});

  static Future<LocationPickResult?> show(
    BuildContext context, {
    String? initialProvince,
    String? initialDistrict,
  }) {
    return showModalBottomSheet<LocationPickResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LocationPickerSheet(initialProvince: initialProvince, initialDistrict: initialDistrict),
    );
  }

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  static const Color ink = Color(0xFF1D1D1F);

  late int _step; // 0 = tỉnh/thành, 1 = quận/huyện, 2 = phường/xã
  String? _selectedProvince;
  String? _selectedDistrict;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedProvince = widget.initialProvince;
    _selectedDistrict = widget.initialDistrict;
    _step = 0;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<String> get _currentOptions {
    final query = _searchCtrl.text.trim().toLowerCase();
    List<String> source;
    switch (_step) {
      case 0:
        source = VnLocationData.provinceNames;
        break;
      case 1:
        source = VnLocationData.districtsOf(_selectedProvince ?? '');
        break;
      default:
        source = VnLocationData.wardsOf(_selectedProvince ?? '', _selectedDistrict ?? '');
    }
    if (query.isEmpty) return source;
    return source.where((e) => e.toLowerCase().contains(query)).toList();
  }

  void _onPickProvince(String province) {
    setState(() {
      _selectedProvince = province;
      _step = 1;
      _searchCtrl.clear();
    });
  }

  void _onPickDistrict(String district) {
    setState(() {
      _selectedDistrict = district;
      _step = 2;
      _searchCtrl.clear();
    });
  }

  void _onPickWard(String ward) {
    Navigator.pop(
      context,
      LocationPickResult(province: _selectedProvince!, district: _selectedDistrict!, ward: ward),
    );
  }

  void _goBack() {
    setState(() {
      if (_step == 2) {
        _step = 1;
      } else if (_step == 1) {
        _step = 0;
      }
      _searchCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final options = _currentOptions;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3))),
              _buildHeader(),
              _buildSearchBox(),
              Divider(height: 1, color: Colors.grey.shade100),
              Expanded(
                child: options.isEmpty
                    ? Center(child: Text('Không tìm thấy kết quả', style: TextStyle(color: Colors.grey.shade500)))
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: options.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100, indent: 16, endIndent: 16),
                        itemBuilder: (context, index) {
                          final item = options[index];
                          return ListTile(
                            title: Text(item, style: const TextStyle(fontSize: 14.5, color: ink)),
                            trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                            onTap: () {
                              if (_step == 0) {
                                _onPickProvince(item);
                              } else if (_step == 1) {
                                _onPickDistrict(item);
                              } else {
                                _onPickWard(item);
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  String get _title {
    switch (_step) {
      case 0:
        return 'Chọn Tỉnh/Thành phố';
      case 1:
        return 'Chọn Quận/Huyện';
      default:
        return 'Chọn Phường/Xã';
    }
  }

  String get _subtitle {
    if (_step == 1) return _selectedProvince ?? '';
    if (_step == 2) return '$_selectedDistrict, $_selectedProvince';
    return '';
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          if (_step > 0)
            IconButton(onPressed: _goBack, icon: const Icon(Icons.arrow_back, size: 20))
          else
            const SizedBox(width: 48),
          Expanded(
            child: Column(
              children: [
                Text(_title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: ink)),
                if (_subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(_subtitle, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
          ),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, size: 20)),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    final hint = _step == 0 ? 'Tìm tỉnh, thành phố' : (_step == 1 ? 'Tìm quận, huyện' : 'Tìm phường, xã');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
