---
name: chingu-theme
description: Chingu 專案的 Minimal Purple 設計規範與主題系統
---

# Chingu Theme Skill

## 概述
這個技能包定義了 Chingu 專案的「極簡紫色 (Minimal Purple)」設計規範。

## 主題系統

### 核心檔案
- `lib/core/theme/app_colors_minimal.dart` - 顏色定義
- `lib/core/theme/app_theme.dart` - 主題配置

### 使用方式

#### 1. 取得主題顏色
```dart
// 使用 Theme.of(context) 取得標準顏色
final primaryColor = Theme.of(context).colorScheme.primary;
final backgroundColor = Theme.of(context).colorScheme.background;

// 使用 ChinguTheme 擴展取得自訂顏色和漸層
final chingu = Theme.of(context).extension<ChinguTheme>()!;
final gradient = chingu.primaryGradient;
final success = chingu.success;
```

#### 2. 避免的做法
```dart
// ❌ 不要直接使用 AppColorsMinimal
Container(color: AppColorsMinimal.primary)

// ✅ 使用 Theme.of(context)
Container(color: Theme.of(context).colorScheme.primary)
```

## 色彩系統

### 主色系
| 名稱 | 色碼 | 用途 |
|------|------|------|
| Primary | `#8B9FFF` | 主強調色、按鈕、連結 |
| Primary Light | `#B4C5FF` | 淺色變體 |
| Primary Dark | `#6B7FE8` | 深色變體、Hover 狀態 |

### 次要色系
| 名稱 | 色碼 | 用途 |
|------|------|------|
| Secondary | `#B8A8FF` | 薰衣草紫、次要強調 |
| Secondary Light | `#D4C8FF` | 淺色變體 |

### 功能色
| 狀態 | 色碼 | 用途 |
|------|------|------|
| Success | `#06A77D` | 成功提示、完成狀態 |
| Warning | `#F4D35E` | 警告提示 |
| Error | `#EF476F` | 錯誤提示、刪除操作 |
| Info | `#3B82F6` | 資訊提示 |

## 間距系統

使用 8px 基準間距：
- `4px` - 極小間距
- `8px` - 小間距
- `16px` - 標準間距
- `24px` - 中等間距
- `32px` - 大間距

## 圓角規範

- 按鈕: `12px`
- 卡片: `16px`
- 輸入框: `12px`
- 彈窗: `20px`
- 頭像: 圓形 (`BorderRadius.circular(999)`)

## 陰影效果

```dart
// 淺陰影 - 用於卡片
BoxShadow(
  color: AppColorsMinimal.shadowLight,
  blurRadius: 8,
  offset: Offset(0, 2),
)

// 中等陰影 - 用於浮動按鈕、彈窗
BoxShadow(
  color: AppColorsMinimal.shadowMedium,
  blurRadius: 16,
  offset: Offset(0, 4),
)
```

## 漸層效果

```dart
// 主漸層 - 適用於按鈕、CTA
Container(
  decoration: BoxDecoration(
    gradient: Theme.of(context).extension<ChinguTheme>()!.primaryGradient,
  ),
)
```
