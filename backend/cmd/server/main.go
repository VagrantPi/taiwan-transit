package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"taiwan-transit-backend/internal/config"
	"taiwan-transit-backend/internal/handler"
	"taiwan-transit-backend/internal/tdx"
)

func main() {
	cfg := config.Load()

	tdxClient := tdx.NewClient(cfg.TDXClientID, cfg.TDXClientSecret)
	h := handler.New(tdxClient)

	srv := &http.Server{
		Addr:         ":" + cfg.Port,
		Handler:      h.Routes(),
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 30 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// 於背景啟動服務。
	go func() {
		log.Printf("taiwan-transit backend 監聽於 :%s", cfg.Port)
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatalf("server error: %v", err)
		}
	}()

	// 等待中止訊號後優雅關閉。
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)
	<-stop

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("graceful shutdown failed: %v", err)
	}
	log.Println("server stopped")
}
