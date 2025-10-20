import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:toastification/toastification.dart';

import '../z_permission_handler.dart';

/// 权限管理工具类
///
/// 用于统一管理 Flutter 应用中的权限请求逻辑，
/// 支持单个或多个权限的检查与请求。
///
/// 功能特性：
/// - 自动处理权限的多种状态（拒绝、永久拒绝、受限等）
/// - 自动弹出权限说明 Toast（通过 [ToastUtil] 实现）
/// - 日志统一加前缀 `[ZPermissionManager]` 便于过滤与追踪
class ZPermissionManager {
  static const String _logTag = "[ZPermissionManager]";

  /// 检查并请求单个权限。
  ///
  /// 参数：
  /// - [context]：当前的 [BuildContext]；
  /// - [permissionItem]：封装了权限、标题和描述信息的 [PermissionItem]。
  ///
  /// 返回：
  /// - `true`：权限已授权；
  /// - `false`：权限被拒绝或受限。
  ///
  /// 使用示例：
  /// ```dart
  /// bool cameraGranted = await ZPermissionManager.checkAndRequestPermission(
  ///   context,
  ///   permissionItem: PermissionItem(
  ///     title: "相机权限",
  ///     desc: "允许应用访问相机，用于拍摄照片",
  ///     permission: Permission.camera,
  ///   ),
  /// );
  ///
  /// if (cameraGranted) {
  ///   debugPrint("相机权限已获取 ✅");
  /// } else {
  ///   debugPrint("相机权限被拒绝 ❌");
  /// }
  /// ```
  static Future<bool> checkAndRequestPermission(
    BuildContext context, {
    required PermissionItem permissionItem,
  }) async {
    final permission = permissionItem.permission;
    final status = await permission.status;

    debugPrint("$_logTag 📋 检查权限: ${permission.toString()}");
    debugPrint("$_logTag 🔸 当前状态: $status");

    // 已授权
    if (status.isGranted) {
      debugPrint("$_logTag ✅ 权限已授权");
      return true;
    }

    // 被拒绝（但未永久拒绝）
    if (status.isDenied) {
      debugPrint("$_logTag ⚠️ 权限被拒绝，将显示说明 Toast 并请求权限...");

      final toast = _ToastUtil.showPermissionToast(
        context,
        title: permissionItem.title,
        desc: permissionItem.desc,
      );

      debugPrint("$_logTag 📤 发起系统权限请求...");
      final result = await permission.request();
      debugPrint("$_logTag 📥 权限请求结果: $result");

      _ToastUtil.dismiss(toast);
      debugPrint("$_logTag ✅ Toast 已关闭");

      if (result.isGranted) {
        debugPrint("$_logTag 🎉 权限请求成功");
        return true;
      } else {
        debugPrint("$_logTag ❌ 用户仍然拒绝权限");
        return false;
      }
    }

    // 永久拒绝
    if (status.isPermanentlyDenied) {
      debugPrint("$_logTag 🚫 权限被永久拒绝，将跳转到系统设置页...");
      openAppSettings();
      return false;
    }

    // iOS 受限状态
    if (status.isRestricted) {
      debugPrint("$_logTag 🔒 权限受限（iOS 特有）");
      return false;
    }

    // iOS/Android 权限有限制
    if (status.isLimited) {
      debugPrint("$_logTag ⚠️ 权限有限制（仅部分访问）");
      return false;
    }

    debugPrint("$_logTag ❓ 未知权限状态: $status");
    return false;
  }

  /// 检查并请求多个权限。
  ///
  /// 参数：
  /// - [context]：用于展示 Toast 的上下文；
  /// - [permissionItems]：包含多个 [PermissionItem] 的列表；
  ///
  /// 返回：
  /// - `Map<PermissionItem, bool>`：键为权限项，值为授权结果（true/false）。
  ///
  /// 使用示例：
  /// ```dart
  /// Map<PermissionItem, bool> permissions =
  ///     await ZPermissionManager.checkAndRequestPermissions(
  ///   context,
  ///   permissionItems: [
  ///     PermissionItem(
  ///       title: "相机权限",
  ///       desc: "允许应用访问相机，用于拍摄照片",
  ///       permission: Permission.camera,
  ///     ),
  ///     PermissionItem(
  ///       title: "录音权限",
  ///       desc: "允许应用使用麦克风进行录音或语音输入",
  ///       permission: Permission.microphone,
  ///     ),
  ///   ],
  /// );
  ///
  /// // 循环打印授权结果
  /// permissions.forEach((item, granted) {
  ///   debugPrint("[权限结果] ${item.title}: ${granted ? '✅ 已授权' : '❌ 拒绝'}");
  /// });
  /// ```
  static Future<Map<PermissionItem, bool>> checkAndRequestPermissions(
    BuildContext context, {
    required List<PermissionItem> permissionItems,
  }) async {
    final results = <PermissionItem, bool>{};

    for (final item in permissionItems) {
      debugPrint("$_logTag 🔍 正在检查权限: ${item.title}");
      results[item] = await checkAndRequestPermission(
        context,
        permissionItem: item,
      );
    }

    debugPrint("$_logTag ✅ 权限检查完成，结果如下：");
    results.forEach((item, granted) {
      debugPrint("$_logTag • ${item.title}: ${granted ? '✅ 已授权' : '❌ 拒绝'}");
    });

    return results;
  }
}

class _ToastUtil {
  /// 显示权限提示 Toast
  static ToastificationItem showPermissionToast(
    BuildContext context, {
    required String title,
    required String desc,
  }) {
    final theme = Theme.of(context);

    return toastification.show(
      context: context,
      icon: Icon(Icons.notifications_rounded),
      style: ToastificationStyle.flat,
      title: Text(title),
      description: Text(desc),
      dragToClose: false,
      closeOnClick: false,
      autoCloseDuration: null,
      animationDuration: Duration(milliseconds: 300),
      alignment: Alignment.topLeft,
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onSurface,
      primaryColor: theme.colorScheme.primary,
      animationBuilder: (context, animation, alignment, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      closeButton: const ToastCloseButton(showType: CloseButtonShowType.none),
    );
  }

  /// 通用关闭方法
  static void dismiss(ToastificationItem toast) {
    toastification.dismiss(toast);
  }
}
