package cache

import (
	"testing"
	"time"
)

func TestTTLCache_SetGet(t *testing.T) {
	c := New[int]()

	if _, ok := c.Get("missing"); ok {
		t.Fatal("未設定的鍵不應命中")
	}

	c.Set("a", 42, time.Minute)
	v, ok := c.Get("a")
	if !ok || v != 42 {
		t.Fatalf("期望命中 42，得到 v=%d ok=%v", v, ok)
	}
}

func TestTTLCache_Expiry(t *testing.T) {
	c := New[string]()
	c.Set("k", "v", 10*time.Millisecond)

	if _, ok := c.Get("k"); !ok {
		t.Fatal("未過期前應命中")
	}
	time.Sleep(20 * time.Millisecond)
	if _, ok := c.Get("k"); ok {
		t.Fatal("過期後不應命中")
	}
}
