# deploy.new.md

Hướng dẫn thay thế app/service mới với rủi ro thấp nhất.

## Mục tiêu
- Clone stack hiện tại để deploy dịch vụ khác.
- Chỉ thay phần app mà không phá core/ops/access.

## Bước 1 — Tạo workspace mới từ template

```bash
node scripts/clone-stack.js --output /opt/stacks --name service-b
```

Kết quả: `/opt/stacks/service-b` chứa bản sao repo (đã bỏ `.git`).

## Bước 2 — Thay app

### Cách A: giữ cấu trúc `services/app`
- Sửa `services/app/Dockerfile`
- Sửa `services/app/package.json`, code app.
- Giữ `compose.apps.yml` gần như nguyên trạng.

### Cách B: dùng image có sẵn
- Sửa service `app` trong `compose.apps.yml`:
  - đổi `image` sang image thực tế.
  - bỏ/điều chỉnh `build`.
  - map lại `APP_PORT` nếu khác.

## Bước 3 — Cập nhật env

Tối thiểu:

- `STACK_NAME`
- `PROJECT_NAME`
- `DOMAIN`
- `CADDY_EMAIL`
- `CADDY_AUTH_USER`
- `CADDY_AUTH_HASH`
- `APP_PORT`

Tùy chọn:

- `APP_HOST_PORT`, `NODE_ENV`, `HEALTH_PATH`
- `ENABLE_*`
- Tailscale block nếu cần private access.

## Bước 4 — Cloudflare

- Cập nhật `cloudflared/config.yml` theo hostname mới.
- Đảm bảo DNS record trỏ đúng tunnel.

## Bước 5 — Validate trước khi chạy

```bash
npm run dockerapp-validate:env
npm run dockerapp-validate:compose
```

Nếu có lỗi `❌` -> bắt buộc sửa trước khi deploy.

## Bước 6 — Deploy

```bash
npm run dockerapp-exec:up
npm run dockerapp-exec:ps
npm run dockerapp-exec:logs
```

## Bước 7 — Checklist hoàn thành theo từng lớp

### Lớp app
- `app` healthy.
- `http://127.0.0.1:${APP_HOST_PORT}` (nếu có publish).

### Lớp public
- Host `${PROJECT_NAME}.${DOMAIN}` truy cập OK.
- Basic auth hoạt động.

### Lớp ops (nếu bật)
- `logs.*`, `files.*`, `ttyd.*` truy cập được.

### Lớp access (nếu bật)
- Tailnet host nội bộ truy cập được.
- Keep-ip logs không báo lỗi Firebase/API.
- Truy cập ops bằng hostname+port qua tailnet:
  - `http://${STACK_NAME}.${TAILSCALE_TAILNET_DOMAIN}:${DOZZLE_HOST_PORT:-18080}`
  - `http://${STACK_NAME}.${TAILSCALE_TAILNET_DOMAIN}:${FILEBROWSER_HOST_PORT:-18081}`
  - `http://${STACK_NAME}.${TAILSCALE_TAILNET_DOMAIN}:${WEBSSH_HOST_PORT:-17681}`

## Tổng kết điểm cần đổi khi thay dịch vụ

1. `compose.apps.yml` (image/build/port/health).
2. `.env` (identity + domain + auth + port + flags).
3. `cloudflared/config.yml` (ingress hostnames).
4. Tùy chọn: script CI/CD để reflect tên stack mới.
