import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:get/get.dart';
import 'package:graba2z/Widgets/secondarybutton.dart';
import 'package:graba2z/Services/notification_permission_preloader.dart';
import 'package:graba2z/Services/push_notification_service.dart';
import '../../../../../../Utils/packages.dart';

class NotificationTile extends StatefulWidget {
  const NotificationTile({super.key, this.initialValue});
  final bool? initialValue;

  @override
  NotificationTileState createState() => NotificationTileState();
}

class NotificationTileState extends State<NotificationTile> with WidgetsBindingObserver {
  bool isNotificationEnabled = false;
  bool _initDone = false;
  static const String _prefKey = 'notification_enabled';
  
  // Add timestamp to track when app was paused
  DateTime? _lastPausedTime;
  static const Duration _resyncThreshold = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.initialValue != null) {
      isNotificationEnabled = widget.initialValue!;
      _initDone = true;
    } else if (NotificationPermissionPreloader.hasValue) {
      isNotificationEnabled = NotificationPermissionPreloader.effectiveOrFalse;
      _initDone = true;
    }

    if (!_initDone) {
      _initNotificationToggle();
    }
  }

  Future<void> _initNotificationToggle() async {
    final osAllowed = await AwesomeNotifications().isNotificationAllowed();
    final prefs = await SharedPreferences.getInstance();
    final bool userPref = prefs.getBool(_prefKey) ?? osAllowed;

    if (!mounted) return;
    setState(() {
      isNotificationEnabled = userPref && osAllowed;
      _initDone = true;
    });

    if (!prefs.containsKey(_prefKey)) {
      await prefs.setBool(_prefKey, userPref);
    }
    await NotificationPermissionPreloader.updateEffective(isNotificationEnabled);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Track when app goes to background
      _lastPausedTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      // Only resync if app was in background for significant time
      if (_lastPausedTime != null) {
        final pauseDuration = DateTime.now().difference(_lastPausedTime!);
        if (pauseDuration > _resyncThreshold) {
          _resyncFromSystem();
        }
      }
    }
  }

  Future<void> _resyncFromSystem() async {
    final prefs = await SharedPreferences.getInstance();
    final userPref = prefs.getBool(_prefKey) ?? false;
    final osAllowed = await AwesomeNotifications().isNotificationAllowed();
    
    if (!mounted) return;
    
    // Only update if there's an actual change
    final effective = userPref && osAllowed;
    if (effective != isNotificationEnabled) {
      setState(() {
        isNotificationEnabled = effective;
        _initDone = true;
      });
      await NotificationPermissionPreloader.updateEffective(effective);
    }
  }

  Future<void> _toggleNotification(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    if (value) {
      final alreadyAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!alreadyAllowed) {
        await AwesomeNotifications().requestPermissionToSendNotifications();
      }
      final nowAllowed = await AwesomeNotifications().isNotificationAllowed();
      await prefs.setBool(_prefKey, nowAllowed);
      if (!mounted) return;
      setState(() {
        isNotificationEnabled = nowAllowed;
        _initDone = true;
      });
      await NotificationPermissionPreloader.updateEffective(isNotificationEnabled);
      if (nowAllowed) {
        // FCM: re-attach this install now that notifications are allowed
        try {
          await PushNotificationService.instance.registerDevice();
        } catch (_) {}
      }
      _showNotificationDialog(
        nowAllowed ? 'settings_notif_enabled_title'.tr : 'settings_notif_perm_title'.tr,
        nowAllowed
            ? 'settings_notif_enabled_body'.tr
            : 'settings_notif_perm_body'.tr,
      );
    } else {
      await prefs.setBool(_prefKey, false);
      try {
        await AwesomeNotifications().cancelAll();
        await AwesomeNotifications().cancelAllSchedules();
      } catch (_) {}
      // FCM: stop pushes to this install when the customer opts out
      try {
        await PushNotificationService.instance.deregisterDevice();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        isNotificationEnabled = false;
        _initDone = true;
      });
      await NotificationPermissionPreloader.updateEffective(false);
      _showNotificationDialog(
        'settings_notif_disabled_title'.tr,
        'settings_notif_disabled_body'.tr,
      );
    }
  }

  void _showNotificationDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: kSecondaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              color: kSecondaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            SecondaryButton(
              onPressFunction: () => Navigator.of(context).pop(),
              buttonText: 'ok'.tr,
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      minLeadingWidth: 0,
      leading: Image.asset(
        "assets/icons/notification.png",
        color: kSecondaryColor,
        width: 20,
        height: 20,
      ),
      title: Text(
        'settings_notification'.tr,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      trailing: SizedBox(
        width: 36,
        height: 20,
        child: Transform.scale(
          scale: 0.8,
          child: Switch(
            padding: EdgeInsets.zero,
            value: _initDone ? isNotificationEnabled : false,
            onChanged: _toggleNotification,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
