package tdx

import (
	"context"
	"encoding/json"
	"fmt"

	"taiwan-transit-backend/internal/model"
)

// TDX StopStatus 對照：0 正常,1 尚未發車,2 交管不停靠,3 末班車已過,4 今日未營運。
var busStopStatusText = map[int]string{
	0: "正常",
	1: "尚未發車",
	2: "交管不停靠",
	3: "末班車已過",
	4: "今日未營運",
}

type busEstimateRaw struct {
	RouteName    nameZh `json:"RouteName"`
	Direction    int    `json:"Direction"`
	StopName     nameZh `json:"StopName"`
	EstimateTime *int   `json:"EstimateTime"` // 秒；可能為 null
	StopStatus   int    `json:"StopStatus"`
	SrcUpdateTime string `json:"SrcUpdateTime"`
}

// BusEstimates 取得指定縣市某路線的公車到站動態，回傳正規化 DTO。
func (c *Client) BusEstimates(ctx context.Context, city, route string) ([]model.BusEstimate, error) {
	b, err := c.Get(ctx, "/v2/Bus/EstimatedTimeOfArrival/City/"+city+"/"+route+"?%24format=JSON")
	if err != nil {
		return nil, fmt.Errorf("bus estimate: %w", err)
	}

	var raws []busEstimateRaw
	if err := json.Unmarshal(b, &raws); err != nil {
		return nil, fmt.Errorf("decode bus estimate: %w", err)
	}

	out := make([]model.BusEstimate, 0, len(raws))
	for _, r := range raws {
		minutes := -1
		// 僅在正常狀態且有預估秒數時換算分鐘，其餘以 -1 表示特殊狀態。
		if r.StopStatus == 0 && r.EstimateTime != nil {
			minutes = *r.EstimateTime / 60
		}
		status := busStopStatusText[r.StopStatus]
		if status == "" {
			status = "未知"
		}
		out = append(out, model.BusEstimate{
			RouteName:       r.RouteName.ZhTw,
			Direction:       r.Direction,
			StopName:        r.StopName.ZhTw,
			EstimateMinutes: minutes,
			Status:          status,
			UpdatedAt:       r.SrcUpdateTime,
		})
	}
	return out, nil
}
