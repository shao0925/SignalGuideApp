# SignalGuideApp
號誌系統線上緊急故障排除指引App


---

## 🖼️ 前端：Flutter App（`signal_guide_app/`）

- 使用 Flutter 架構，支援 Android/iOS 雙平台
- 功能：
  - 使用者登入與身份驗證
  - 緊急故障 SOP 查詢
  - 維修紀錄查閱與標示
  - 支援離線資料快取

---

## ⚙️ 後端：Django API（`signalguideproject/`）

- 提供 RESTful API 與 JWT 驗證機制
- 功能：
  - 使用者資料與權限管理
  - 維修紀錄資料庫操作（查詢、新增、編輯）
  - SOP 流程資料提供給前端使用
- 可部署於內網伺服器或雲端平台

---

## 🚀 使用說明（可依需要新增）

```bash
# 前端啟動
cd signal_guide_app
flutter pub get
flutter run

# 後端啟動（建議使用虛擬環境）
cd signalguideproject
python manage.py runserver

