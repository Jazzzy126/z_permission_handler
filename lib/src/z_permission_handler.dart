import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// 权限项数据类
///
/// 包含权限的标题、描述和实际的 [Permission] 对象
///
/// 使用示例:
/// ```dart
/// final item = ZPermissionHandlerItem(
///   title: "相机权限",
///   desc: "需要访问相机以拍照",
///   permission: Permission.camera,
/// );
/// ```
class ZPermissionHandlerItem {
  /// 权限标题，用于显示给用户
  final String title;

  /// 权限描述，用于提示用户为什么需要该权限
  final String desc;

  /// 实际请求的权限
  final Permission permission;

  /// 构造方法
  ZPermissionHandlerItem({
    required this.title,
    required this.desc,
    required this.permission,
  });
}

/// 权限管理工具类
///
/// 提供单例对象，用于全局管理权限请求、提示展示以及关闭逻辑
///
/// 使用示例:
/// ```dart
/// final permissionHandler = ZPermissionHandler();
///
/// // 初始化全局显示/关闭函数
/// permissionHandler.init(
///   show: (context, item) {
///     showDialog(
///       context: context,
///       builder: (_) => AlertDialog(
///         title: Text(item.title),
///         content: Text(item.desc),
///         actions: [
///           TextButton(
///             onPressed: () => Navigator.of(context).pop(),
///             child: Text("确定"),
///           ),
///         ],
///       ),
///     );
///   },
///   close: (context, item) {
///     Navigator.of(context).pop();
///   },
/// );
///
/// // 请求单个权限
/// bool granted = await permissionHandler.checkAndRequestPermission(
///   context,
///   zPermissionHandlerItem: ZPermissionHandlerItem(
///     title: "相机权限",
///     desc: "需要访问相机以拍照",
///     permission: Permission.camera,
///   ),
/// );
///
/// // 批量请求权限
/// bool allGranted = await permissionHandler.checkAndRequestPermissions(
///   context,
///   items: [
///     ZPermissionHandlerItem(
///       title: "存储权限",
///       desc: "需要访问存储以保存文件",
///       permission: Permission.storage,
///     ),
///     ZPermissionHandlerItem(
///       title: "相机权限",
///       desc: "需要访问相机以拍照",
///       permission: Permission.camera,
///     ),
///   ],
/// );
/// ```
class ZPermissionHandler {
  /// 单例对象
  static final ZPermissionHandler _instance = ZPermissionHandler._internal();

  /// 工厂构造方法
  factory ZPermissionHandler() => _instance;

  /// 私有构造方法
  ZPermissionHandler._internal();

  /// 全局显示权限提示函数
  void Function(BuildContext context, ZPermissionHandlerItem item)? _showFunc;

  /// 全局关闭权限提示函数
  void Function(BuildContext context, ZPermissionHandlerItem item)? _closeFunc;

  /// 初始化全局显示/关闭函数
  ///
  /// 需要在应用启动时调用，否则调用权限请求方法会抛出异常
  void init({
    required void Function(BuildContext context, ZPermissionHandlerItem item)
    show,
    required void Function(BuildContext context, ZPermissionHandlerItem item)
    close,
  }) {
    debugPrint("[ZPermission] 初始化全局 show/close 函数");
    _showFunc = show;
    _closeFunc = close;
  }

  /// 检查并请求单个权限
  ///
  /// 如果权限未授予，会调用 [_showFunc] 显示提示，完成后调用 [_closeFunc] 关闭提示。
  ///
  /// 如果权限永久拒绝，会直接打开系统设置。
  ///
  /// 返回 `true` 表示权限已授予，`false` 表示未授予。
  Future<bool> checkAndRequestPermission(
    BuildContext context, {
    required ZPermissionHandlerItem zPermissionHandlerItem,
  }) async {
    if (_showFunc == null || _closeFunc == null) {
      throw Exception("[ZPermission] 未初始化，请先调用 ZPermission.init()");
    }

    final permission = zPermissionHandlerItem.permission;
    final status = await permission.status;
    debugPrint("[ZPermission] 权限状态: $status");

    if (status.isGranted) {
      debugPrint("[ZPermission] 权限已授权: ${zPermissionHandlerItem.permission}");
      return true;
    }

    if (status.isDenied) {
      debugPrint(
        "[ZPermission] 权限未授权，显示提示: ${zPermissionHandlerItem.permission}",
      );
      _showFunc!(context, zPermissionHandlerItem);

      final result = await permission.request();
      debugPrint("[ZPermission] 请求权限结果: $result");

      _closeFunc!(context, zPermissionHandlerItem);
      debugPrint("[ZPermission] 关闭权限提示: ${zPermissionHandlerItem.permission}");

      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      debugPrint(
        "[ZPermission] 权限被永久拒绝，打开设置: ${zPermissionHandlerItem.permission}",
      );
      openAppSettings();
      return false;
    }

    debugPrint("[ZPermission] 未处理的权限状态: $status");
    return false;
  }

  /// 批量检查并请求权限
  ///
  /// 遍历 [items]，依次请求每个权限，如果有任何权限未授予，则返回 `false`。
  Future<bool> checkAndRequestPermissions(
    BuildContext context, {
    required List<ZPermissionHandlerItem> items,
  }) async {
    for (final item in items) {
      final granted = await checkAndRequestPermission(
        context,
        zPermissionHandlerItem: item,
      );
      if (!granted) return false;
    }
    return true;
  }
}
