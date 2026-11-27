# خونمون — اپ Flutter متصل به PocketBase

اپ مدیریت خانهٔ اشتراکی با رابط فارسی راست‌به‌چپ. این نسخه از PocketBase برای ورود، همگام‌سازی خانه، اعضا، کارها و فهرست خرید استفاده می‌کند.

## نیازمندی و اجرا

نیازمند Flutter stable (Dart 3.3 یا جدیدتر)، Android SDK و PocketBase در دسترس است:

```bash
flutter pub get
flutter analyze
flutter run
```

ساخت APK آزمایشی:

```bash
flutter build apk --debug
```

پروژهٔ فعلی فاقد پوشهٔ پلتفرم Android است؛ در صورت نیاز می‌توان آن را در ریشهٔ پروژه ایجاد کرد (`flutter create --platforms=android .`). در محیط این مهاجرت Flutter/Dart نصب نبود و ساخت محلی اجرا/تأیید نشده است.

## هویت بصری و آیکون برنامه

رابط فارسی با لوگوی خانه در صفحهٔ ورود و نوار بالای برنامه، کارت خوشامدگویی سبز-فیروزه‌ای، کارت‌های روشن، رنگ‌های گرم نارنجی/مرجانی و حالت‌های خالی دوستانه به‌روزرسانی شده است. فایل لوگو در `assets/branding/hamkhaneh_logo.png` قرار دارد و در `pubspec.yaml` ثبت شده است. عنوان برنامه در Flutter برابر «خونمون» است.

این پروژه در حال حاضر پوشهٔ `android/` و `AndroidManifest.xml` ندارد؛ بنابراین برچسب Manifest و منابع نهایی launcher icon در این نسخه ساخته نشدند. پس از ساخت پلتفرم Android با `flutter create --platforms=android .`، با اجرای `dart run flutter_launcher_icons` آیکون‌ها از همان لوگوی PNG تولید می‌شوند (تنظیم Android و پس‌زمینهٔ تطبیقی در pubspec ثبت شده است).

GitHub Actions همان workflow قبلی را اجرا می‌کند: `flutter pub get` و `flutter analyze`. این تغییرات در این محیط build یا analyze نشده‌اند، چون Flutter/Dart نصب نیست؛ CI نیز در workflow کنونی APK نمی‌سازد.

## تنظیم PocketBase

آدرس پیش‌فرض در `lib/config/app_config.dart` برابر `https://pocketbase-iy9qam.chbkn.dev` است. در PocketBase، collection احراز هویت `users` با فیلدهای `name` و `avatar` و این collectionهای پایه را ایجاد کنید:

- `houses`: `name` (text)، `invite_code` (text)، `owner` (single relation به `users`)، `members` (multiple relation به `users`)
- `tasks`: `house` (single relation به `houses`)، `title` (text)، `due_date` (date)، `is_completed` (bool)، `is_weekend` (bool)، `assigned_to` (relation به `users`، در صورت nullable بودن اختیاری)
- `shopping_items`: `house` (single relation به `houses`)، `name` (text)، `quantity` (text)، `category` (text)، `is_bought` (bool)، `month_key` (text)

برنامه هنگام ایجاد خانه مالک را در `owner` و عضو نخست را در `members` قرار می‌دهد. فهرست خانه‌های قابل‌دسترسی با دریافت رکوردها و بررسی رابطه‌های مالک/اعضا سمت کلاینت انتخاب می‌شود تا به نحو فیلتر relation خاص PocketBase وابسته نباشد؛ قواعد API همچنان باید دسترسی رکوردها را سمت سرور محدود کنند. بارگیری task و shopping بر اساس `house` انجام می‌شود. relationها هم به صورت شناسه و هم رکورد expand‌شده خوانده می‌شوند.

### قواعد دسترسی و امنیت

برای راه‌اندازی فعلی ممکن است API rules مجموعه‌ها به کاربران احراز هویت‌شده دسترسی گسترده بدهند. این وضعیت فقط تسهیل‌کنندهٔ اتصال اولیه است، **برای استفادهٔ واقعی امن نیست**. قواعد `list/view/create/update/delete` را بر اساس مالک و عضویت خانه محدود کنید و آزمون کنید؛ به‌ویژه اجازهٔ ویرایش `houses.members` یا `invite_code` نباید به هر کاربر احراز هویت‌شده داده شود. هیچ API rule ساختگی در کد برنامه قرار داده نشده است. اعتبارسنجی و کنترل دسترسی باید در PocketBase/سرور انجام شود.

