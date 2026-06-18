// Package handler 提供對外的 HTTP 路由與處理函式。
package handler

import (
	"context"
	"encoding/json"
	"net/http"
	"time"

	"taiwan-transit-backend/internal/tdx"
)

// Handler 持有對外服務所需的相依物件。
type Handler struct {
	tdx *tdx.Client
}

// New 建立 Handler。
func New(tdxClient *tdx.Client) *Handler {
	return &Handler{tdx: tdxClient}
}

// Routes 註冊並回傳 HTTP 路由。
func (h *Handler) Routes() http.Handler {
	mux := http.NewServeMux()

	mux.HandleFunc("GET /healthz", h.health)

	// 以下為各運具查詢端點骨架，實作詳見執行計畫書 Phase 2。
	mux.HandleFunc("GET /api/v1/bike/stations", h.notImplemented) // YouBike 站點/車位
	mux.HandleFunc("GET /api/v1/bus/estimated", h.notImplemented) // 公車到站動態
	mux.HandleFunc("GET /api/v1/rail/timetable", h.notImplemented) // 台鐵/高鐵時刻

	return mux
}

func (h *Handler) health(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{
		"status": "ok",
		"time":   time.Now().UTC().Format(time.RFC3339),
	})
}

func (h *Handler) notImplemented(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusNotImplemented, map[string]any{
		"error": "not implemented yet",
	})
}

// callTDX 是給後續端點使用的輔助範例：帶 timeout 呼叫 TDX 並回傳原始 JSON。
func (h *Handler) callTDX(w http.ResponseWriter, path string) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	data, err := h.tdx.Get(ctx, path)
	if err != nil {
		writeJSON(w, http.StatusBadGateway, map[string]any{"error": err.Error()})
		return
	}
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write(data)
}

func writeJSON(w http.ResponseWriter, status int, body any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(body)
}
