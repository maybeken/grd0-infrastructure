FROM golang:alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /proxy .

FROM scratch
COPY --from=builder /proxy /proxy
EXPOSE 8088
ENTRYPOINT ["/proxy"]
