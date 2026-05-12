# Plan: triển khai Litestream + Tinyauth

## Context

User muốn thay Basic Auth của Caddy bằng Tinyauth, đồng thời thêm Litestream để backup/replicate các SQLite DB trong stack.

Mục tiêu:

- Dữ liệu an toàn trước, hiệu năng sau.
- Cấu hình mở rộng được cho nhiều app/DB.
- Env theo prefix `LITESTREAM_` và `TINYAUTH_`.
- Cập nhật task checklist và `.opushforce.message` theo `CLAUDE.md`.

---

## Phạm vi file dự kiến chỉnh

### `compose.apps.yml`

- Thêm service `tinyauth`.
- Thêm/điều chỉnh volume SQLite.
- Đổi Caddy auth labels của app từ `basic_auth` sang `forward_auth` tới Tinyauth.

### `docker-compose/compose.ops.yml`

- Đổi auth labels của Dozzle/Filebrowser/WebSSH từ `basic_auth` sang `forward_auth` tới Tinyauth.

### `docker-compose/compose.core.yml`

- Nếu cần, giữ/kiểm tra `caddy.auto_https=disable_redirects` đã có để phù hợp Cloudflared/Tailscale.

### `.env.example`

- Thay khối Caddy Basic Auth bằng khối Tinyauth đầy đủ.
- Thêm khối Litestream env prefix `LITESTREAM_`.

### `litestream.yml` hoặc `services/litestream/litestream.yml`

- Config multi-DB dùng env prefix `LITESTREAM_`, dựa trên mẫu user đưa.

### `tasks/2026-05-12-01-bo-sung-tinyauth.md`

- Cập nhật checklist.
- Cập nhật file liên quan.
- Cập nhật kết quả kiểm tra.

### `.opushforce.message`

- Cập nhật đúng format bắt buộc.

---

## Hướng triển khai

### 1. Xác minh tài liệu Tinyauth v5

- Xác minh docs Tinyauth v5 hiện hành từ upstream/local README nếu truy cập được để liệt kê env hỗ trợ.
- Nếu docs không truy cập được, dùng env phổ biến của Tinyauth v5 nhưng ghi rõ nguồn/giới hạn trong task note.

### 2. Thêm service `tinyauth`

Thông tin dự kiến:

```yaml
container_name: "tinyauth"
image: ghcr.io/steveiliop56/tinyauth:v5
env_file: ./.env
```

Yêu cầu:

- Mount SQLite DB riêng của Tinyauth dưới `${DOCKER_VOLUMES_ROOT}/tinyauth`.
- Join `app_net`.
- `restart: unless-stopped`.
- Thêm healthcheck nếu image có endpoint phù hợp.

### 3. Chuyển Caddy auth

Thực hiện:

- Xóa labels `caddy.basic_auth=*` và `caddy_1.basic_auth=*` ở app/ops.
- Thêm labels `forward_auth` trỏ tới `tinyauth:<port>` cho các route cần bảo vệ.
- Giữ `reverse_proxy` hiện có.
- Nếu Tinyauth cần auth URL/callback host, cấu hình bằng `TINYAUTH_` env.

Lưu ý:

- Forward auth label syntax của `lucaslorentz/caddy-docker-proxy` phải đúng để tránh sinh Caddyfile sai.

### 4. Thêm Litestream

Service dự kiến:

- Image: `litestream/litestream` hoặc image chính thức phù hợp.
- Config `dbs` gồm nhiều entries:
  - Tinyauth SQLite.
  - App SQLite mẫu nếu có.

S3 replica dùng các env:

```env
LITESTREAM_S3_ENDPOINT=
LITESTREAM_S3_BUCKET=
LITESTREAM_S3_ACCESS_KEY_ID=
LITESTREAM_S3_SECRET_ACCESS_KEY=
```

Multi-DB path:

```env
LITESTREAM_TINYAUTH_S3_PATH=
```

Mục tiêu là mỗi app/DB có path riêng, tránh ghi đè dữ liệu.

Policy an toàn theo mẫu:

```yaml
sync-interval: 5s
snapshot-interval: 30m
retention: 48h
retention-check-interval: 1h
```

Lưu ý quan trọng:

- Litestream không tự restore nếu chưa có command restore.
- Task hiện yêu cầu lưu trữ/replicate, chưa yêu cầu restore tự động.

### 5. Cập nhật `.env.example`

Thêm khối `TINYAUTH_*`:

- Giải thích đầy đủ.
- Default rõ ràng.
- Option list trong comment.
- Link/hướng dẫn OIDC Google/GitHub nếu cần.
- Giữ `CADDY_EMAIL`.
- Bỏ hoặc đánh dấu legacy `CADDY_AUTH_USER/HASH` nếu không còn dùng.

Thêm khối `LITESTREAM_*`:

- Hướng dẫn S3/Supabase/AWS.
- Hỗ trợ multi-DB path.
- Dùng prefix rõ ràng để dễ mở rộng.

---

## Verification

Cần kiểm tra:

- Chạy `docker compose config` với các compose file liên quan để validate YAML/env interpolation.
- Nếu khả thi, chạy service hoặc ít nhất kiểm tra label render đúng.
- Không claim UI verified nếu không chạy được container/browser.

Lệnh kiểm tra gợi ý:

```bash
docker compose \
  -f docker-compose/compose.core.yml \
  -f compose.apps.yml \
  -f docker-compose/compose.ops.yml \
  config
```

---

## Rủi ro/điểm cần chú ý

1. **Tinyauth v5 env phải bám docs**
   - Cần xác minh trước khi viết `.env.example` quá rộng.

2. **Forward auth label syntax phải chính xác**
   - Đặc biệt với `lucaslorentz/caddy-docker-proxy`.
   - Sai syntax có thể khiến Caddyfile render lỗi hoặc auth không hoạt động.

3. **Litestream chỉ replicate, chưa restore tự động**
   - Nếu muốn HA/DR đầy đủ, cần thêm quy trình restore riêng.

4. **Mount volume SQLite phải thống nhất**
   - App nào dùng SQLite cần xác định chính xác DB path.
   - Litestream phải mount được cùng path hoặc read-only phù hợp.

5. **An toàn dữ liệu ưu tiên trước hiệu năng**
   - Giữ interval replicate ngắn.
   - Tách path theo từng DB.
   - Không dùng chung object path cho nhiều database.

---

## Checklist triển khai

- [ ] Xác minh docs/env Tinyauth v5.
- [ ] Thêm service `tinyauth`.
- [ ] Mount volume SQLite cho Tinyauth.
- [ ] Chuyển label Caddy từ `basic_auth` sang `forward_auth`.
- [ ] Thêm service `litestream`.
- [ ] Tạo config `litestream.yml`.
- [ ] Bổ sung env `TINYAUTH_*` vào `.env.example`.
- [ ] Bổ sung env `LITESTREAM_*` vào `.env.example`.
- [ ] Cập nhật task markdown.
- [ ] Cập nhật `.opushforce.message`.
- [ ] Chạy `docker compose config`.
- [ ] Ghi rõ phần nào đã verify, phần nào chưa verify.

---

## Kết luận

Kế hoạch triển khai theo hướng thay Basic Auth bằng Tinyauth và bổ sung Litestream để replicate SQLite là phù hợp với mục tiêu ưu tiên an toàn dữ liệu.

Trọng tâm cần kiểm soát là:

- Cú pháp `forward_auth` của Caddy Docker Proxy.
- Env thực tế của Tinyauth v5.
- Path SQLite chính xác cho từng service.
- Quy trình restore Litestream nếu muốn hoàn thiện phương án khôi phục dữ liệu.
