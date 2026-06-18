// Package model 定義後端對前端輸出的 DTO（已正規化的乾淨格式），
// 與前端 lib/data/models 一一對齊。TDX 原始格式不外流到前端。
package model

// BikeStation 是 YouBike 站點 + 即時車位。
type BikeStation struct {
	ID              string  `json:"id"`              // 站點代碼
	Name            string  `json:"name"`            // 站點名稱（中文）
	Lat             float64 `json:"lat"`             // 緯度
	Lng             float64 `json:"lng"`             // 經度
	AvailableRent   int     `json:"availableRent"`   // 可借車輛數
	AvailableReturn int     `json:"availableReturn"` // 可還空位數
	Total           int     `json:"total"`           // 總車柱數
	UpdatedAt       string  `json:"updatedAt"`       // 資料更新時間 (RFC3339)
}

// BusEstimate 是公車到站動態。
type BusEstimate struct {
	RouteName       string `json:"routeName"`       // 路線名稱
	Direction       int    `json:"direction"`       // 去返程：0 去程 / 1 返程
	StopName        string `json:"stopName"`        // 站牌名稱
	EstimateMinutes int    `json:"estimateMinutes"` // 預估到站分鐘數；-1 表示無班次/進站中等特殊狀態
	Status          string `json:"status"`          // 狀態文字（如「將到站」「未發車」）
	UpdatedAt       string `json:"updatedAt"`       // 資料更新時間 (RFC3339)
}

// Operator 區分鐵路營運商。
type Operator string

const (
	OperatorTRA  Operator = "TRA"  // 台鐵
	OperatorTHSR Operator = "THSR" // 高鐵
)

// RailTrain 是台鐵/高鐵單一車次時刻。
type RailTrain struct {
	TrainNo   string   `json:"trainNo"`   // 車次號
	Type      string   `json:"type"`      // 車種（如自強、區間；高鐵車型）
	From      string   `json:"from"`      // 起站名稱
	To        string   `json:"to"`        // 訖站名稱
	Departure string   `json:"departure"` // 出發時間 HH:mm
	Arrival   string   `json:"arrival"`   // 抵達時間 HH:mm
	Operator  Operator `json:"operator"`  // TRA | THSR
}
