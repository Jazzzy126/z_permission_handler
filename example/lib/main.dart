import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:z_permission_handler/z_permission_handler.dart';

void main() {
  ZPermissionHandler().init(
    onShow: (context, item) async {
      debugPrint("[ZPermission] 显示权限提示: ${item.permission}");
      _ToastUtil.showPermissionToast(
        context,
        title: item.title,
        desc: item.desc,
      );
    },
    onClose: (context, item) async {
      _ToastUtil.dismiss();
      debugPrint("[ZPermission] 关闭权限提示: ${item.permission}");
    },
    onDenied: (context, item) async {
      debugPrint("[ZPermission] 权限被拒绝: ${item.permission}");
    },
    onPermanentlyDenied: (context, item) async {
      debugPrint("[ZPermission] 权限永久拒绝: ${item.permission}");
    },
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void _requestPermission() {
    ZPermissionHandler().checkAndRequestPermission(
      context,
      item: ZPermissionHandlerItem(title: "相机权限", desc: "需要相机权限来拍照", permission: Permission.camera),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(child: const Text('请求相机权限')),
      floatingActionButton: FloatingActionButton(
        onPressed: _requestPermission,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ToastUtil {
  // 当前显示的 Toast
  static ToastificationItem? _currentToast;

  /// 显示权限提示 Toast
  static ToastificationItem showPermissionToast(
    BuildContext context, {
    required String title,
    required String desc,
  }) {
    final theme = Theme.of(context);

    // 如果已有 Toast，先关闭
    if (_currentToast != null) {
      toastification.dismiss(_currentToast!);
      _currentToast = null;
    }

    _currentToast = toastification.show(
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

    return _currentToast!;
  }

  /// 通用关闭方法
  static void dismiss() {
    if (_currentToast != null) {
      toastification.dismiss(_currentToast!);
      _currentToast = null;
    }
  }
}
