import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/onboarding_provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/onboarding_progress_bar.dart';

// 全台灣 22 縣市資料
const Map<String, List<String>> cityDistrictMap = {
  '台北市': ['中正區', '大同區', '中山區', '松山區', '大安區', '萬華區', '信義區', '士林區', '北投區', '內湖區', '南港區', '文山區'],
  '新北市': ['板橋區', '三重區', '中和區', '永和區', '新莊區', '新店區', '樹林區', '鶯歌區', '三峽區', '淡水區', '汐止區', '瑞芳區', '土城區', '蘆洲區', '五股區', '泰山區', '林口區', '深坑區', '石碇區', '坪林區', '三芝區', '石門區', '八里區', '平溪區', '雙溪區', '貢寮區', '金山區', '萬里區', '烏來區'],
  '基隆市': ['仁愛區', '信義區', '中正區', '中山區', '安樂區', '暖暖區', '七堵區'],
  '桃園市': ['桃園區', '中壢區', '平鎮區', '八德區', '楊梅區', '蘆竹區', '龜山區', '龍潭區', '大溪區', '大園區', '觀音區', '新屋區', '復興區'],
  '新竹市': ['東區', '北區', '香山區'],
  '新竹縣': ['竹北市', '竹東鎮', '新埔鎮', '關西鎮', '湖口鄉', '新豐鄉', '芎林鄉', '橫山鄉', '北埔鄉', '寶山鄉', '峨眉鄉', '尖石鄉', '五峰鄉'],
  '苗栗縣': ['苗栗市', '頭份市', '竹南鎮', '後龍鎮', '通霄鎮', '苑裡鎮', '卓蘭鎮', '造橋鄉', '西湖鄉', '頭屋鄉', '公館鄉', '銅鑼鄉', '三義鄉', '大湖鄉', '獅潭鄉', '三灣鄉', '南庄鄉', '泰安鄉'],
  '台中市': ['中區', '東區', '南區', '西區', '北區', '西屯區', '南屯區', '北屯區', '豐原區', '東勢區', '大甲區', '清水區', '沙鹿區', '梧棲區', '后里區', '神岡區', '潭子區', '大雅區', '新社區', '石岡區', '外埔區', '大安區', '烏日區', '大肚區', '龍井區', '霧峰區', '太平區', '大里區', '和平區'],
  '彰化縣': ['彰化市', '員林市', '鹿港鎮', '和美鎮', '北斗鎮', '溪湖鎮', '田中鎮', '二林鎮', '線西鄉', '伸港鄉', '福興鄉', '秀水鄉', '花壇鄉', '芬園鄉', '大村鄉', '埔鹽鄉', '埔心鄉', '永靖鄉', '社頭鄉', '二水鄉', '田尾鄉', '埤頭鄉', '芳苑鄉', '大城鄉', '竹塘鄉', '溪州鄉'],
  '南投縣': ['南投市', '埔里鎮', '草屯鎮', '竹山鎮', '集集鎮', '名間鄉', '鹿谷鄉', '中寮鄉', '魚池鄉', '國姓鄉', '水里鄉', '信義鄉', '仁愛鄉'],
  '雲林縣': ['斗六市', '虎尾鎮', '斗南鎮', '西螺鎮', '土庫鎮', '北港鎮', '古坑鄉', '大埤鄉', '莿桐鄉', '林內鄉', '二崙鄉', '崙背鄉', '麥寮鄉', '東勢鄉', '褒忠鄉', '台西鄉', '元長鄉', '四湖鄉', '口湖鄉', '水林鄉'],
  '嘉義市': ['東區', '西區'],
  '嘉義縣': ['太保市', '朴子市', '布袋鎮', '大林鎮', '民雄鄉', '溪口鄉', '新港鄉', '六腳鄉', '東石鄉', '義竹鄉', '鹿草鄉', '水上鄉', '中埔鄉', '竹崎鄉', '梅山鄉', '番路鄉', '大埔鄉', '阿里山鄉'],
  '台南市': ['中西區', '東區', '南區', '北區', '安平區', '安南區', '永康區', '歸仁區', '新化區', '左鎮區', '玉井區', '楠西區', '南化區', '仁德區', '關廟區', '龍崎區', '官田區', '麻豆區', '佳里區', '西港區', '七股區', '將軍區', '學甲區', '北門區', '新營區', '後壁區', '白河區', '東山區', '六甲區', '下營區', '柳營區', '鹽水區', '善化區', '大內區', '山上區', '新市區', '安定區'],
  '高雄市': ['楠梓區', '左營區', '鼓山區', '三民區', '鹽埕區', '前金區', '新興區', '苓雅區', '前鎮區', '旗津區', '小港區', '鳳山區', '大寮區', '鳥松區', '林園區', '仁武區', '大樹區', '大社區', '岡山區', '路竹區', '橋頭區', '梓官區', '彌陀區', '永安區', '燕巢區', '田寮區', '阿蓮區', '茄萣區', '湖內區', '旗山區', '美濃區', '內門區', '杉林區', '甲仙區', '六龜區', '茂林區', '桃源區', '那瑪夏區'],
  '屏東縣': ['屏東市', '潮州鎮', '東港鎮', '恆春鎮', '萬丹鄉', '長治鄉', '麟洛鄉', '九如鄉', '里港鄉', '鹽埔鄉', '高樹鄉', '萬巒鄉', '內埔鄉', '竹田鄉', '新埤鄉', '枋寮鄉', '新園鄉', '崁頂鄉', '林邊鄉', '南州鄉', '佳冬鄉', '琉球鄉', '車城鄉', '滿州鄉', '枋山鄉', '三地門鄉', '霧台鄉', '瑪家鄉', '泰武鄉', '來義鄉', '春日鄉', '獅子鄉', '牡丹鄉'],
  '宜蘭縣': ['宜蘭市', '羅東鎮', '蘇澳鎮', '頭城鎮', '礁溪鄉', '壯圍鄉', '員山鄉', '冬山鄉', '五結鄉', '三星鄉', '大同鄉', '南澳鄉'],
  '花蓮縣': ['花蓮市', '鳳林鎮', '玉里鎮', '新城鄉', '吉安鄉', '壽豐鄉', '光復鄉', '豐濱鄉', '瑞穗鄉', '萬榮鄉', '富里鄉', '秀林鄉', '卓溪鄉'],
  '台東縣': ['台東市', '成功鎮', '關山鎮', '卑南鄉', '鹿野鄉', '池上鄉', '東河鄉', '長濱鄉', '太麻里鄉', '大武鄉', '綠島鄉', '蘭嶼鄉', '延平鄉', '海端鄉', '達仁鄉', '金峰鄉'],
  '澎湖縣': ['馬公市', '湖西鄉', '白沙鄉', '西嶼鄉', '望安鄉', '七美鄉'],
  '金門縣': ['金城鎮', '金湖鎮', '金沙鎮', '金寧鄉', '烈嶼鄉', '烏坵鄉'],
  '連江縣': ['南竿鄉', '北竿鄉', '莒光鄉', '東引鄉'],
};

