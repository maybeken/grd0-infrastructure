package main

import (
	"context"
	"log"
	"net"
	"net/http"
	"net/http/httputil"

	"github.com/elazarl/goproxy"
)

func main() {
	proxy := goproxy.NewProxyHttpServer()

	proxy.OnRequest().DoFunc(func(req *http.Request, ctx *goproxy.ProxyCtx) (*http.Request, *http.Response) {
		dump, err := httputil.DumpRequestOut(req, false)
		if err != nil {
			log.Printf("Error dumping request: %v", err)
		} else {
			log.Printf("Request: %s", string(dump))
		}
		return req, nil
	})

	proxy.OnRequest().HandleConnectFunc(func(host string, ctx *goproxy.ProxyCtx) (*goproxy.ConnectAction, string) {
		log.Printf("CONNECT: %s", host)
		return nil, host
	})

	proxy.ConnectDialWithReq = func(req *http.Request, network, addr string) (net.Conn, error) {
		log.Printf("ConnectDialWithReq: network=%s addr=%s req.URL=%s", network, addr, req.URL.String())
		host, port, err := net.SplitHostPort(addr)
		if err != nil {
			log.Printf("SplitHostPort error: %v", err)
			return net.Dial(network, addr)
		}
		log.Printf("host=%s port=%s", host, port)
		if host == "cloud.grd0.net" {
			log.Printf("Resolving custom DNS for cloud.grd0.net")
			newAddr, err := net.ResolveTCPAddr("tcp", "caddy:443")
			if err != nil {
				log.Printf("ResolveTCPAddr error: %v", err)
				return nil, err
			}
			log.Printf("Resolved to %s", newAddr.String())
			return net.Dial("tcp", newAddr.String())
		}
		dialer := &net.Dialer{
			Resolver: &net.Resolver{
				PreferGo: true,
				Dial: func(ctx context.Context, network, address string) (net.Conn, error) {
					d := &net.Dialer{}
					return d.DialContext(ctx, network, "8.8.8.8:53")
				},
			},
		}
		return dialer.Dial(network, addr)
	}

	log.Println("Starting HTTPS proxy on :8088")
	log.Println("Configure your client to use http://localhost:8088 as the HTTP/HTTPS proxy")

	if err := http.ListenAndServe(":8088", proxy); err != nil {
		log.Fatal(err)
	}
}
