package tdx

import (
	"context"
	"encoding/json"
	"fmt"

	"taiwan-transit-backend/internal/model"
)

// nameZh 對應 TDX 常見的多語名稱物件 {"Zh_tw": "...", "En": "..."}。
type nameZh struct {
	ZhTw string `json:"Zh_tw"`
	En   string `json:"En"`
}

type bikeStationRaw struct {
	StationUID     string `json:"StationUID"`
	StationName    nameZh `json:"StationName"`
	StationPosition struct {
		Lat float64 `json:"PositionLat"`
		Lon float64 `json:"PositionLon"`
	} `json:"StationPosition"`
	BikesCapacity int `json:"BikesCapacity"`
}

type bikeAvailabilityRaw struct {
	StationUID           string `json:"StationUID"`
	AvailableRentBikes   int    `json:"AvailableRentBikes"`
	AvailableReturnBikes int    `json:"AvailableReturnBikes"`
	UpdateTime           string `json:"UpdateTime"`
}

// BikeStations 取得指定縣市的 YouBike 站點並結合即時車位，回傳正規化 DTO。
// city 為 TDX 縣市英文代碼，如 "Taipei"、"NewTaipei"、"Taichung"。
func (c *Client) BikeStations(ctx context.Context, city string) ([]model.BikeStation, error) {
	stationBytes, err := c.Get(ctx, "/v2/Bike/Station/City/"+city+"?%24format=JSON")
	if err != nil {
		return nil, fmt.Errorf("bike station: %w", err)
	}
	availBytes, err := c.Get(ctx, "/v2/Bike/Availability/City/"+city+"?%24format=JSON")
	if err != nil {
		return nil, fmt.Errorf("bike availability: %w", err)
	}

	var stations []bikeStationRaw
	if err := json.Unmarshal(stationBytes, &stations); err != nil {
		return nil, fmt.Errorf("decode bike station: %w", err)
	}
	var avails []bikeAvailabilityRaw
	if err := json.Unmarshal(availBytes, &avails); err != nil {
		return nil, fmt.Errorf("decode bike availability: %w", err)
	}

	availByUID := make(map[string]bikeAvailabilityRaw, len(avails))
	for _, a := range avails {
		availByUID[a.StationUID] = a
	}

	out := make([]model.BikeStation, 0, len(stations))
	for _, s := range stations {
		a := availByUID[s.StationUID] // 未命中時為零值，車位以 0 呈現
		out = append(out, model.BikeStation{
			ID:              s.StationUID,
			Name:            s.StationName.ZhTw,
			Lat:             s.StationPosition.Lat,
			Lng:             s.StationPosition.Lon,
			AvailableRent:   a.AvailableRentBikes,
			AvailableReturn: a.AvailableReturnBikes,
			Total:           s.BikesCapacity,
			UpdatedAt:       a.UpdateTime,
		})
	}
	return out, nil
}
