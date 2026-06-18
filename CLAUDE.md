# CLAUDE.md

本檔提供 Claude Code 在此專案工作的指引。

## 專案概觀

台灣大眾運輸查詢 App：一站查詢**公車到站動態**、**台鐵/高鐵時刻**、**YouBike 即時車位**，含地圖、定位與收藏。

- 前端：Flutter 3.35.3 (Dart 3.9.2)，iOS / Android
- 後端：Go 1.26（標準函式庫 `net/http`），作為 BFF
- 資料來源：TDX 運輸資料流通服務平臺（OAuth2 client_credentials）
- 完整規劃見 `執行計畫書.md`

## Monorepo 結構

```
taiwan-transit/
├── 執行計畫書.md      規劃與 roadmap（單一事實來源）
├── frontend/          Flutter App
└── backend/           Go BFF（封裝/快取 TDX，對前端出乾淨 DTO）
    ├── cmd/server/    進入點
    └── internal/{config,tdx,handler,model,cache}/
```

## 常用指令

### 後端（在 `backend/`）
```bash
cp .env.example .env          # 填入 TDX 憑證
go run ./cmd/server           # 預設 :8080
go test ./...                 # 測試
go vet ./... && go build ./...
```
> Go 裝在 `/opt/homebrew/bin`；若 shell 找不到 `go`，先 `export PATH="/opt/homebrew/bin:$PATH"`。

### 前端（在 `frontend/`）
```bash
flutter pub get
flutter analyze
# 行動裝置連後端：localhost 不通，需指定 base URL
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080   # Android 模擬器
flutter run --dart-define=API_BASE_URL=http://localhost:8080  # iOS 模擬器
```

## 架構慣例

- **後端是 BFF**：前端**不直連 TDX**。`client_secret` 只存後端 `.env`（已列入 `.gitignore`），永不進前端。
- **DTO 正規化**：後端把 TDX 原始格式 map 成 App 自訂乾淨 schema（`internal/model/`）後才回前端；前後端 model 欄位需對齊。
- **台鐵 (TRA) 與高鐵 (THSR) 是不同 TDX API group**，分開處理，勿混用。
- **快取**：站點等靜態資料長 TTL、到站/車位等動態資料短 TTL，集中在後端 `internal/cache/`。

## 前端技術選型（已定）

- 狀態管理：Riverpod
- 地圖：flutter_map + OpenStreetMap（免費，無金鑰）
- 定位：geolocator；HTTP：dio；本機儲存：shared_preferences

## 慣例

- 回答與 commit message 使用繁體中文。
- 變更僅限必要範圍；UI 相關工作先用 design 相關 skill 設計再實作。