دعوت در این نسخه فقط از فیلد `houses.invite_code` استفاده می‌کند: تولید و پذیرش کد به دسترسی update/read مناسب روی رکورد خانه وابسته است. با rules امن مالک‌محور، پیوستن عضو باید با endpoint/hook سمت سرورِ کنترل‌شده پیاده‌سازی شود؛ client-side lookup یا به‌روزرسانی اعضا به تنهایی سازوکار امن دعوت نیست.

قیمت تخمینی/واقعی و یادداشت/اولویت task از UI قدیمی حذف شده‌اند، چون جزو schema تأییدشده نیستند. مبلغ هزینه از دادهٔ schema موجود قابل محاسبه نیست.

## ساختار

- `lib/main.dart`: رابط فارسی و صفحات برنامه
- `lib/state/household_store.dart`: PocketBase auth، بارگیری و mutation داده‌ها
- `lib/config/app_config.dart`: نشانی سرور و نام collectionها
- `supabase/schema.sql`: نام قدیمی مسیر برای حفظ سازگاری بسته؛ اکنون راهنمای schema و rules مربوط به PocketBase است، نه SQL اجرایی
- `.github/workflows/flutter.yml`: بررسی خودکار Flutter و ساخت debug APK


## فونت فارسی پلاک و یادآوری موعد

- فونت Plak در فایل‌های این مخزن/بسته موجود نبود و این محیط دسترسی اینترنتی نداشت؛ فایل فونت از منبع نامعتبر یا بدون مجوز کپی نشده است. تم برنامه روی خانوادهٔ `Plak` تنظیم شده، اما Flutter تا وقتی asset واقعی تعریف نشود از فونت جایگزین سیستم استفاده می‌کند. برای فعال‌سازی، فایل دارای مجوز `Plak-Regular.ttf` را در `assets/fonts/Plak-Regular.ttf` قرار دهید و بخش `fonts` کامنت‌شده در `pubspec.yaml` را فعال کنید. مجوز و انتساب/منبعی که فروشنده یا صاحب فونت مقرر کرده را کنار فایل نگه دارید. نام فایل باید با مسیر pubspec یکی باشد.
- یادآوری‌ها محلی و روی همان دستگاه‌اند، نه Push/اعلان سرور. برای task باز و دارای شناسه، یک اعلان برای ساعت ۹ صبح به‌وقت محلی، روز تقویمی قبل موعد، زمان‌بندی می‌شود. اگر task همان روز پس از ۹ صبح ساخته/به‌روزرسانی شود، اعلان یک دقیقه بعد می‌آید؛ موعدهای امروز/گذشته اعلان پیشاپیش ندارند. برای task انجام‌شده اعلان لغو می‌شود. بارگذاری مجدد taskها اعلان‌های مربوط به taskهای حذف‌شده از سمت سرور را پاک و موعدهای تغییرکرده را جایگزین می‌کند. در UI فعلی و schema روش حذف/ویرایش task تعریف نشده؛ اگر API حذف/ویرایش اضافه شد باید بلافاصله `TaskReminderService.instance.synchronize(tasks)` پس از mutation فراخوانی شود.
- برنامه درخواست مجوز اعلان و مجوز Exact Alarm را می‌دهد؛ در صورت رد Exact Alarm، زمان‌بندی به حالت inexact fallback می‌کند. Android پس از reboot نیازمند receiver و مجوزهای manifest است. این repository هیچ پوشهٔ `android/` یا `ios/` فعالی نداشت، بنابراین پیکربندی native باید هنگام تولید پلتفرم merge شود؛ نمونهٔ manifest در `docs/android-notifications.md` آمده است. در Android 13+ کاربر باید مجوز اعلان را تأیید کند. زمان دقیق تحت محدودیت‌های سیستم/Doze ممکن است تضمین نشود.
- تعریف `is_weekend` موجود در PocketBase حفظ شده است. در UI، «آخر هفته» به پنجشنبه/جمعهٔ تقویم ایرانی اشاره می‌کند؛ انتخاب این گزینه یا تاریخ، موعد را به نزدیک‌ترین پنجشنبه یا جمعهٔ پیشِ رو (همان روز اگر پنجشنبه/جمعه باشد) تنظیم می‌کند. تقویم هفتگی فقط جمعه را با نشان آخر هفته مشخص می‌کند؛ خود برنامه تاریخ را ذخیره می‌کند و به طور خودکار تکرار هفتگی نمی‌سازد.
- بررسی این بسته در این محیط فقط ایستا است؛ Flutter/Dart SDK نصب نیست، پس build/analyze اجرا نشده است.
## Android release setup

The repository includes a complete Android platform scaffold. The application ID is `org.example.hamkhaneh` because no existing Android package identifier was present in the source snapshot. The Android build enables core library desugaring for `flutter_local_notifications` and declares the required notification, exact-alarm, boot, and internet permissions.

