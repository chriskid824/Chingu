import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/restaurant_model.dart';
import '../providers/admin_restaurants_provider.dart';

class RestaurantManageScreen extends StatefulWidget {
  const RestaurantManageScreen({super.key});

  @override
  State<RestaurantManageScreen> createState() => _RestaurantManageScreenState();
}

class _RestaurantManageScreenState extends State<RestaurantManageScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminRestaurantsProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminRestaurantsProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: const Text('餐廳管理'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => prov.loadAll(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2E5364),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('新增餐廳'),
        onPressed: () => _openEditor(context, null),
      ),
      body: _buildBody(prov),
    );
  }

  Widget _buildBody(AdminRestaurantsProvider prov) {
    if (prov.isLoading && prov.all.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (prov.errorMessage != null) {
      return Center(child: Text(prov.errorMessage!, style: const TextStyle(color: Colors.red)));
    }
    if (prov.all.isEmpty) {
      return const Center(child: Text('尚無餐廳資料', style: TextStyle(color: Colors.black54)));
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Card(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 250),
            child: DataTable(
              columns: const [
                DataColumn(label: Text('名稱')),
                DataColumn(label: Text('地址')),
                DataColumn(label: Text('預算')),
                DataColumn(label: Text('飲食標籤')),
                DataColumn(label: Text('啟用')),
                DataColumn(label: Text('操作')),
              ],
              rows: [
                for (final r in prov.all)
                  DataRow(cells: [
                    DataCell(Text(r.name)),
                    DataCell(SizedBox(width: 280, child: Text(r.address, overflow: TextOverflow.ellipsis))),
                    DataCell(Text(r.budgetLevelText)),
                    DataCell(Text(r.dietaryTags.isEmpty ? '—' : r.dietaryTags.join(', '))),
                    DataCell(Switch(
                      value: r.isActive,
                      onChanged: (_) => prov.toggleActive(r),
                    )),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _openEditor(context, r),
                        ),
                      ],
                    )),
                  ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, RestaurantModel? existing) async {
    final saved = await showDialog<RestaurantModel>(
      context: context,
      builder: (_) => _RestaurantEditor(existing: existing),
    );
    if (saved == null || !context.mounted) return;
    final prov = context.read<AdminRestaurantsProvider>();
    if (existing == null) {
      await prov.create(saved);
    } else {
      await prov.update(saved);
    }
  }
}

class _RestaurantEditor extends StatefulWidget {
  final RestaurantModel? existing;
  const _RestaurantEditor({this.existing});

  @override
  State<_RestaurantEditor> createState() => _RestaurantEditorState();
}

class _RestaurantEditorState extends State<_RestaurantEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _imageUrl;
  late final TextEditingController _lat;
  late final TextEditingController _lng;
  late final TextEditingController _dietary;
  int _budgetLevel = 1;
  String _city = '台北市';
  String _district = '信義區';

  @override
  void initState() {
    super.initState();
    final r = widget.existing;
    _name = TextEditingController(text: r?.name ?? '');
    _address = TextEditingController(text: r?.address ?? '');
    _phone = TextEditingController(text: r?.phone ?? '');
    _imageUrl = TextEditingController(text: r?.imageUrl ?? '');
    _lat = TextEditingController(text: r?.location.latitude.toString() ?? '25.033');
    _lng = TextEditingController(text: r?.location.longitude.toString() ?? '121.565');
    _dietary = TextEditingController(text: r?.dietaryTags.join(',') ?? '');
    _budgetLevel = r?.budgetLevel ?? 1;
    _city = r?.city ?? '台北市';
    _district = r?.district ?? '信義區';
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    _imageUrl.dispose();
    _lat.dispose();
    _lng.dispose();
    _dietary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.existing == null ? '新增餐廳' : '編輯餐廳',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _field(_name, '名稱', required: true),
                _field(_address, '地址', required: true),
                _field(_phone, '電話'),
                _field(_imageUrl, '封面圖 URL（選填）'),
                Row(
                  children: [
                    Expanded(child: _field(_lat, '緯度', isNumber: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _field(_lng, '經度', isNumber: true)),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _budgetLevel,
                  decoration: const InputDecoration(labelText: '預算等級', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('NT\$ 300-500')),
                    DropdownMenuItem(value: 1, child: Text('NT\$ 500-800')),
                    DropdownMenuItem(value: 2, child: Text('NT\$ 800-1200')),
                    DropdownMenuItem(value: 3, child: Text('NT\$ 1200+')),
                  ],
                  onChanged: (v) => setState(() => _budgetLevel = v ?? 1),
                ),
                const SizedBox(height: 12),
                _field(_dietary, '飲食標籤（逗號分隔，例：vegetarian,no_beef）'),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E5364)),
                      child: const Text('儲存'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {bool required = false, bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : null,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: required ? (v) => (v == null || v.isEmpty) ? '必填' : null : null,
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final tags = _dietary.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final base = widget.existing;
    final result = RestaurantModel(
      id: base?.id ?? '',
      name: _name.text.trim(),
      address: _address.text.trim(),
      location: GeoPoint(
        double.tryParse(_lat.text) ?? 25.033,
        double.tryParse(_lng.text) ?? 121.565,
      ),
      phone: _phone.text.trim(),
      imageUrl: _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),
      budgetLevel: _budgetLevel,
      maxGroupSize: base?.maxGroupSize ?? 8,
      dietaryTags: tags,
      city: _city,
      district: _district,
      isActive: base?.isActive ?? true,
      lastBookedAt: base?.lastBookedAt,
      createdAt: base?.createdAt ?? DateTime.now(),
    );
    Navigator.pop(context, result);
  }
}
