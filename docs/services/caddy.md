# Caddy service (`docker-compose/compose.core.yml`)

## Vai trò
- Reverse proxy động từ Docker labels.
- Gom route cho app + dịch vụ ops.

## Cấu hình chính
- Image: `lucaslorentz/caddy-docker-proxy:2.9.1-alpine`
- Port publish: `80:80`
- Volumes:
  - Docker socket read-only
  - `caddy_data:/data`
  - `caddy_config:/config`
- Label global:
  - `caddy.email=${CADDY_EMAIL}`
  - `caddy.auto_https=disable_redirects`

## ENV liên quan
- `CADDY_EMAIL` (**bắt buộc**): email đăng ký cert.
- `DOCKER_SOCK` (optional): override đường dẫn Docker socket.
- `STACK_NAME` (**bắt buộc**): dùng để định danh ingress network `${STACK_NAME}_net`.

## Lưu ý
- Public traffic hiện đi qua Cloudflare Tunnel nên upstream từ cloudflared vào Caddy bằng HTTP nội bộ.
- Basic auth cho từng virtual host được khai báo ở labels của từng service (`CADDY_AUTH_USER`, `CADDY_AUTH_HASH`).
