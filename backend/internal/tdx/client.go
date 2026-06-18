// Package tdx 封裝對 TDX 運輸資料流通服務平臺的存取。
// 平臺採 OAuth2 client_credentials 流程取得 access token，
// 再以 Bearer token 呼叫各運具的資料 API（公車、台鐵/高鐵、YouBike）。
package tdx

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"sync"
	"time"
)

const (
	defaultAuthURL = "https://tdx.transportdata.tw/auth/realms/TDXConnect/protocol/openid-connect/token"
	defaultBaseURL = "https://tdx.transportdata.tw/api/basic"
)

// Client 是 TDX API 的最小可用客戶端，內含 token 快取。
type Client struct {
	clientID     string
	clientSecret string
	httpClient   *http.Client

	authURL string // token 端點；測試時可覆寫指向假 server
	baseURL string // API 端點；測試時可覆寫指向假 server

	mu          sync.Mutex
	accessToken string
	expiresAt   time.Time
}

// NewClient 建立一個 TDX 客戶端。
func NewClient(clientID, clientSecret string) *Client {
	return &Client{
		clientID:     clientID,
		clientSecret: clientSecret,
		httpClient:   &http.Client{Timeout: 15 * time.Second},
		authURL:      defaultAuthURL,
		baseURL:      defaultBaseURL,
	}
}

type tokenResponse struct {
	AccessToken string `json:"access_token"`
	ExpiresIn   int    `json:"expires_in"`
}

// token 取得有效的 access token，必要時自動更新並快取。
func (c *Client) token(ctx context.Context) (string, error) {
	c.mu.Lock()
	defer c.mu.Unlock()

	if c.accessToken != "" && time.Now().Before(c.expiresAt) {
		return c.accessToken, nil
	}

	form := url.Values{}
	form.Set("grant_type", "client_credentials")
	form.Set("client_id", c.clientID)
	form.Set("client_secret", c.clientSecret)

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.authURL, strings.NewReader(form.Encode()))
	if err != nil {
		return "", fmt.Errorf("build token request: %w", err)
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("request token: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("token endpoint returned %d", resp.StatusCode)
	}

	var tr tokenResponse
	if err := json.NewDecoder(resp.Body).Decode(&tr); err != nil {
		return "", fmt.Errorf("decode token response: %w", err)
	}

	c.accessToken = tr.AccessToken
	// 提早 60 秒過期，避免邊界誤用。
	c.expiresAt = time.Now().Add(time.Duration(tr.ExpiresIn-60) * time.Second)
	return c.accessToken, nil
}

// Get 以已驗證的身分對 TDX basic API 發出 GET 請求，回傳原始 JSON bytes。
// path 範例： "/v2/Bike/Station/City/Taipei?%24format=JSON"
func (c *Client) Get(ctx context.Context, path string) ([]byte, error) {
	tok, err := c.token(ctx)
	if err != nil {
		return nil, err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, c.baseURL+path, nil)
	if err != nil {
		return nil, fmt.Errorf("build api request: %w", err)
	}
	req.Header.Set("Authorization", "Bearer "+tok)
	req.Header.Set("Accept", "application/json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("request api: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("tdx api %s returned %d", path, resp.StatusCode)
	}

	out, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("read api response: %w", err)
	}
	return out, nil
}
