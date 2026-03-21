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

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // 地區資訊
  String _selectedCity = '台北市';
  String? _selectedDistrict;
  List<String> _availableDistricts = cityDistrictMap['台北市']!;
  
  // 用餐偏好
  String _diningPreference = 'any';
  double _minAge = 18;
  double _maxAge = 50;
  int _budgetRange = 1;
  
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // 預設選擇第一個地區
    _selectedDistrict = _availableDistricts.first;
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('請選擇地區'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // 保存步驟3和步驟4的數據
    final onboardingProvider = context.read<OnboardingProvider>();
    
    // 設置配對偏好
    onboardingProvider.setPreferences(
      diningPreference: _diningPreference,
      minAge: _minAge.toInt(),
      maxAge: _maxAge.toInt(),
      budgetRange: _budgetRange,
    );
    
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

    if (success) {
      // 完成 onboarding，導航到主頁
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('個人資料設定完成！🎉'),
          backgroundColor: Theme.of(context).extension<ChinguTheme>()?.success ?? Colors.green,
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
          backgroundColor: Theme.of(context).colorScheme.error,
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
                currentStep: 3,
              ),
              const SizedBox(height: 8),
              Text(
                '配對偏好與地區',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              
              // 用餐偏好
              Text(
                '你期待和什麼樣的人一起用餐？',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('男性為主'),
                      value: 'male',
                      groupValue: _diningPreference,
                      onChanged: (value) {
                        setState(() => _diningPreference = value!);
                      },
                      activeColor: theme.colorScheme.primary,
                    ),
                    RadioListTile<String>(
                      title: const Text('女性為主'),
                      value: 'female',
                      groupValue: _diningPreference,
                      onChanged: (value) {
                        setState(() => _diningPreference = value!);
                      },
                      activeColor: theme.colorScheme.primary,
                    ),
                    RadioListTile<String>(
                      title: const Text('都喜歡'),
                      value: 'any',
                      groupValue: _diningPreference,
                      onChanged: (value) {
                        setState(() => _diningPreference = value!);
                      },
                      activeColor: theme.colorScheme.primary,
                    ),
                    RadioListTile<String>(
                      title: const Text('隨緣'),
                      value: 'no_preference',
                      groupValue: _diningPreference,
                      onChanged: (value) {
                        setState(() => _diningPreference = value!);
                      },
                      activeColor: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // 年齡範圍
              Text(
                '年齡範圍偏好',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${_minAge.toInt()} - ${_maxAge.toInt()} 歲'),
                        Icon(Icons.favorite_rounded, color: theme.colorScheme.error, size: 20),
                      ],
                    ),
                    RangeSlider(
                      values: RangeValues(_minAge, _maxAge),
                      min: 18,
                      max: 100,
                      divisions: 82,
                      activeColor: theme.colorScheme.primary,
                      onChanged: (values) {
                        setState(() {
                          _minAge = values.start;
                          _maxAge = values.end;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // 預算範圍
              Text(
                '預算範圍',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    _buildBudgetOption(0, 'NT\$ 300-500', theme.colorScheme.primary),
                    _buildBudgetOption(1, 'NT\$ 500-800', theme.colorScheme.primary),
                    _buildBudgetOption(2, 'NT\$ 800-1200', theme.colorScheme.primary),
                    _buildBudgetOption(3, 'NT\$ 1200+', theme.colorScheme.primary),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // 地區資訊
              Text(
                '地區資訊',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              
              // 城市下拉選單
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
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
                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
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

  Widget _buildBudgetOption(int value, String label, Color activeColor) {
    final isSelected = _budgetRange == value;
    return RadioListTile<int>(
      title: Text(label),
      value: value,
      groupValue: _budgetRange,
      onChanged: (val) {
        setState(() => _budgetRange = val!);
      },
      activeColor: activeColor,
      selected: isSelected,
    );
  }
}
