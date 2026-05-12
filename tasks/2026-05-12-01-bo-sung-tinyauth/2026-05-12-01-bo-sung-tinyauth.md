# Task: <Triển khai litestream + tinyauth>

## User prompt

> Triển khai thêm litestream để lưu trữ các sqlite dùng cho các app trong codebase
    1. Dựa vào cấu hình tại file: `H:\nodejs-tester\dockerstack-pocketbase\services\app\litestream.yml` với mục tiêu là đảm bảo dữ liệu an toàn nhất, kế đến là hiệu năng cao
    2. Có thể mở rộng khi nhiều app cũng sử dụng litestream này, ví dụ: tinyauth sử dụng, và các app cũng sử dụng được. Các app sẽ sử dụng các file sqlite khác nhau.
    3. Tất cả .env dùng prefix: `LITESTREAM_`


> Triển khai thêm app `tinyauth`: dùng `container_name: "tinyauth" image: ghcr.io/steveiliop56/tinyauth:v5`, tất cả auth caddy chuyển qua phần tinyauth

    1. Tất cả .env dùng prefix: `TINYAUTH_`
    2. Hãy dùng tất cả env mà tinyauth hỗ trợ, có giá trị mặc định, có diễn giải công dụng, cách cấu hình, nếu là lựa chọn phải có đầy đủ giá trị trong phần comment để dễ dàng triển khai. Các cấu hình cần thấy thông tin khác, thì phải có link để lấy các thông tin như google oidc....
    3. Phải tắt cảnh báo direct giữa http và https, vì hệ thống triển khai thông qua cloudfared tunnel và tailscale.

## Thông tin cần xác nhận

Agent điền mục này nếu prompt thiếu dữ liệu cần thiết để triển khai đúng.

- [x] Không cần hỏi thêm
- [ ] Cần hỏi user trước khi làm

Câu hỏi cần xác nhận:

- User đã xác nhận dùng env Tinyauth phổ biến cho triển khai nhiều app.
- User bổ sung yêu cầu: lần đầu `LITESTREAM_INIT_MODE=true` thì không restore; các lần deploy bình thường phải restore trước khi app chạy.

## Checklist triển khai

Agent tự tạo checklist từ `User prompt`, rồi đánh dấu khi từng bước hoàn tất.

- [x] Đọc yêu cầu user và xác định phạm vi thay đổi
- [x] Kiểm tra rule bắt buộc trong `CLAUDE.md`
- [x] Xác định file/thư mục cần chỉnh
- [x] Triển khai thay đổi cần thiết
- [x] Kiểm tra lại thay đổi phù hợp yêu cầu
- [x] Cập nhật `.opushforce.message` đúng format trong `CLAUDE.md`
- [x] Trả lời user ngắn gọn kèm file đã chỉnh

## File liên quan

Agent cập nhật danh sách file đã đọc/chỉnh.

- `compose.apps.yml`
- `docker-compose/compose.ops.yml`
- `docker-compose/compose.deploy.yml`
- `docker-compose/compose.core.yml`
- `docker-compose/scripts/dc.sh`
- `.env.example`
- `.env`
- `.env.local`
- `services/litestream/litestream.yml`
- `services/litestream/entrypoint.sh`
- `.opushforce.message`

## Kết quả kiểm tra

Agent ghi command đã chạy hoặc lý do không chạy.

- Đã chạy: `bash docker-compose/scripts/dc.sh config >/tmp/docker-stack-template-compose-config.yml`
- Kết quả: pass, không có output lỗi.

## Ghi chú cho lần sau

Chỉ ghi thông tin hữu ích trực tiếp cho task này, không thay cho memory dài hạn.

- `LITESTREAM_INIT_MODE=true`: lần đầu tạo DB mới, không restore.
- `LITESTREAM_INIT_MODE=false`: deploy bình thường, restore bắt buộc trước khi `app`/`tinyauth` chạy.
- Tinyauth env trong `.env*` dùng prefix `TINYAUTH_`; compose map sang env runtime phổ biến của container.
