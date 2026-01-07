# Chingu Demo 部署指南

## 當前狀態

✅ Flutter 專案已建立
✅ demo 資料夾已創建  
✅ Widgetbook 套件已安裝
⏳ 需要完成 UI 組件創建
⏳ 需要部署到 GitHub Pages

---

## 完成步驟

### 步驟 1: 重新創建核心組件

由於文件被刪除，需要重新創建：

```bash
# 1. 創建資料夾結構
mkdir -p lib/core/theme
mkdir -p lib/core/widgets  
mkdir -p lib/screens/auth

# 2. 復製之前創建的文件內容
# - lib/core/theme/app_colors.dart
# - lib/core/theme/app_text_styles.dart
# - lib/core/theme/app_theme.dart
# - lib/core/widgets/primary_button.dart
# - lib/core/widgets/app_card.dart
# - lib/screens/auth/splash_screen.dart
```

###步驟 2: 建立 Web 版本

```bash
cd /Users/chris/Chingu
flutter build web --target=demo/main.dart --release
```

### 步驟 3: 初始化 Git 並推送到 GitHub

```bash
# 初始化 Git（如果還沒有）
git init
git add .
git commit -m "Initial commit with Chingu demo"

# 在 GitHub 上創建新倉庫後
git remote add origin https://github.com/YOUR_USERNAME/chingu-demo.git
git branch -M main
git push -u origin main
```

### 步驟 4: 設置 GitHub Pages

#### 方法 A: 手動部署

```bash
# 1. 建立 gh-pages 分支
git checkout --orphan gh-pages

# 2. 清空內容
git rm -rf .

# 3. 複製 build/web 內容
cp -r build/web/* .

# 4. 提交並推送
git add .
git commit -m "Deploy to GitHub Pages"
git push origin gh-pages
```

#### 方法 B: 使用 GitHub Actions 自動部署

創建 `.github/workflows/deploy.yml`:

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v2
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.29.3'
          
      - name: Install dependencies
        run: flutter pub get
        
      - name: Build web
        run: flutter build web --target=demo/main.dart --release --base-href /chingu-demo/
        
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./build/web
```

### 步驟 5: 在 GitHub 設定 Pages

1. 進入 GitHub 倉庫設定
2. 找到 "Pages" 選項
3. Source 選擇 `gh-pages` 分支
4. 儲存

完成後網址會是：`https://YOUR_USERNAME.github.io/chingu-demo/`

---

## 本地預覽

```bash
# 啟動本地伺服器
flutter run -d chrome --target=demo/main.dart

# 或使用 Python 簡單伺服器
cd build/web
python3 -m http.server 8000
# 然後打開 http://localhost:8000
```

---

## 替代方案：使用 Vercel

更簡單的部署方式：

```bash
# 1. 安裝 Vercel CLI
npm i -g vercel

# 2. 建立 Web 版本
flutter build web --target=demo/main.dart --release

# 3. 部署
cd build/web
vercel --prod
```

完成後 Vercel 會給你一個網址，例如：
`https://chingu-demo.vercel.app`

---

## 需要的文件內容

### lib/core/theme/app_colors.dart
```dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFFF6B35);
  static const Color secondary = Color(0xFF004E89);
  static const Color background = Color(0xFFF7F7F7);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF2D3142);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color success = Color(0xFF06A77D);
  static const Color warning = Color(0xFFF4D35E);
  static const Color error = Color(0xFFEF476F);
  
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFFFF8C61)],
  );
  
  static Color primaryLight = primary.withOpacity(0.1);
  static Color shadowColor = Colors.black.withOpacity(0.1);
  static const Color divider = Color(0xFFE5E7EB);
}
```

### lib/core/theme/app_theme.dart
```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        background: AppColors.background,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
      ),
    );
  }
}
```

---

## 下一步

1. 重新創建所有核心組件文件
2. 測試本地運行 `flutter run -d chrome --target=demo/main.dart`
3. 建立 web 版本
4. 推送到 GitHub
5. 設置 GitHub Pages

---

## 提示

- 確保所有文件路徑正確
- 使用 `--base-href` 參數指定 GitHub Pages 的基礎路徑
- 可以使用 Vercel 作為更簡單的替代方案

---

最後更新: 2024/10/13



