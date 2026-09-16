import Foundation

/// Equivalent of Android's `LanguageManager.kt` + the `strings.xml` /
/// `values-fa/strings.xml` / `values-ru/strings.xml` resource sets.
/// Provides an in-app runtime language switch (independent of the device's
/// system language), matching the Android app's behaviour.
enum L {
    struct LangOption: Identifiable {
        let code: String
        let displayName: String
        let emoji: String
        var id: String { code }
    }

    static let supportedLanguages: [LangOption] = [
        LangOption(code: "fa", displayName: "فارسی", emoji: "❤️"),
        LangOption(code: "en", displayName: "English", emoji: "🇺🇸"),
        LangOption(code: "ru", displayName: "Русский", emoji: "🇷🇺")
    ]

    static func isRTL(_ code: String?) -> Bool {
        code == "fa"
    }

    private static let strings: [String: [String: String]] = [
        "app_name": ["en": "Iwana Proxy", "fa": "Iwana Proxy", "ru": "Iwana Proxy"],
        "disclaimer": [
            "en": "All proxies are created by third parties and we only collect them ✅",
            "fa": "تمام پروکسی‌ها توسط اشخاص ثالث ایجاد شده‌اند و ما فقط آن‌ها را جمع‌آوری می‌کنیم ✅",
            "ru": "Все прокси созданы третьими лицами, мы только собираем их ✅"
        ],
        "offline_notice": [
            "en": "⚠️ These proxies were fetched previously and connection to the server failed.",
            "fa": "⚠️ این پروکسی‌ها از قبل دریافت شده و اتصال به سرور ناموفق بود.",
            "ru": "⚠️ Эти прокси получены ранее, подключение к серверу не удалось."
        ],
        "telegram_not_installed": ["en": "Telegram is not installed.", "fa": "تلگرام نصب نشده است.", "ru": "Telegram не установлен."],
        "scan_proxies_caps": ["en": "SCAN PROXIES", "fa": "اسکن پروکسی‌ها", "ru": "СКАНИРОВАТЬ ПРОКСИ"],
        "retry": ["en": "Retry", "fa": "تلاش مجدد", "ru": "Повторить"],
        "online_status": ["en": "Online", "fa": "متصل", "ru": "Онлайн"],
        "no_proxies_found": ["en": "No working proxies found.", "fa": "پروکسی فعالی یافت نشد.", "ru": "Рабочих прокси не найдено."],
        "connect": ["en": "Connect", "fa": "اتصال", "ru": "Подключиться"],
        "copy": ["en": "Copy", "fa": "کپی", "ru": "Копировать"],
        "copied": ["en": "Copied to clipboard!", "fa": "در کلیپ‌بورد کپی شد!", "ru": "Скопировано в буфер!"],
        "search_placeholder": ["en": "Search server or port...", "fa": "جستجوی سرور یا پورت...", "ru": "Поиск сервера или порта..."],
        "system_ready_with_count": ["en": "CONNECTED PROXIES (%d)", "fa": "پروکسی‌های متصل (%d)", "ru": "ПОДКЛЮЧЕННЫЕ ПРОКСИ (%d)"],
        "settings": ["en": "Settings", "fa": "تنظیمات", "ru": "Настройки"],
        "language": ["en": "Language", "fa": "زبان", "ru": "Язык"],
        "first_launch_title": ["en": "Choose Language", "fa": "انتخاب زبان", "ru": "Выберите язык"],
        "select_lang_desc": ["en": "Select your preferred language", "fa": "زبان مورد نظر خود را انتخاب کنید", "ru": "Выберите предпочитаемый язык"],
        "auto_scan_settings_title": ["en": "Auto Scan Settings", "fa": "تنظیمات اسکن خودکار", "ru": "Автосканирование"],
        "auto_scan_enable_toggle": ["en": "Enable Auto Scan", "fa": "فعال‌سازی اسکن خودکار", "ru": "Включить автосканирование"],
        "auto_scan_interval_text": ["en": "Scan Interval: %d seconds", "fa": "فاصله اسکن: %d ثانیه", "ru": "Интервал: %d сек."],
        "saved_proxies": ["en": "Saved Proxies", "fa": "پروکسی‌های ذخیره‌شده", "ru": "Сохранённые прокси"],
        "no_saved_proxies": ["en": "No saved proxies yet.", "fa": "هیچ پروکسی ذخیره‌شده‌ای وجود ندارد.", "ru": "Нет сохранённых прокси."],
        "saved_toast": ["en": "Saved to list", "fa": "در ذخیره‌ها قرار گرفت", "ru": "Сохранено в список"],
        "removed_toast": ["en": "Removed from saved", "fa": "از ذخیره‌ها حذف شد", "ru": "Удалено из сохранённых"],
        "save": ["en": "Save", "fa": "ذخیره", "ru": "Сохранить"],
        "proxy_speed_test": ["en": "Proxy Speed Test", "fa": "تست سرعت پروکسی", "ru": "Тест скорости прокси"],
        "proxy_input_hint": ["en": "Paste tg:// link or server:port:secret", "fa": "لینک tg:// یا server:port:secret را وارد کنید", "ru": "Вставьте ссылку tg:// или server:port:secret"],
        "paste_clipboard": ["en": "Paste", "fa": "جای‌گذاری", "ru": "Вставить"],
        "start_test": ["en": "Start Speed Test", "fa": "شروع تست سرعت", "ru": "Начать тест"],
        "testing": ["en": "Testing…", "fa": "در حال تست…", "ru": "Тестирование…"],
        "avg_ping": ["en": "Avg Ping", "fa": "میانگین پینگ", "ru": "Средний пинг"],
        "jitter_label": ["en": "Jitter", "fa": "نوسان (جیتر)", "ru": "Джиттер"],
        "packet_loss_label": ["en": "Packet Loss", "fa": "پکت لاس", "ru": "Потеря пакетов"],
        "connection_quality": ["en": "Quality", "fa": "کیفیت اتصال", "ru": "Качество"],
        "quality_excellent": ["en": "Excellent", "fa": "فوق‌العاده", "ru": "Отлично"],
        "quality_good": ["en": "Good", "fa": "خوب", "ru": "Хорошо"],
        "quality_fair": ["en": "Fair", "fa": "متوسط", "ru": "Средне"],
        "quality_poor": ["en": "Poor", "fa": "ضعیف", "ru": "Слабо"],
        "quality_offline": ["en": "Offline", "fa": "غیرقابل اتصال", "ru": "Недоступен"],
        "invalid_proxy_format": ["en": "Please enter a valid proxy address or Telegram proxy link.", "fa": "لطفاً یک لینک یا آدرس پروکسی معتبر وارد کنید.", "ru": "Пожалуйста, введите корректный адрес или ссылку прокси."],
        "download_speed": ["en": "Download Speed", "fa": "سرعت دانلود", "ru": "Скорость загрузки"],
        "upload_speed": ["en": "Upload Speed", "fa": "سرعت آپلود", "ru": "Скорость отдачи"],
        "stability_label": ["en": "Stability", "fa": "پایداری", "ru": "Стабильность"],
        "banner_slider_setting": ["en": "Banner Slider", "fa": "اسلایدر برنامه", "ru": "Слайдер приложения"],
        "estimated_badge": ["en": "Estimated", "fa": "تخمینی", "ru": "Примерно"],
        "telegram_speed_disclaimer": ["en": "This value is an estimate based on network conditions and is not guaranteed by Telegram.", "fa": "این مقدار تخمینی است و سرعت تضمین‌شده Telegram نیست.", "ru": "Это расчетное значение, скорость Telegram не гарантируется."],
        "real_telegram_download_speed": ["en": "Real Telegram Download Speed", "fa": "سرعت واقعی دانلود در تلگرام", "ru": "Реальная скорость загрузки в Telegram"],
        "file_download_estimator": ["en": "Download Time Estimator", "fa": "محاسبه زمان دانلود فایل", "ru": "Расчет времени скачивания"],
        "file_size_mb_hint": ["en": "File size (e.g. 74.6 MB)", "fa": "حجم فایل به مگابایت (مثلاً 74.6)", "ru": "Размер файла в МБ (напр. 74.6)"],
        "estimated_time_result": ["en": "Estimated Time", "fa": "زمان تخمینی دانلود", "ru": "Примерное время"],
        "offline_failed_status": ["en": "OFFLINE", "fa": "قطع", "ru": "ОФЛАЙН"],
        "scanning_status": ["en": "SCANNING", "fa": "در حال اسکن", "ru": "СКАНИРОВАНИЕ"],
        "testing_status": ["en": "TESTING", "fa": "در حال بررسی", "ru": "ПРОВЕРКА"],
        "for_download_badge": ["en": "FOR DOWNLOAD", "fa": "دانلودی", "ru": "ДЛЯ СКАЧИВАНИЯ"],
        "russian_badge": ["en": "RUSSIAN", "fa": "روسی", "ru": "РОССИЯ"],
        "back": ["en": "Back", "fa": "بازگشت", "ru": "Назад"]
    ]

    static func t(_ key: String, lang: String?) -> String {
        let code = lang ?? "en"
        return strings[key]?[code] ?? strings[key]?["en"] ?? key
    }
}
