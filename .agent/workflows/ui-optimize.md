---
description: UI 優化檢查清單與設計規範
---

# UI 優化工作流程

## 設計主題
**Minimal Purple（極簡紫色）** - 深色主題搭配紫色強調色

## 優化檢查清單

### 1. 顏色與主題
- [ ] 使用 `Theme.of(context)` 取得顏色
- [ ] 使用 `ChinguTheme` 擴展方法
- [ ] 避免直接使用 `AppColorsMinimal`
- [ ] 確保深色背景 + 紫色強調色

### 2. 排版與間距
- [ ] 統一使用 8px 間距系統
- [ ] 標題使用 `headlineMedium` 或 `titleLarge`
- [ ] 內文使用 `bodyMedium` 或 `bodyLarge`

### 3. 元件規範
- [ ] 按鈕使用 `ElevatedButton` 或 `OutlinedButton`
- [ ] 輸入框使用 `ChinguTextField`（如有）
- [ ] 卡片使用圓角 16px
- [ ] 確保觸控區域至少 48x48

### 4. 動畫
- [ ] 頁面過渡使用 Fade + Slide
- [ ] 按鈕點擊有回饋動畫
- [ ] 列表項目有漸進式載入動畫

## 代碼位置
- 主題定義: `lib/theme/`
- 顏色定義: `lib/theme/app_colors_minimal.dart`
- 共用元件: `lib/widgets/`
