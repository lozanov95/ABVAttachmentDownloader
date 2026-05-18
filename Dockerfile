FROM golang:1.26 AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download && go mod verify
COPY main.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -o abv-attachment-downloader main.go

FROM chromedp/headless-shell@sha256:313ed7255ae1e155fb157631a6d4c0eb8b65bbe06de9e704ed834399bdf678ff
RUN apt-get update && apt-get install -y zip unzip
COPY --from=builder /app/abv-attachment-downloader /usr/local/bin
WORKDIR /app
COPY download.sh ./
VOLUME [ "/downloads"]
WORKDIR /tmp/zips
CMD ["/bin/bash"]