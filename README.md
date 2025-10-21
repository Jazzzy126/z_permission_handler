# z_permission_handler

[![pub package](https://img.shields.io/pub/v/z_permission_handler.svg)](https://pub.dev/packages/z_permission_handler)
[![Flutter](https://img.shields.io/badge/Flutter-2.18%2B-blue.svg)](https://flutter.dev)

Flutter 权限管理工具包，用于统一管理应用权限请求逻辑。
支持单个或多个权限的检查与请求，并自动展示权限说明 Toast 提示。

---

## 功能特性

* 自动处理权限多种状态（拒绝、永久拒绝、受限、部分访问等）
* 自动弹出权限说明 Toast（通过 [Toastification] 实现）
* 日志统一加 `[ZPermission]` 前缀，便于调试和追踪
* 支持 Android 和 iOS 平台

---

## 安装

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  z_permission_handler: ^0.0.2
```

然后执行：

```bash
flutter pub get
```

---

## 使用示例

### 检查单个权限

```dart
bool cameraGranted = await ZPermission.checkAndRequestPermission(
  context,
  ZPermissionItem: ZPermissionItem(
    title: "相机权限",
    desc: "允许应用访问相机，用于拍摄照片",
    permission: Permission.camera,
  ),
);

if (cameraGranted) {
  debugPrint("相机权限已获取 ✅");
} else {
  debugPrint("相机权限被拒绝 ❌");
}
```

### 检查多个权限

```dart
Map<ZPermissionItem, bool> permissions =
    await ZPermission.checkAndRequestPermissions(
  context,
  permissionItems: [
    ZPermissionItem(
      title: "相机权限",
      desc: "允许应用访问相机，用于拍摄照片",
      permission: Permission.camera,
    ),
    ZPermissionItem(
      title: "录音权限",
      desc: "允许应用使用麦克风进行录音或语音输入",
      permission: Permission.microphone,
    ),
  ],
);

permissions.forEach((item, granted) {
  debugPrint("${item.title}: ${granted ? '✅ 已授权' : '❌ 拒绝'}");
});
```

---

## 支持平台

* ✅ Android
* ✅ iOS

---

## License

MIT License，详情见 [LICENSE](LICENSE)。
