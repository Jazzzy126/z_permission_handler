// 定义权限数据模型
import 'package:permission_handler/permission_handler.dart';

class ZPermissionItem {
  final String title;
  final String desc;
  final Permission permission;

  ZPermissionItem({
    required this.title,
    required this.desc,
    required this.permission,
  });
}