FROM golang:1.11-alpine AS build-env
RUN apk --no-cache add git
ADD authserver /go/src/app
RUN cd /go/src/app && go get -v 
RUN cd /go/src/app && go build -o goapp

# final stage
FROM alpine
WORKDIR /app
COPY --from=build-env /go/src/app /app/
ENTRYPOINT ./goapp