package config

import (
	"os"
)

// Config 保存後端服務的執行設定，皆來自環境變數。
type Config struct {
	Port string // HTTP 服務埠號

	// TDX 運輸資料流通服務平臺的 OAuth2 client credentials
	TDXClientID     string
	TDXClientSecret string
}

// Load 從環境變數讀取設定，並對缺漏值套用合理預設。
func Load() Config {
	return Config{
		Port:            getenv("PORT", "8080"),
		TDXClientID:     os.Getenv("TDX_CLIENT_ID"),
		TDXClientSecret: os.Getenv("TDX_CLIENT_SECRET"),
	}
}

func getenv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
