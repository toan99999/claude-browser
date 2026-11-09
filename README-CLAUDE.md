# Claude — Reynard fork mở thẳng Claude, ẩn toolbar

Gốc: https://github.com/minh-ton/reynard-browser (Reynard 0.20.1, trình duyệt Gecko cho iOS 13+)
Bản này: **Claude** — tên app `Claude`, Bundle ID `ai.claude.browser`, URL scheme `claude://`

## Đã đổi gì (19 file sửa + 1 workflow mới, giống bản Muse/ChatGPT — cộng thêm 3 lỗi sửa sau build #3)

| Chức năng | Cách làm |
|---|---|
| Mở app vào thẳng Claude | `BrowserViewController.viewDidLoad`: sau `createInitialTab()` thì mở `https://claude.ai` cho tab đang chọn. Tab mới cũng vậy: mặc định `NewTabSettings` đổi thành `.customURL` + `customNewTabURL = https://claude.ai` trong `BrowserPreferences.swift`. Màn hình mở đầu đổi từ `homepage` sang `lastTab` để không ép hiện trang chủ Reynard. |
| Luôn ẩn thanh công cụ | `BrowserChrome.apply`: ép `topState = .hidden`, `bottomState = .hidden` bất kể presentation/mode. `BrowserViewController.applyPhoneLayout / applyCompactLayout / applyPadLayout`: nội dung web neo vào mép màn hình (safe area) thay vì neo vào toolbar, nên web chiếm toàn màn hình. |
| Chạm 3 ngón tay hiện/ẩn thanh công cụ | `BrowserChrome.isAddressBarVisible` (mặc định tắt) + cử chỉ chạm 3 ngón tay trong `BrowserViewController`: chạm 3 ngón thì thanh công cụ hiện lên, chạm lại thì ẩn đi; nội dung web tự co lại/tràn ra theo. |
| Nút ← → khi thanh công cụ hiện | `updateNavigationButtons()`: chỉ khi thanh công cụ đang hiện (`isAddressBarVisible`) thì nút quay lại/tiến mới hoạt động theo lịch sử thật của tab (`canGoBack`/`canGoForward`); khi thanh công cụ ẩn thì cả hai nút đều tắt. Cử chỉ vuốt quay lại vẫn tắt hẳn. |
| Hộp thoại xin quyền không tự từ chối trong im lặng | `PermissionPromptPresenter.findPresenter()`: khi trang web xin mic/camera mà app chưa tìm được màn hình để hiện hộp thoại (đang mở app hoặc chuyển màn hình), chờ tối đa ~3 giây cho scene lên foreground rồi mới hiện hộp thoại; chỉ từ chối khi hoàn toàn không có màn hình nào. Trước đây code trả về "từ chối" ngay khi `topViewController()` là nil, nên trang web có thể bị ghi vào danh sách từ chối dù mặc định là "Hỏi trước khi cho phép" (đã xảy ra với chatgpt.com lúc 09:17 ngày 2026-11-08 ở bản ChatGPT). |
| Giữ phiên chat khi mở lại app | `BrowserViewController.viewDidLoad`: chỉ mở `https://claude.ai` khi tab đang hoàn toàn trống (tab mới, chưa có URL). Trước đây so sánh cứng `tab.url != "https://claude.ai"` còn khớp cả URL đoạn chat đã khôi phục (`.../c/...`) và URL đã chuẩn hóa (`...ai/`), nên mỗi lần mở lại app là đoạn chat đang mở bị vứt đi. |
| Chia sẻ "Open in Claude" hoạt động | `OpenInViewController.browserOpenURL`: mở link chia sẻ bằng `claude://open?url=...` thay vì `reynard://open?url=...` (scheme cũ không còn app nào nhận), thông báo lỗi đổi thành "Unable to open Claude.". App chính đã xử lý sẵn `claude://open?url=` trong `SceneDelegate.resolvedBrowserURL`. |
| Gọn file .tipa | `tools/release/create-ipa.sh`: nén zip với `-9 -D` (nén tối đa, không ghi các thư mục rỗng — bản cũ có 509 mục thư mục rỗng), giảm ~800 KB. Chỉ đổi vỏ zip, gói app đã ký bên trong không động vào nên chữ ký vẫn nguyên. |
| Tắt quay lại | `canGoBack=false`, `backPreviewImage=nil`, tắt vuốt quay lại và `interactivePopGestureRecognizer`, `isToolbarEnabled=false` trong `BrowserViewController`. |
| Đổi tên / Bundle ID | `APP_DISPLAY_NAME = Claude` (`Reynard.xcconfig`); `ai.claude.browser`, `.Helper`, `.OpenIn` trong `project.pbxproj`, `Info.plist`, entitlements, `create-ipa.sh`, `OpenInViewController.swift`; scheme `reynard://` → `claude://` (`SceneDelegate.swift`, `Info.plist`). |
| Không tự cập nhật về Reynard | `BrowserUpdates.fetchUpdates()` tắt, file sideload đổi thành `Claude.ipa`. |
| Build cho fork | `.github/workflows/build.yml`: bỏ điều kiện `repository_owner == 'minh-ton'`, tên artifact đổi thành `Claude.ipa` / `Claude-TrollStore.tipa` / `Claude-Jailbroken.ipa`. Thêm `.github/workflows/build-claude.yml`: chỉ build bản TrollStore. |

