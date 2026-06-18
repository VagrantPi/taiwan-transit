package handler

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"taiwan-transit-backend/internal/model"
)

// fakeSource 是可控的 TransitSource 假實作。
type fakeSource struct {
	bike    []model.BikeStation
	bikeErr error
	calls   int // BikeStations 被呼叫次數（驗證快取）
}

func (f *fakeSource) BikeStations(_ context.Context, _ string) ([]model.BikeStation, error) {
	f.calls++
	return f.bike, f.bikeErr
}
func (f *fakeSource) BusEstimates(_ context.Context, _, _ string) ([]model.BusEstimate, error) {
	return nil, nil
}
func (f *fakeSource) RailTimetable(_ context.Context, _ model.Operator, _, _, _ string) ([]model.RailTrain, error) {
	return nil, nil
}

func TestHealthz(t *testing.T) {
	h := New(&fakeSource{})
	rr := httptest.NewRecorder()
	h.Routes().ServeHTTP(rr, httptest.NewRequest(http.MethodGet, "/healthz", nil))

	if rr.Code != http.StatusOK {
		t.Fatalf("期望 200，得到 %d", rr.Code)
	}
}

func TestBikeStations_MissingCity(t *testing.T) {
	h := New(&fakeSource{})
	rr := httptest.NewRecorder()
	h.Routes().ServeHTTP(rr, httptest.NewRequest(http.MethodGet, "/api/v1/bike/stations", nil))

	if rr.Code != http.StatusBadRequest {
		t.Fatalf("缺 city 應回 400，得到 %d", rr.Code)
	}
}

func TestBikeStations_OKAndCached(t *testing.T) {
	src := &fakeSource{bike: []model.BikeStation{{ID: "U1", Name: "捷運市府站", AvailableRent: 5}}}
	h := New(src)

	for i := 0; i < 3; i++ {
		rr := httptest.NewRecorder()
		h.Routes().ServeHTTP(rr, httptest.NewRequest(http.MethodGet, "/api/v1/bike/stations?city=Taipei", nil))
		if rr.Code != http.StatusOK {
			t.Fatalf("期望 200，得到 %d", rr.Code)
		}
		var got []model.BikeStation
		if err := json.Unmarshal(rr.Body.Bytes(), &got); err != nil {
			t.Fatalf("回應非合法 JSON：%v", err)
		}
		if len(got) != 1 || got[0].Name != "捷運市府站" {
			t.Fatalf("回應內容不符：%+v", got)
		}
	}
	// 三次請求但因快取只應實際呼叫來源一次。
	if src.calls != 1 {
		t.Fatalf("應因快取只呼叫來源 1 次，實際 %d 次", src.calls)
	}
}

func TestBikeStations_UpstreamError(t *testing.T) {
	h := New(&fakeSource{bikeErr: errors.New("tdx down")})
	rr := httptest.NewRecorder()
	h.Routes().ServeHTTP(rr, httptest.NewRequest(http.MethodGet, "/api/v1/bike/stations?city=Taipei", nil))

	if rr.Code != http.StatusBadGateway {
		t.Fatalf("來源錯誤應回 502，得到 %d", rr.Code)
	}
}

func TestRailTimetable_BadOperator(t *testing.T) {
	h := New(&fakeSource{})
	rr := httptest.NewRecorder()
	h.Routes().ServeHTTP(rr, httptest.NewRequest(http.MethodGet, "/api/v1/rail/timetable?from=1&to=2&date=2026-06-18&operator=XXX", nil))

	if rr.Code != http.StatusBadRequest {
		t.Fatalf("錯誤 operator 應回 400，得到 %d", rr.Code)
	}
}
