import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// 通用权限回调类型
///
/// 用于所有权限回调，包括显示提示、关闭提示、普通拒绝和永久拒绝。
/// 回调是异步的，方便弹窗或其他异步操作。
typedef ZPermissionCallback = Future<void> Function(
  BuildContext context,
  ZPermissionHandlerItem item,
);

/// 单个权限项的数据类
///
/// 包含权限的标题、描述和实际的 [Permission] 对象。
class ZPermissionHandlerItem {
  /// 权限标题，用于显示给用户
  final String title;

  /// 权限描述，用于提示用户为什么需要该权限
  final String desc;

  /// 实际请求的权限对象
  final Permission permission;

  /// 构造方法
  ZPermissionHandlerItem({
    required this.title,
    required this.desc,
    required this.permission,
  });
}

/// 批量权限请求结果
///
/// 用于批量权限请求的返回值，包含是否全部授予以及被拒绝的权限项列表。
class ZPermissionBatchResult {
  /// 是否所有权限都被授予
  final bool allGranted;

  /// 被拒绝的权限项列表
  final List<ZPermissionHandlerItem> deniedItems;

  /// 构造方法
  ZPermissionBatchResult({
    required this.allGranted,
    required this.deniedItems,
  });
}

/// 权限管理器
///
/// 提供单例对象，用于全局管理权限请求、提示展示以及拒绝处理逻辑。
///
/// **使用示例**
/// ```dart
/// ZPermissionHandler().init(
///   onShow: (context, item) async {
///     // 弹窗显示权限提示
///   },
///   onClose: (context, item) async {
///     // 关闭弹窗
///   },
///   onDenied: (context, item) async {
///     // 普通拒绝处理
///   },
///   onPermanentlyDenied: (context, item) async {
///     // 永久拒绝处理
///   },
/// );
/// ```
class ZPermissionHandler {
  static final ZPermissionHandler _instance = ZPermissionHandler._internal();
  factory ZPermissionHandler() => _instance;
  ZPermissionHandler._internal();

  /// 权限提示显示回调（必填）
  late ZPermissionCallback _onShowFunc;

  /// 权限提示关闭回调（必填）
  late ZPermissionCallback _onCloseFunc;

  /// 普通权限拒绝回调（可选）
  ZPermissionCallback? _onDeniedFunc;

  /// 永久权限拒绝回调（可选）
  ZPermissionCallback? _onPermanentlyDeniedFunc;

  /// 初始化全局权限回调
  ///
  /// 必须在调用 `checkAndRequestPermission` 或 `checkAndRequestPermissions` 之前调用。
  ///
  /// 参数说明：
  /// - [onShow] 显示权限提示（必填）
  /// - [onClose] 关闭权限提示（必填）
  /// - [onDenied] 普通拒绝处理（可选）
  /// - [onPermanentlyDenied] 永久拒绝处理（可选）
  void init({
    required ZPermissionCallback onShow,
    required ZPermissionCallback onClose,
    ZPermissionCallback? onDenied,
    ZPermissionCallback? onPermanentlyDenied,
  }) {
    _onShowFunc = onShow;
    _onCloseFunc = onClose;
    _onDeniedFunc = onDenied;
    _onPermanentlyDeniedFunc = onPermanentlyDenied;
  }

  /// 请求单个权限
  ///
  /// 如果权限已授权，直接返回 `true`。
  /// 如果权限未授权，会调用 [_onShowFunc] 显示提示，完成后调用 [_onCloseFunc] 关闭提示。
  /// 如果权限被拒绝，会调用 [_onDeniedFunc] 或 [_onPermanentlyDeniedFunc]。
  ///
  /// 返回值：
  /// - `true` 表示权限已授予
  /// - `false` 表示权限未授予
  Future<bool> checkAndRequestPermission(
    BuildContext context, {
    required ZPermissionHandlerItem item,
  }) async {
    final permission = item.permission;
    final status = await permission.status;

    debugPrint("🍀 [ZPermission] 当前状态: $status");

    if (status.isGranted || status.isLimited) return true;

    if (status.isRestricted) {
      debugPrint("🚫 [ZPermission] restricted：权限无法申请");
      if (_onDeniedFunc != null) await _onDeniedFunc!(context, item);
      return false;
    }

    if (status.isPermanentlyDenied) {
      debugPrint("⚠️ [ZPermission] 权限永久拒绝");
      if (_onPermanentlyDeniedFunc != null) {
        await _onPermanentlyDeniedFunc!(context, item);
      }
      return false;
    }

    // 正常流程：显示提示 → 请求权限 → 关闭提示
    await _onShowFunc(context, item);
    final result = await permission.request();
    await _onCloseFunc(context, item);

    if (result.isGranted || result.isLimited) return true;

    if (_onDeniedFunc != null) await _onDeniedFunc!(context, item);
    return false;
  }

  /// 批量请求权限（逐个处理）
  ///
  /// 遍历 [items]，依次请求每个权限。
  ///
  /// 返回值：
  /// - [ZPermissionBatchResult]：
  ///   - [allGranted] 表示是否所有权限都已授予
  ///   - [deniedItems] 被拒绝的权限列表
  Future<ZPermissionBatchResult> checkAndRequestPermissions(
    BuildContext context, {
    required List<ZPermissionHandlerItem> items,
  }) async {
    final deniedItems = <ZPermissionHandlerItem>[];

    for (final item in items) {
      final granted = await checkAndRequestPermission(context, item: item);
      if (!granted) {
        deniedItems.add(item);
      }
    }

    return ZPermissionBatchResult(
      allGranted: deniedItems.isEmpty,
      deniedItems: deniedItems,
    );
  }
}