Icon app đã đổi sang logo Claude (ngôi sao trắng trên nền cam, bản tối sao trắng trên nền tối, bản tô màu sao trắng trên nền đen) trong `Assets.xcassets/AppIcon.appiconset`.

## Cách build ra file .tipa (không build được trên máy Linux này)

Reynard dùng engine Gecko, phải build bằng Xcode trên macOS, tải Gecko, build Rust — máy Linux này không có Xcode nên **không biên dịch trực tiếp được ở đây**. Cách đúng là build trên GitHub Actions (macOS 26, Xcode 26.6, theo workflow gốc):

1. Tạo repo GitHub mới (ví dụ `claude-browser`), push toàn bộ thư mục `claude-browser/` lên, kèm submodule:
   ```bash
   git submodule update --init --recursive
   git add -A && git commit -m "Claude fork" && git push
   ```
   Workflow sẽ tự `git submodule update` cho `engine/firefox` và `support/idevice` nên không cần push Gecko lên.
2. Vào repo → **Actions** → **Build Claude (TrollStore)** → **Run workflow**.
3. Chờ build xong, tải artifact **Claude-TrollStore.tipa** về.
   - Lần đầu build Gecko rất lâu (có thể vài giờ, cache sccache / Gecko deps giúp các lần sau nhanh hơn). Nếu job fail, xem log ở bước `Build Gecko` / `Build app` trước, đừng chạy lại ngay.
   - Không cần tài khoản Apple Developer cho bản TrollStore: workflow gốc build `--no-signing` rồi fake-sign bằng `ldid`.

## Cài lên iPhone iOS 17.0

Theo README gốc, bản TrollStore dùng cho **iOS 14 – 16.6.1 và 17.0** — đúng máy iOS 17.0 bạn đang tìm. Cài file `Claude-TrollStore.tipa` bằng TrollStore trên máy đó. Bản thường `Claude.ipa` chỉ dùng cho AltStore/SideStore trên iOS 17.4+.

## Lưu ý / chưa kiểm chứng

- Code Swift chỉ kiểm tra bằng mắt + cân bằng ngoặc, **chưa biên dịch bằng Xcode** — lỗi biên dịch (nếu có) sẽ hiện ở lần chạy Actions đầu tiên.
- Ẩn toolbar là ẩn hẳn cả thanh trên + thanh dưới và nút địa chỉ. Muốn quay lại trang khác / mở tab mới sẽ phải dùng cử chỉ hoặc menu trong web — đây là hệ quả cố ý của yêu cầu "luôn ẩn". Nếu muốn giữ một cách mở tab (ví dụ vuốt hoặc nút nổi), nói mình để thêm.
- Đăng nhập Claude trong app vẫn qua web `claude.ai` như bình thường; Claude chỉ là vỏ trình duyệt, không lưu tài khoản riêng.
