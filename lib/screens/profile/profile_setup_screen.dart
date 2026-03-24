import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/onboarding_provider.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/widgets/onboarding_progress_bar.dart';

// 產業別清單
const List<String> industryList = [
  '科技 / 資訊',
  '金融 / 保險',
  '醫療 / 護理',
  '教育 / 學術',
  '法律 / 政治',
  '設計 / 藝術',
  '媒體 / 傳播',
  '行銷 / 廣告',
  '餐飲 / 服務',
  '零售 / 電商',
  '製造 / 工程',
  '建築 / 不動產',
  '運輸 / 物流',
  '農業 / 環保',
  '政府 / 公務',
  '學生',
  '自由工作者',
  '其他',
];

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  String? _selectedGender;
  String? _selectedIndustry;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _handleNextStep() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('請選擇性別'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (_selectedIndustry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('請選擇產業別'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // 保存步驟1的數據
    final onboardingProvider = context.read<OnboardingProvider>();
    onboardingProvider.setBasicInfo(
      name: _nameController.text.trim(),
      age: int.parse(_ageController.text),
      gender: _selectedGender!,
      job: _selectedIndustry!,
    );

    // 導航到下一步
    Navigator.of(context).pushNamed(AppRoutes.interestsSelection);
  }

  void _showIndustryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _IndustryPickerSheet(
        selected: _selectedIndustry,
        onSelected: (industry) {
          setState(() => _selectedIndustry = industry);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                totalSteps: 3,
                currentStep: 1,
              ),
              const SizedBox(height: 8),
              Text(
                '基本資料',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 32),

              // 姓名
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '姓名',
                  hintText: '請輸入您的姓名',
                  prefixIcon: Icon(Icons.person_outline_rounded, color: theme.colorScheme.primary),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '請輸入姓名';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 年齡
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '年齡',
                  hintText: '請輸入您的年齡',
                  prefixIcon: Icon(Icons.cake_rounded, color: theme.colorScheme.primary),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '請輸入年齡';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 18 || age > 100) {
                    return '請輸入有效的年齡 (18-100)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 性別
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '性別',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('男'),
                            value: 'male',
                            groupValue: _selectedGender,
                            onChanged: (value) {
                              setState(() => _selectedGender = value);
                            },
                            activeColor: theme.colorScheme.primary,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('女'),
                            value: 'female',
                            groupValue: _selectedGender,
                            onChanged: (value) {
                              setState(() => _selectedGender = value);
                            },
                            activeColor: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 產業別（可搜尋 Bottom Sheet）
              GestureDetector(
                onTap: _showIndustryPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedIndustry != null
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.5),
                      width: _selectedIndustry != null ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.work_outline_rounded,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedIndustry ?? '選擇產業別',
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedIndustry != null
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 下一步按鈕
              GradientButton(
                text: '下一步',
                onPressed: _handleNextStep,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 產業別搜尋選擇器 Bottom Sheet ───
class _IndustryPickerSheet extends StatefulWidget {
  final String? selected;
  final ValueChanged<String> onSelected;

  const _IndustryPickerSheet({
    required this.selected,
    required this.onSelected,
  });

  @override
  State<_IndustryPickerSheet> createState() => _IndustryPickerSheetState();
}

class _IndustryPickerSheetState extends State<_IndustryPickerSheet> {
  final _searchController = TextEditingController();
  List<String> _filtered = industryList;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = industryList;
      } else {
        _filtered = industryList
            .where((i) => i.toLowerCase().contains(query.toLowerCase()))
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
          // Handle bar
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            '選擇產業別',
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
                hintText: '搜尋產業...',
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
                final industry = _filtered[index];
                final isSelected = industry == widget.selected;

                return ListTile(
                  onTap: () => widget.onSelected(industry),
                  leading: Icon(
                    _getIndustryIcon(industry),
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    size: 22,
                  ),
                  title: Text(
                    industry,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle_rounded,
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

  IconData _getIndustryIcon(String industry) {
    if (industry.contains('科技')) return Icons.computer_rounded;
    if (industry.contains('金融')) return Icons.account_balance_rounded;
    if (industry.contains('醫療')) return Icons.local_hospital_rounded;
    if (industry.contains('教育')) return Icons.school_rounded;
    if (industry.contains('法律')) return Icons.gavel_rounded;
    if (industry.contains('設計')) return Icons.palette_rounded;
    if (industry.contains('媒體')) return Icons.videocam_rounded;
    if (industry.contains('行銷')) return Icons.campaign_rounded;
    if (industry.contains('餐飲')) return Icons.restaurant_rounded;
    if (industry.contains('零售')) return Icons.shopping_bag_rounded;
    if (industry.contains('製造')) return Icons.precision_manufacturing_rounded;
    if (industry.contains('建築')) return Icons.apartment_rounded;
    if (industry.contains('運輸')) return Icons.local_shipping_rounded;
    if (industry.contains('農業')) return Icons.eco_rounded;
    if (industry.contains('政府')) return Icons.account_balance_rounded;
    if (industry.contains('學生')) return Icons.backpack_rounded;
    if (industry.contains('自由')) return Icons.laptop_mac_rounded;
    return Icons.work_outline_rounded;
  }
}
