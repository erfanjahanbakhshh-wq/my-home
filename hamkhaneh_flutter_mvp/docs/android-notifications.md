# Android local-notification platform setup

The source snapshot has no `android/` Gradle project. When generating it with `flutter create --platforms=android .`, merge the following into `android/app/src/main/AndroidManifest.xml` (do not replace Flutter's generated activity/application metadata blindly):

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />

<!-- Inside <application> -->
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
  <intent-filter>
    <action android:name="android.intent.action.BOOT_COMPLETED" />
    <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
    <action android:name="android.intent.action.QUICKBOOT_POWERON" />
  </intent-filter>
</receiver>
```

Use a current Android compile SDK supported by the installed Flutter/plugin versions; plugin v18 needs Android embedding v2. Android 13+ runtime notification permission is requested in Dart. The app treats Thursday and Friday as Iranian weekend days. Exact-alarm special access can be denied by the user/system; code falls back to inexact scheduling. Test alarm delivery, reboot restoration, permission-denied behavior, and device-specific power management on real devices. iOS runtime alert/badge/sound permission is also requested.
