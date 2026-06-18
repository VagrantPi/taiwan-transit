package tdx

import (
	"context"
	"encoding/json"
	"fmt"

	"taiwan-transit-backend/internal/model"
)

// RailTimetable 取得指定營運商、起訖站、日期的車次時刻，回傳正規化 DTO。
// from/to 為該營運商的車站代碼；date 格式 YYYY-MM-DD。
func (c *Client) RailTimetable(ctx context.Context, op model.Operator, from, to, date string) ([]model.RailTrain, error) {
	switch op {
	case model.OperatorTHSR:
		return c.thsrTimetable(ctx, from, to, date)
	default:
		return c.traTimetable(ctx, from, to, date)
	}
}

// --- 台鐵 TRA：起訖站每日時刻表 ---

type traStopTime struct {
	StationName   nameZh `json:"StationName"`
	ArrivalTime   string `json:"ArrivalTime"`
	DepartureTime string `json:"DepartureTime"`
}

type traTimetableResp struct {
	TrainTimetables []struct {
		TrainInfo struct {
			TrainNo       string `json:"TrainNo"`
			TrainTypeName nameZh `json:"TrainTypeName"`
		} `json:"TrainInfo"`
		StopTimes []traStopTime `json:"StopTimes"`
	} `json:"TrainTimetables"`
}

func (c *Client) traTimetable(ctx context.Context, from, to, date string) ([]model.RailTrain, error) {
	path := fmt.Sprintf("/v2/Rail/TRA/DailyTrainTimetable/OD/%s/to/%s/%s?%%24format=JSON", from, to, date)
	b, err := c.Get(ctx, path)
	if err != nil {
		return nil, fmt.Errorf("tra timetable: %w", err)
	}

	var resp traTimetableResp
	if err := json.Unmarshal(b, &resp); err != nil {
		return nil, fmt.Errorf("decode tra timetable: %w", err)
	}

	out := make([]model.RailTrain, 0, len(resp.TrainTimetables))
	for _, t := range resp.TrainTimetables {
		if len(t.StopTimes) < 2 {
			continue // OD 查詢應至少含起訖兩站
		}
		origin := t.StopTimes[0]
		dest := t.StopTimes[len(t.StopTimes)-1]
		out = append(out, model.RailTrain{
			TrainNo:   t.TrainInfo.TrainNo,
			Type:      t.TrainInfo.TrainTypeName.ZhTw,
			From:      origin.StationName.ZhTw,
			To:        dest.StationName.ZhTw,
			Departure: origin.DepartureTime,
			Arrival:   dest.ArrivalTime,
			Operator:  model.OperatorTRA,
		})
	}
	return out, nil
}

// --- 高鐵 THSR：起訖站每日時刻表 ---

type thsrStopTime struct {
	StationName   nameZh `json:"StationName"`
	ArrivalTime   string `json:"ArrivalTime"`
	DepartureTime string `json:"DepartureTime"`
}

type thsrTimetableItem struct {
	DailyTrainInfo struct {
		TrainNo string `json:"TrainNo"`
	} `json:"DailyTrainInfo"`
	OriginStopTime      thsrStopTime `json:"OriginStopTime"`
	DestinationStopTime thsrStopTime `json:"DestinationStopTime"`
}

func (c *Client) thsrTimetable(ctx context.Context, from, to, date string) ([]model.RailTrain, error) {
	path := fmt.Sprintf("/v2/Rail/THSR/DailyTimetable/OD/%s/to/%s/%s?%%24format=JSON", from, to, date)
	b, err := c.Get(ctx, path)
	if err != nil {
		return nil, fmt.Errorf("thsr timetable: %w", err)
	}

	var items []thsrTimetableItem
	if err := json.Unmarshal(b, &items); err != nil {
		return nil, fmt.Errorf("decode thsr timetable: %w", err)
	}

	out := make([]model.RailTrain, 0, len(items))
	for _, it := range items {
		out = append(out, model.RailTrain{
			TrainNo:   it.DailyTrainInfo.TrainNo,
			Type:      "高鐵",
			From:      it.OriginStopTime.StationName.ZhTw,
			To:        it.DestinationStopTime.StationName.ZhTw,
			Departure: it.OriginStopTime.DepartureTime,
			Arrival:   it.DestinationStopTime.ArrivalTime,
			Operator:  model.OperatorTHSR,
		})
	}
	return out, nil
}
