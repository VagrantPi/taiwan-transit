package tdx

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync/atomic"
	"testing"

	"taiwan-transit-backend/internal/model"
)

// fakeTDX 啟動一個假的 TDX server，並回傳指向它的 Client 與 token 請求計數器。
func fakeTDX(t *testing.T) (*Client, *int32) {
	t.Helper()
	var tokenHits int32

	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch {
		case strings.HasSuffix(r.URL.Path, "/token"):
			atomic.AddInt32(&tokenHits, 1)
			_, _ = w.Write([]byte(`{"access_token":"tok","expires_in":3600}`))
		case r.URL.Path == "/v2/Bike/Station/City/Taipei":
			_, _ = w.Write([]byte(`[{"StationUID":"U1","StationName":{"Zh_tw":"捷運市府站"},"StationPosition":{"PositionLat":25.04,"PositionLon":121.56},"BikesCapacity":30}]`))
		case r.URL.Path == "/v2/Bike/Availability/City/Taipei":
			_, _ = w.Write([]byte(`[{"StationUID":"U1","AvailableRentBikes":12,"AvailableReturnBikes":18,"UpdateTime":"2026-06-18T12:00:00+08:00"}]`))
		case r.URL.Path == "/v2/Bus/EstimatedTimeOfArrival/City/Taipei/307":
			_, _ = w.Write([]byte(`[{"RouteName":{"Zh_tw":"307"},"Direction":0,"StopName":{"Zh_tw":"市政府"},"EstimateTime":180,"StopStatus":0,"SrcUpdateTime":"2026-06-18T12:00:00+08:00"},{"RouteName":{"Zh_tw":"307"},"Direction":0,"StopName":{"Zh_tw":"國父紀念館"},"EstimateTime":null,"StopStatus":1,"SrcUpdateTime":"2026-06-18T12:00:00+08:00"}]`))
		case strings.HasPrefix(r.URL.Path, "/v2/Rail/TRA/DailyTrainTimetable/OD/"):
			_, _ = w.Write([]byte(`{"TrainTimetables":[{"TrainInfo":{"TrainNo":"123","TrainTypeName":{"Zh_tw":"自強"}},"StopTimes":[{"StationName":{"Zh_tw":"台北"},"DepartureTime":"08:00","ArrivalTime":"08:00"},{"StationName":{"Zh_tw":"台中"},"DepartureTime":"09:30","ArrivalTime":"09:28"}]}]}`))
		case strings.HasPrefix(r.URL.Path, "/v2/Rail/THSR/DailyTimetable/OD/"):
			_, _ = w.Write([]byte(`[{"DailyTrainInfo":{"TrainNo":"805"},"OriginStopTime":{"StationName":{"Zh_tw":"台北"},"DepartureTime":"08:00"},"DestinationStopTime":{"StationName":{"Zh_tw":"左營"},"ArrivalTime":"09:36"}}]`))
		default:
			http.Error(w, "not found: "+r.URL.Path, http.StatusNotFound)
		}
	}))
	t.Cleanup(srv.Close)

	c := NewClient("id", "secret")
	c.authURL = srv.URL + "/token"
	c.baseURL = srv.URL
	return c, &tokenHits
}

func TestTokenCaching(t *testing.T) {
	c, hits := fakeTDX(t)
	ctx := context.Background()

	for i := 0; i < 3; i++ {
		if _, err := c.token(ctx); err != nil {
			t.Fatalf("token 失敗：%v", err)
		}
	}
	if got := atomic.LoadInt32(hits); got != 1 {
		t.Fatalf("token 應只請求一次（快取），實際 %d 次", got)
	}
}

func TestBikeStations_Join(t *testing.T) {
	c, _ := fakeTDX(t)
	stations, err := c.BikeStations(context.Background(), "Taipei")
	if err != nil {
		t.Fatalf("BikeStations 失敗：%v", err)
	}
	if len(stations) != 1 {
		t.Fatalf("期望 1 站，得到 %d", len(stations))
	}
	s := stations[0]
	if s.Name != "捷運市府站" || s.AvailableRent != 12 || s.AvailableReturn != 18 || s.Total != 30 {
		t.Fatalf("站點 join 結果不符：%+v", s)
	}
}

func TestBusEstimates_StatusMapping(t *testing.T) {
	c, _ := fakeTDX(t)
	ests, err := c.BusEstimates(context.Background(), "Taipei", "307")
	if err != nil {
		t.Fatalf("BusEstimates 失敗：%v", err)
	}
	if len(ests) != 2 {
		t.Fatalf("期望 2 筆，得到 %d", len(ests))
	}
	if ests[0].EstimateMinutes != 3 { // 180 秒 → 3 分
		t.Fatalf("第一筆應為 3 分，得到 %d", ests[0].EstimateMinutes)
	}
	if ests[1].EstimateMinutes != -1 || ests[1].Status != "尚未發車" {
		t.Fatalf("第二筆特殊狀態不符：%+v", ests[1])
	}
}

func TestRailTimetable_TRAandTHSR(t *testing.T) {
	c, _ := fakeTDX(t)
	ctx := context.Background()

	tra, err := c.RailTimetable(ctx, model.OperatorTRA, "1000", "1040", "2026-06-18")
	if err != nil {
		t.Fatalf("TRA 失敗：%v", err)
	}
	if len(tra) != 1 || tra[0].TrainNo != "123" || tra[0].Type != "自強" ||
		tra[0].From != "台北" || tra[0].To != "台中" || tra[0].Arrival != "09:28" ||
		tra[0].Operator != model.OperatorTRA {
		t.Fatalf("TRA 解析不符：%+v", tra)
	}

	thsr, err := c.RailTimetable(ctx, model.OperatorTHSR, "0990", "1070", "2026-06-18")
	if err != nil {
		t.Fatalf("THSR 失敗：%v", err)
	}
	if len(thsr) != 1 || thsr[0].TrainNo != "805" || thsr[0].Operator != model.OperatorTHSR ||
		thsr[0].To != "左營" || thsr[0].Arrival != "09:36" {
		t.Fatalf("THSR 解析不符：%+v", thsr)
	}
}
