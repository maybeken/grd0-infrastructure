# go-https-proxy

## Build & Run

```bash
make build        # builds to bin/$(GOARCH)/proxy
./bin/amd64/proxy # runs on :8088
```

## Behavior

- Listens on `:8088`
- Set `ENV=production` to disable verbose request/response logging
- Uses `github.com/elazarl/goproxy`

## No tests

This repo has no test files.

## Workflow

- After any code change, run `make build` to produce a fresh binary before testing.
