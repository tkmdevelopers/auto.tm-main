# Android Notification Icon Guide (Phase D)

To eliminate `PlatformException(invalid_icon, resource ... not found)` and ensure a crisp status-bar icon, add a dedicated monochrome notification icon resource.

## 1. Asset Requirements
- Name: `ic_stat_notify.png`
- Color: Pure white (#FFFFFF) on a fully transparent background.
- Shape: Simple glyph (no gradients, no shadow) per Android design guidelines.
- Size: 24x24 dp (baseline). Provide multiple densities or leverage Android's automatic scaling.

Recommended to export a base 24x24 px vector (SVG) and generate raster PNGs per density:
- mdpi: 24x24
- hdpi: 36x36
- xhdpi: 48x48
- xxhdpi: 72x72
- xxxhdpi: 96x96

## 2. Placement
Put the files in:
```
android/app/src/main/res/drawable/ic_stat_notify.png        (optional single-density fallback)
android/app/src/main/res/mipmap-mdpi/ic_stat_notify.png
android/app/src/main/res/mipmap-hdpi/ic_stat_notify.png
android/app/src/main/res/mipmap-xhdpi/ic_stat_notify.png
android/app/src/main/res/mipmap-xxhdpi/ic_stat_notify.png
android/app/src/main/res/mipmap-xxxhdpi/ic_stat_notify.png
```

You can use only mipmap folders (preferred for launcher-style assets) or drawable + mipmap. Avoid adaptive foreground/background layers for status bar icons.

## 3. Code Integration
`NotificationService` now attempts to use `ic_stat_notify` for:
- Initialization: `AndroidInitializationSettings('ic_stat_notify')`
- Notification details: `AndroidNotificationDetails(... icon: 'ic_stat_notify')`

If the resource isn't present, Android will fallback; if you encounter an `invalid_icon` crash, ensure the PNG exists in at least one density folder.

## 4. Verification Steps
After adding assets, run:
```cmd
flutter clean
flutter pub get
flutter run --release
```
Trigger a test notification (send a Firebase test message or call a local show) and confirm:
- Status bar shows your monochrome icon (white glyph) without tinted background.
- No `invalid_icon` exception in logcat.

## 5. Optional: Channel Customization
You can later differentiate channels (e.g., marketing vs system) by creating additional `AndroidNotificationDetails` with different channel IDs and importance.

## 6. iOS Considerations
iOS uses the app icon; no custom status-bar glyph is required. Ensure transparency handling is correct in the app icon asset catalog.

## 7. Troubleshooting
| Issue | Cause | Fix |
|-------|-------|-----|
| invalid_icon PlatformException | Resource name mismatch or missing PNG | Verify filename & directory; rebuild after `flutter clean`. |
| Icon appears colored/tinted incorrectly | Used adaptive or multi-color asset | Replace with flat white transparent PNG. |
| Icon too blurry | Provided only mdpi asset | Supply all densities or use vector + raster generation tool. |

## 8. Generation Tips
Use Android Studio Asset Studio or command-line tools (e.g., ImageMagick) to resize:
```cmd
magick ic_stat_notify.png -resize 24x24 mipmap-mdpi/ic_stat_notify.png
```
Repeat for each density with target size above.

---
Phase D implementation updated the service; add assets next to finalize.
