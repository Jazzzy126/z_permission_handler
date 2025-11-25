# z_permission_handler

[![pub package](https://img.shields.io/pub/v/z_permission_handler.svg)](https://pub.dev/packages/z_permission_handler)
[![Flutter](https://img.shields.io/badge/Flutter-3.24.0%2B-blue.svg)](https://flutter.dev)

Flutter 权限管理工具包，用于统一管理应用权限请求逻辑。
提供单例模式，支持自定义权限提示样式，自动处理权限的各种状态。

---

## 功能特性

* 采用单例模式设计，全局统一管理权限请求
* 自动处理权限多种状态（已授予、被拒绝、永久拒绝等）
* 支持自定义权限说明提示样式（对话框、Toast等）
* 当权限被永久拒绝时，自动引导用户前往系统设置
* 日志统一加 `[ZPermission]` 前缀，便于调试和追踪
* 支持 Android 和 iOS 平台

---

## 安装

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  z_permission_handler: ^0.0.4
```

然后执行：

```bash
flutter pub get
```

---

## 使用示例

### 1. 初始化

首先需要在应用启动时初始化权限处理器，并定义权限提示的显示和关闭逻辑：

```dart
import 'package:z_permission_handler/z_permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 初始化权限处理器
    final permissionHandler = ZPermissionHandler();
    
    // 定义权限提示的显示和关闭方法
    permissionHandler.init(
      show: (context, item) {
        // 自定义权限提示，例如使用对话框
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(item.title),
            content: Text(item.desc),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("确定"),
              ),
            ],
          ),
        );
      },
      close: (context, item) {
        // 关闭权限提示
        Navigator.of(context).pop();
      },
    );
    
    return MaterialApp(
      title: '权限管理示例',
      home: HomePage(),
    );
  }
}
```

### 2. 请求单个权限

```dart
Future<void> requestCameraPermission(BuildContext context) async {
  final permissionHandler = ZPermissionHandler();
  
  bool granted = await permissionHandler.checkAndRequestPermission(
    context,
    zPermissionHandlerItem: ZPermissionHandlerItem(
      title: "相机权限",
      desc: "需要访问相机以拍摄照片",
      permission: Permission.camera,
    ),
  );
  
  if (granted) {
    print("相机权限已获取 ✅");
    // 执行需要相机权限的操作
  } else {
    print("相机权限被拒绝 ❌");
    // 处理权限被拒绝的情况
  }
}
```

### 3. 批量请求权限

```dart
Future<void> requestMultiplePermissions(BuildContext context) async {
  final permissionHandler = ZPermissionHandler();
  
  List<ZPermissionHandlerItem> permissionItems = [
    ZPermissionHandlerItem(
      title: "相机权限",
      desc: "需要访问相机以拍摄照片",
      permission: Permission.camera,
    ),
    ZPermissionHandlerItem(
      title: "存储权限",
      desc: "需要访问存储以保存图片",
      permission: Permission.storage,
    ),
    ZPermissionHandlerItem(
      title: "麦克风权限",
      desc: "需要使用麦克风进行录音",
      permission: Permission.microphone,
    ),
  ];
  
  bool allGranted = await permissionHandler.checkAndRequestPermissions(
    context,
    items: permissionItems,
  );
  
  if (allGranted) {
    print("所有权限均已获取 ✅");
    // 执行需要权限的操作
  } else {
    print("部分或全部权限被拒绝 ❌");
    // 处理权限被拒绝的情况
  }
}
```

---

## 权限状态处理

该库会自动处理以下权限状态：

1. **已授予**：直接返回 `true`，不显示提示
2. **被拒绝**：显示权限提示，然后请求权限
3. **永久拒绝**：直接打开系统设置页面

---

## 支持平台

* ✅ Android
* ✅ iOS
* ✅ Web

---

## 注意事项

1. 必须在使用前调用 `init()` 方法，否则会抛出异常
2. 确保在 `AndroidManifest.xml` 和 `Info.plist` 中正确配置了所需的权限声明
3. 当权限被永久拒绝时，用户需要手动在系统设置中开启权限

---

## License

MIT License，详情见 [LICENSE](LICENSE)。
