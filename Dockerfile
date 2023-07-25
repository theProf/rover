# Prep base stage
ARG TF_VERSION=1.5.3

# Build ui
FROM node:16-alpine as ui
WORKDIR /src
# Copy specific package files
COPY --link ./ui/package-lock.json ./
COPY --link ./ui/package.json ./
COPY --link ./ui/babel.config.js ./
# Set Progress, Config and install
RUN npm set progress=false && npm config set depth 0 && npm install
# Copy source
# Copy Specific Directories
COPY --link ./ui/public ./public
COPY --link ./ui/src ./src
# build (to dist folder)
RUN npm run build

# Build rover
FROM golang:1.19 AS rover
WORKDIR /src
# Copy full source
COPY --link . .
# Copy ui/dist from ui stage as it needs to embedded
COPY --link --from=ui ./src/dist ./ui/dist
# Build rover
RUN go get -d -v golang.org/x/net/html  
RUN CGO_ENABLED=0 GOOS=linux go build -o rover .

# Release stage
FROM hashicorp/terraform:$TF_VERSION AS release
# Install Google Chrome
RUN apk add chromium
# Copy terraform binary to the rover's default terraform path
RUN cp /bin/terraform /usr/local/bin/terraform
# Copy rover binary
COPY --link --from=rover /src/rover /bin/rover
RUN chmod +x /bin/rover

WORKDIR /src

ENTRYPOINT [ "/bin/rover" ]
