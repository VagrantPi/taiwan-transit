// Package cache 提供最小的執行緒安全 TTL 記憶體快取，
// 用於降低對 TDX 的請求量（站點等靜態資料長 TTL、到站/車位等動態資料短 TTL）。
package cache

import (
	"sync"
	"time"
)

type entry[V any] struct {
	value     V
	expiresAt time.Time
}

// TTLCache 是以 string 為鍵的泛型 TTL 快取。
type TTLCache[V any] struct {
	mu    sync.RWMutex
	items map[string]entry[V]
}

// New 建立一個 TTLCache。
func New[V any]() *TTLCache[V] {
	return &TTLCache[V]{items: make(map[string]entry[V])}
}

// Get 回傳鍵對應且尚未過期的值；ok 為 false 表示未命中或已過期。
func (c *TTLCache[V]) Get(key string) (V, bool) {
	c.mu.RLock()
	e, found := c.items[key]
	c.mu.RUnlock()

	var zero V
	if !found || time.Now().After(e.expiresAt) {
		return zero, false
	}
	return e.value, true
}

// Set 以指定 TTL 寫入鍵值。
func (c *TTLCache[V]) Set(key string, value V, ttl time.Duration) {
	c.mu.Lock()
	c.items[key] = entry[V]{value: value, expiresAt: time.Now().Add(ttl)}
	c.mu.Unlock()
}