// 初期開放的地區（district-level，集中用戶密度）
const String activeCity = '台北市';
const List<String> activeDistricts = ['信義區'];

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedCity;
  String? _selectedDistrict;

  bool _isSubmitting = false;
  bool _isLoadingLocation = false;

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    // 模擬定位過程（未來接真正 GPS）
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      _selectedCity = '台北市';
      _selectedDistrict = '中正區';
      _isLoadingLocation = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('已定位至：台北市中正區'),
        backgroundColor: Theme.of(context).extension<ChinguTheme>()?.success ?? Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SearchablePickerSheet(
        title: '選擇城市',
        items: cityDistrictMap.keys.toList(),
        selected: _selectedCity,
        activeItems: [activeCity],
        onSelected: (city) {
          setState(() {
            _selectedCity = city;
            _selectedDistrict = null; // reset district
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showDistrictPicker() {
    if (_selectedCity == null) return;
    final districts = cityDistrictMap[_selectedCity]!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SearchablePickerSheet(
        title: '選擇地區',
        items: districts,
        selected: _selectedDistrict,
        onSelected: (district) {
          setState(() => _selectedDistrict = district);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Future<void> _handleComplete() async {
    final theme = Theme.of(context);

    if (_selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('請選擇城市'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
      return;
    }

    if (_selectedDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('請選擇地區'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
      return;
    }

    // 不阻擋註冊 — 用戶無論住哪都可以完成 onboarding
    // 晚餐活動目前只在信義區舉辦，但這不影響註冊

    setState(() => _isSubmitting = true);

    final onboardingProvider = context.read<OnboardingProvider>();

    onboardingProvider.setLocation(
      country: '台灣',
      city: _selectedCity!,
      district: _selectedDistrict!,
    );

    final authProvider = context.read<AuthProvider>();
    final success = await onboardingProvider.submitOnboardingData(authProvider);

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    final chinguTheme = theme.extension<ChinguTheme>();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('個人資料設定完成！🎉'),
          backgroundColor: chinguTheme?.success ?? Colors.green,
        ),
      );
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.notificationPermission,
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('提交失敗，請稍後再試'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }

  void _showComingSoonDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🚀', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              '即將開放！',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '$_selectedCity $_selectedDistrict 目前尚未開放晚餐活動\n我們會在開放時通知你！',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '目前開放：$activeCity ${activeDistricts.join("、")}',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _selectedCity = activeCity;
                _selectedDistrict = activeDistricts.first;
              });
            },
            child: Text('切換到$activeCity${activeDistricts.first}'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('我知道了'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('完成個人資料', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Indicator
              const OnboardingProgressBar(
                totalSteps: 4,
                currentStep: 4,
              ),
              const SizedBox(height: 8),
              Text(
                '地區資訊',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),

              // 說明文字
              Text(
                '選擇您的居住地區',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),

              // 使用當前位置按鈕
              OutlinedButton.icon(
                onPressed: _isLoadingLocation ? null : _useCurrentLocation,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: theme.colorScheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isLoadingLocation
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : Icon(Icons.my_location, color: theme.colorScheme.primary),
                label: Text(
                  _isLoadingLocation ? '定位中...' : '使用當前位置',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ===== 城市選擇器 =====
              GestureDetector(
                onTap: _showCityPicker,
                child: _buildPickerField(
                  theme: theme,
                  icon: Icons.location_city_rounded,
                  label: _selectedCity ?? '選擇城市',
                  isSelected: _selectedCity != null,
                ),
              ),
              const SizedBox(height: 16),

              // ===== 地區選擇器 =====
              GestureDetector(
                onTap: _selectedCity != null ? _showDistrictPicker : null,
                child: _buildPickerField(
                  theme: theme,
                  icon: Icons.place_rounded,
                  label: _selectedDistrict ?? '選擇地區',
                  isSelected: _selectedDistrict != null,
                  isDisabled: _selectedCity == null,
                ),
              ),

              // 開放地區提示
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '目前開放地區：$activeCity ${activeDistricts.join("、")}',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 完成按鈕
              Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: chinguTheme?.successGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (chinguTheme?.success ?? Colors.green).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Text(
                          '完成設定 🎉',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerField({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required bool isSelected,
    bool isDisabled = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: isDisabled
            ? theme.disabledColor.withValues(alpha: 0.05)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.5),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: isDisabled
              ? theme.disabledColor
              : theme.colorScheme.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: isDisabled
                    ? theme.disabledColor
                    : isSelected
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          Icon(Icons.arrow_drop_down_rounded,
              color: isDisabled ? theme.disabledColor : theme.colorScheme.primary),
        ],
      ),
    );
  }
}

// ─── 通用可搜尋選擇器 Bottom Sheet ───
class _SearchablePickerSheet extends StatefulWidget {
  final String title;
  final List<String> items;
  final String? selected;
  final List<String>? activeItems; // if set, inactive items show a badge
  final ValueChanged<String> onSelected;

  const _SearchablePickerSheet({
    required this.title,
    required this.items,
    required this.selected,
    this.activeItems,
    required this.onSelected,
  });

  @override
  State<_SearchablePickerSheet> createState() => _SearchablePickerSheetState();
}

class _SearchablePickerSheetState extends State<_SearchablePickerSheet> {
  final _searchController = TextEditingController();
  late List<String> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = widget.items;
      } else {
        _filtered = widget.items
            .where((i) => i.contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: '搜尋...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // List
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final item = _filtered[index];
                final isSelected = item == widget.selected;
                final isActive = widget.activeItems == null ||
                    widget.activeItems!.contains(item);

                return ListTile(
                  onTap: () => widget.onSelected(item),
                  leading: Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    size: 22,
                  ),
                  title: Text(
                    item,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  trailing: !isActive
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '即將開放',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : isSelected
                          ? Icon(Icons.check_rounded,
                              color: theme.colorScheme.primary)
                          : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
