import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/onboarding_provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/onboarding_progress_bar.dart';

// 台灣城市和地區資料
const Map<String, List<String>> cityDistrictMap = {
  '台北市': ['中正區', '大同區', '中山區', '松山區', '大安區', '萬華區', '信義區', '士林區', '北投區', '內湖區', '南港區', '文山區'],
  '新北市': ['板橋區', '三重區', '中和區', '永和區', '新莊區', '新店區', '樹林區', '鶯歌區', '三峽區', '淡水區', '汐止區', '瑞芳區', '土城區', '蘆洲區', '五股區', '泰山區', '林口區', '深坑區', '石碇區', '坪林區', '三芝區', '石門區', '八里區', '平溪區', '雙溪區', '貢寮區', '金山區', '萬里區', '烏來區'],
  '桃園市': ['桃園區', '中壢區', '平鎮區', '八德區', '楊梅區', '蘆竹區', '龜山區', '龍潭區', '大溪區', '大園區', '觀音區', '新屋區', '復興區'],
  '台中市': ['中區', '東區', '南區', '西區', '北區', '西屯區', '南屯區', '北屯區', '豐原區', '東勢區', '大甲區', '清水區', '沙鹿區', '梧棲區', '后里區', '神岡區', '潭子區', '大雅區', '新社區', '石岡區', '外埔區', '大安區', '烏日區', '大肚區', '龍井區', '霧峰區', '太平區', '大里區', '和平區'],
  '台南市': ['中西區', '東區', '南區', '北區', '安平區', '安南區', '永康區', '歸仁區', '新化區', '左鎮區', '玉井區', '楠西區', '南化區', '仁德區', '關廟區', '龍崎區', '官田區', '麻豆區', '佳里區', '西港區', '七股區', '將軍區', '學甲區', '北門區', '新營區', '後壁區', '白河區', '東山區', '六甲區', '下營區', '柳營區', '鹽水區', '善化區', '大內區', '山上區', '新市區', '安定區'],
  '高雄市': ['楠梓區', '左營區', '鼓山區', '三民區', '鹽埕區', '前金區', '新興區', '苓雅區', '前鎮區', '旗津區', '小港區', '鳳山區', '大寮區', '鳥松區', '林園區', '仁武區', '大樹區', '大社區', '岡山區', '路竹區', '橋頭區', '梓官區', '彌陀區', '永安區', '燕巢區', '田寮區', '阿蓮區', '茄萣區', '湖內區', '旗山區', '美濃區', '內門區', '杉林區', '甲仙區', '六龜區', '茂林區', '桃源區', '那瑪夏區'],
};

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final _formKey = GlobalKey<FormState>();

  // 地區資訊
  String _selectedCity = '台北市';
  String? _selectedDistrict;
  List<String> _availableDistricts = cityDistrictMap['台北市']!;

  bool _isSubmitting = false;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    // 預設選擇第一個地區
    _selectedDistrict = _availableDistricts.first;
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    // 模擬定位過程
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      _selectedCity = '台北市';
      _availableDistricts = cityDistrictMap['台北市']!;
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

  void _onCityChanged(String? newCity) {
    if (newCity != null) {
      setState(() {
        _selectedCity = newCity;
        _availableDistricts = cityDistrictMap[newCity]!;
        // 重置地區選擇為第一個
        _selectedDistrict = _availableDistricts.first;
      });
    }
  }

  Future<void> _handleComplete() async {
    final theme = Theme.of(context);

    if (!_formKey.currentState!.validate()) {
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

    setState(() => _isSubmitting = true);

    // 保存步驟4的數據
    final onboardingProvider = context.read<OnboardingProvider>();

    // 設置地區資訊
    onboardingProvider.setLocation(
      country: '台灣',
      city: _selectedCity,
      district: _selectedDistrict!,
    );

    // 提交所有數據到 Firestore
    final authProvider = context.read<AuthProvider>();
    final success = await onboardingProvider.submitOnboardingData(authProvider);

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    final chinguTheme = theme.extension<ChinguTheme>();

    if (success) {
      // 完成 onboarding，導航到主頁
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('個人資料設定完成！🎉'),
          backgroundColor: chinguTheme?.success ?? Colors.green,
        ),
      );
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.mainNavigation,
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

              // 地區資訊
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

              // 城市下拉選單
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCity,
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary),
                    dropdownColor: theme.cardColor,
                    items: cityDistrictMap.keys.map((String city) {
                      return DropdownMenuItem<String>(
                        value: city,
                        child: Row(
                          children: [
                            Icon(Icons.location_city_rounded, color: theme.colorScheme.primary, size: 20),
                            const SizedBox(width: 12),
                            Text(city),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: _onCityChanged,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 地區下拉選單
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDistrict,
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.secondary),
                    dropdownColor: theme.cardColor,
                    items: _availableDistricts.map((String district) {
                      return DropdownMenuItem<String>(
                        value: district,
                        child: Row(
                          children: [
                            Icon(Icons.place_rounded, color: theme.colorScheme.secondary, size: 20),
                            const SizedBox(width: 12),
                            Text(district),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newDistrict) {
                      setState(() => _selectedDistrict = newDistrict);
                    },
                  ),
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
                      color: (chinguTheme?.success ?? Colors.green).withOpacity(0.3),
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
}
