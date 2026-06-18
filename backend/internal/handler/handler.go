// Package handler 提供對外的 HTTP 路由與處理函式。
package handler

import (
	"context"
	"encoding/json"
	"net/http"
	"time"

	"taiwan-transit-backend/internal/cache"
	"taiwan-transit-backend/internal/model"
)

// TransitSource 是 handler 所需的運輸資料來源（由 tdx.Client 實作）。
// 抽成介面以便測試注入假來源。
type TransitSource interface {
	BikeStations(ctx context.Context, city string) ([]model.BikeStation, error)
	BusEstimates(ctx context.Context, city, route string) ([]model.BusEstimate, error)
	RailTimetable(ctx context.Context, op model.Operator, from, to, date string) ([]model.RailTrain, error)
}

// TDX 來源端逾時與各類資料的快取存活時間。
const (
	tdxTimeout = 10 * time.Second
	dynamicTTL = 20 * time.Second // 車位、到站等即時資料
	railTTL    = 1 * time.Hour    // 當日時刻表變動低
)

// Handler 持有對外服務所需的相依物件與各類快取。
type Handler struct {
	tdx TransitSource

	bikeCache *cache.TTLCache[[]model.BikeStation]
	busCache  *cache.TTLCache[[]model.BusEstimate]
	railCache *cache.TTLCache[[]model.RailTrain]
}

// New 建立 Handler。
func New(src TransitSource) *Handler {
	return &Handler{
		tdx:       src,
		bikeCache: cache.New[[]model.BikeStation](),
		busCache:  cache.New[[]model.BusEstimate](),
		railCache: cache.New[[]model.RailTrain](),
	}
}

// Routes 註冊並回傳 HTTP 路由。
func (h *Handler) Routes() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", h.health)
	mux.HandleFunc("GET /api/v1/bike/stations", h.bikeStations)  // ?city=Taipei
	mux.HandleFunc("GET /api/v1/bus/estimated", h.busEstimated)  // ?city=Taipei&route=307
	mux.HandleFunc("GET /api/v1/rail/timetable", h.railTimetable) // ?operator=TRA&from=&to=&date=
	return mux
}

func (h *Handler) health(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{
		"status": "ok",
		"time":   time.Now().UTC().Format(time.RFC3339),
	})
}

func (h *Handler) bikeStations(w http.ResponseWriter, r *http.Request) {
	city := r.URL.Query().Get("city")
	if city == "" {
		writeError(w, http.StatusBadRequest, "缺少 city 參數")
		return
	}
	if v, ok := h.bikeCache.Get(city); ok {
		writeJSON(w, http.StatusOK, v)
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), tdxTimeout)
	defer cancel()
	data, err := h.tdx.BikeStations(ctx, city)
	if err != nil {
		writeError(w, http.StatusBadGateway, err.Error())
		return
	}
	h.bikeCache.Set(city, data, dynamicTTL)
	writeJSON(w, http.StatusOK, data)
}

func (h *Handler) busEstimated(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	city, route := q.Get("city"), q.Get("route")
	if city == "" || route == "" {
		writeError(w, http.StatusBadRequest, "缺少 city 或 route 參數")
		return
	}
	key := city + "|" + route
	if v, ok := h.busCache.Get(key); ok {
		writeJSON(w, http.StatusOK, v)
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), tdxTimeout)
	defer cancel()
	data, err := h.tdx.BusEstimates(ctx, city, route)
	if err != nil {
		writeError(w, http.StatusBadGateway, err.Error())
		return
	}
	h.busCache.Set(key, data, dynamicTTL)
	writeJSON(w, http.StatusOK, data)
}

func (h *Handler) railTimetable(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	from, to, date := q.Get("from"), q.Get("to"), q.Get("date")
	op := model.Operator(q.Get("operator"))
	if from == "" || to == "" || date == "" {
		writeError(w, http.StatusBadRequest, "缺少 from、to 或 date 參數")
		return
	}
	if op != model.OperatorTRA && op != model.OperatorTHSR {
		writeError(w, http.StatusBadRequest, "operator 必須為 TRA 或 THSR")
		return
	}
	key := string(op) + "|" + from + "|" + to + "|" + date
	if v, ok := h.railCache.Get(key); ok {
		writeJSON(w, http.StatusOK, v)
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), tdxTimeout)
	defer cancel()
	data, err := h.tdx.RailTimetable(ctx, op, from, to, date)
	if err != nil {
		writeError(w, http.StatusBadGateway, err.Error())
		return
	}
	h.railCache.Set(key, data, railTTL)
	writeJSON(w, http.StatusOK, data)
}

func writeError(w http.ResponseWriter, status int, msg string) {
	writeJSON(w, status, map[string]any{"error": msg})
}

func writeJSON(w http.ResponseWriter, status int, body any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(body)
}
