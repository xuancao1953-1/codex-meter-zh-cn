import Foundation

enum L10n {
    static let locale = Locale(identifier: "zh-Hans-CN")

    private static let chineseBundle: Bundle = {
        guard let path = Bundle.main.path(forResource: "zh-Hans", ofType: "lproj"),
              let bundle = Bundle(path: path) else { return .main }
        return bundle
    }()

    private static let shortTimeFormatter = makeFormatter("HH:mm")
    private static let dateTimeFormatter = makeFormatter("M月d日 HH:mm")
    private static let weekdayFormatter = makeFormatter("EEE")

    static func text(_ key: String, default value: String) -> String {
        chineseBundle.localizedString(forKey: key, value: value, table: nil)
    }

    static func format(_ key: String, default value: String, _ arguments: CVarArg...) -> String {
        String(format: text(key, default: value), locale: locale, arguments: arguments)
    }

    static func shortTime(_ date: Date) -> String {
        shortTimeFormatter.string(from: date)
    }

    static func dateTime(_ date: Date) -> String {
        dateTimeFormatter.string(from: date)
    }

    static func weekday(_ date: Date) -> String {
        weekdayFormatter.string(from: date)
    }

    static func relativeReset(_ date: Date?, now: Date = Date()) -> String {
        guard let date else {
            return text("reset.unavailable", default: "重置时间不可用")
        }

        let minutes = Int((date.timeIntervalSince(now) / 60).rounded(.up))
        guard minutes > 0 else {
            return text("reset.now", default: "现在重置")
        }
        if minutes < 60 {
            return L10n.format("reset.in.minutes", default: "将在 %d 分钟后重置", minutes)
        }

        let hours = Int((Double(minutes) / 60).rounded(.up))
        if hours < 24 {
            return L10n.format("reset.in.hours", default: "将在 %d 小时后重置", hours)
        }

        let days = Int((Double(hours) / 24).rounded(.up))
        return L10n.format("reset.in.days", default: "将在 %d 天后重置", days)
    }

    static let appName = text("app.name", default: "Codex Meter 中文版")
    static let codexUsage = text("accessibility.codex_usage", default: "Codex 用量")
    static let codexActivity = text("accessibility.codex_activity", default: "Codex 活动")
    static let codexUsageUnavailable = text("accessibility.codex_usage_unavailable", default: "Codex 用量不可用")
    static let sevenDayCodexActivity = text("accessibility.seven_day_codex_activity", default: "Codex 七日活动")
    static let menuRefresh = text("menu.refresh", default: "刷新")
    static let menuQuit = text("menu.quit", default: "退出 Codex Meter 中文版")
    static let quotaChecking = text("quota.checking", default: "正在检查 Codex 用量")
    static let quotaUnavailable = text("quota.unavailable", default: "用量暂不可用")
    static let refreshUsage = text("action.refresh_usage", default: "刷新用量")
    static let refreshCodexUsage = text("action.refresh_codex_usage", default: "刷新 Codex 用量")
    static let useAccount = text("account.use", default: "使用账户")
    static let addAccount = text("account.add", default: "添加账户…")
    static let deleteAccount = text("account.delete", default: "删除账户")
    static let switchCodexAccount = text("account.switch", default: "切换 Codex 账户")
    static let usageWindows = text("quota.windows", default: "用量周期")
    static let localActivity = text("activity.local", default: "本地活动")
    static let localActivityUnavailable = text("activity.unavailable", default: "本地活动不可用")
    static let usageDataUnavailable = text("quota.data_unavailable", default: "用量数据不可用。")
    static let bankedResets = text("quota.banked_resets", default: "已存重置次数")
    static let bankedResetsUnknown = text("quota.banked_resets_unknown", default: "OpenAI 未返回此账户的已存重置次数")
    static let bankedResetsAvailable = text("quota.banked_resets_available", default: "此账户当前可用的重置次数")
    static let settingsTitle = text("settings.title", default: "设置")
    static let settingsDetail = text("settings.detail", default: "显示、提醒与账户")
    static let activeAccount = text("account.active", default: "当前账户")
    static let addShort = text("action.add_short", default: "添加…")
    static let deleteShort = text("action.delete_short", default: "删除…")
    static let desktopSwitchSignIn = text("account.desktop_secure_sign_in", default: "桌面端切换使用 OpenAI 安全登录。")
    static let openCodexEllipsis = text("action.open_codex_ellipsis", default: "打开 Codex…")
    static let openCodex = text("action.open_codex", default: "打开 Codex")
    static let quit = text("action.quit", default: "退出")
    static let menuBar = text("settings.menu_bar", default: "菜单栏")
    static let menuBarDisplay = text("settings.menu_bar_display", default: "菜单栏显示")
    static let currency = text("settings.currency", default: "货币")
    static let lowUsageAlert = text("settings.low_usage_alert", default: "低用量提醒")
    static let fallbackPrice = text("settings.fallback_price", default: "未知模型的备用美元价格")
    static let priceInput = text("settings.price_input", default: "输入")
    static let priceCachedInput = text("settings.price_cached_input", default: "缓存输入")
    static let priceOutput = text("settings.price_output", default: "输出")
    static let fallbackPriceDetail = text("settings.fallback_price_detail", default: "仅在模型没有内置官方价格时使用。单位为每百万 token 的美元价格。")
    static let launchAtLogin = text("settings.launch_at_login", default: "登录时启动")
    static let lastUpdateStale = text("status.last_update_stale", default: "上次更新已过期")
    static let signedInThroughCodex = text("status.signed_in_through_codex", default: "已通过 Codex App 登录")
    static let sevenDaysLocalLogs = text("activity.seven_days_local_logs", default: "七日 · 读取自本地会话日志")
    static let tokens = text("unit.tokens", default: "token")
    static let chartDay = text("chart.day", default: "日期")
    static let chartTokens = text("chart.tokens", default: "Token")
    static let sevenDayLocalTokenActivity = text("accessibility.seven_day_local_token_activity", default: "七日本地 token 活动")
    static let apiPriceNote = text("activity.api_price_note", default: "API 价格核对日期：2026年7月15日 · 仅供估算")
    static let unpriced = text("activity.unpriced", default: "未定价")
    static let pricePerMillion = text("settings.price_per_million", default: "$/百万")
    static let nearlyExhausted = text("quota.nearly_exhausted", default: "即将耗尽")
    static let runningLow = text("quota.running_low", default: "剩余不多")
    static let tryAgain = text("action.try_again", default: "重试")
    static let defaultAccount = text("account.default", default: "默认账户")
    static let cancel = text("action.cancel", default: "取消")
    static let continueAction = text("action.continue", default: "继续")
    static let workAccount = text("account.work", default: "工作")
    static let switchMeter = text("account.switch_meter", default: "仅切换 Codex Meter")
    static let switchMeterAndCodex = text("account.switch_meter_and_codex", default: "切换 Codex Meter 与 Codex")
    static let meterOnly = text("account.meter_only", default: "仅切换 Codex Meter")
    static let deleteAccountAction = text("account.delete.action", default: "删除账户")
    static let accountRemoved = text("celebration.account_removed", default: "账户已移除")
    static let localCredentialsDeleted = text("celebration.local_credentials_deleted", default: "本地凭据已删除")
    static let accountReady = text("celebration.account_ready", default: "账户已就绪")
    static let secureSignInCompleted = text("celebration.secure_sign_in_completed", default: "安全登录已完成")
    static let tokenMilestone = text("celebration.token_milestone", default: "Token 里程碑")
    static let resetBanked = text("celebration.reset_banked", default: "已存入重置次数")
    static let signingCodexOut = text("account.signing_codex_out", default: "正在退出 Codex…")
    static let waitingSecureSignIn = text("account.waiting_secure_sign_in", default: "正在等待 OpenAI 安全登录…")
    static let codexAccountSwitched = text("celebration.codex_account_switched", default: "Codex 账户已切换")
    static let usageRunningLow = text("celebration.usage_running_low", default: "用量剩余不多")
    static let lowUsageNotificationTitle = text("notification.low.title", default: "Codex 用量偏低")
    static func estimatedSavings(_ currencyCode: String, _ amount: Int) -> String {
        format("status.estimated_savings", default: "预计节省：%@ %d。", currencyCode, amount)
    }

    static func tightestWindowRemaining(_ percent: Int, savings: String) -> String {
        format("status.tightest_window_remaining", default: "Codex：最紧张的用量周期剩余 %d%%。%@", percent, savings)
    }

    static func usageUnavailableDetail(_ detail: String) -> String {
        format("status.usage_unavailable_detail", default: "Codex 用量不可用：%@", detail)
    }

    static func staleUsage(_ time: String) -> String {
        format("status.stale_usage", default: "Codex 用量已过期。上次更新于 %@。", time)
    }

    static func currentAccountAccessibility(_ account: String) -> String {
        format("account.current_accessibility", default: "当前账户：%@。打开账户切换器", account)
    }

    static func tokenCount(_ count: String) -> String {
        format("unit.token_count", default: "%@ token", count)
    }

    static func planName(_ rawValue: String) -> String {
        switch rawValue.lowercased() {
        case "plus": return text("plan.plus", default: "Plus 套餐")
        case "pro": return text("plan.pro", default: "Pro 套餐")
        case "team": return text("plan.team", default: "团队套餐")
        case "business": return text("plan.business", default: "商业套餐")
        case "enterprise": return text("plan.enterprise", default: "企业套餐")
        case "edu": return text("plan.edu", default: "教育套餐")
        case "free": return text("plan.free", default: "免费套餐")
        default:
            return format("plan.unknown", default: "其他套餐（%@）", rawValue)
        }
    }

    static func compactTokens(_ value: Int64) -> String {
        if value >= 1_000_000_000 {
            return String(format: "%.1f", locale: locale, Double(value) / 1_000_000_000) + "B"
        }
        if value >= 1_000_000 {
            return String(format: "%.1f", locale: locale, Double(value) / 1_000_000) + "M"
        }
        if value >= 1_000 {
            return String(format: "%.1f", locale: locale, Double(value) / 1_000) + "K"
        }
        return String(value)
    }

    static func currencyAmount(_ amount: Double, symbol: String) -> String {
        symbol + String(format: "%.2f", locale: locale, amount)
    }

    static func updated(_ time: String, plan: String?) -> String {
        guard let plan else {
            return format("status.updated", default: "更新于 %@", time)
        }
        return format("status.updated_with_plan", default: "更新于 %@ · %@", time, plan)
    }

    static func todayTokens(_ count: String) -> String {
        format("activity.today_tokens", default: "今天 %@", count)
    }

    static func apiEquivalent(_ amount: String) -> String {
        format("activity.api_equivalent", default: "API 等值费用 ≈ %@", amount)
    }

    static func estimatedSavingsVersusSol(_ amount: String) -> String {
        format("activity.savings_versus_sol", default: "相较 GPT-5.6 Sol 预计节省：%@", amount)
    }

    static func dailyTokenAccessibility(weekday: String, tokens: Int64) -> String {
        format("accessibility.daily_tokens", default: "%@：%lld token", weekday, tokens)
    }

    static func remainingPercent(_ percent: Int) -> String {
        format("accessibility.remaining_percent", default: "剩余 %d%%", percent)
    }

    static func percentage(_ percent: Int) -> String {
        format("format.percentage", default: "%d%%", percent)
    }

    static func percentageWithSavings(_ percent: Int, currencyCode: String, amount: Int) -> String {
        format("format.percentage_with_savings", default: "%d%% · %@%d", percent, currencyCode, amount)
    }

    static func remainingWithResetAccessibility(_ percent: Int, reset: String) -> String {
        format("accessibility.remaining_with_reset", default: "剩余 %d%%。%@", percent, reset)
    }

    static func usageWindowName(durationMinutes: Int?) -> String {
        guard let durationMinutes else {
            return text("quota.window", default: "用量周期")
        }
        if durationMinutes <= 360 {
            return text("quota.window.five_hour", default: "5 小时限额")
        }
        if durationMinutes >= 9_000 {
            return text("quota.window.weekly", default: "每周限额")
        }
        if durationMinutes >= 1_200 {
            return text("quota.window.daily", default: "每日限额")
        }
        return format("quota.window.hours", default: "%d 小时限额", durationMinutes / 60)
    }

    static func activityScanFailed(_ detail: String) -> String {
        format("error.activity_scan_failed", default: "读取本地活动失败：%@", detail)
    }

    static func usageRefreshFailed(_ detail: String) -> String {
        format("error.usage_refresh_failed", default: "刷新 Codex 用量失败：%@", detail)
    }

    static let noRateLimitWindows = text("error.no_rate_limit_windows", default: "此账户没有返回 Codex 用量周期。")
    static func launchAtLoginFailed(_ detail: String) -> String {
        format("error.launch_at_login_failed", default: "无法更改登录时启动设置：%@", detail)
    }

    static let codexNotInstalled = text("error.codex_not_installed", default: "未在 /Applications 中找到 Codex。")
    static func openCodexFailed(_ detail: String) -> String {
        format("error.open_codex_failed", default: "无法打开 Codex：%@", detail)
    }

    static func switchToAccount(_ account: String) -> String {
        format("account.switch.title", default: "切换到 %@？", account)
    }

    static let switchDesktopProfileInfo = text("account.switch.desktop_info", default: "这是 Codex 桌面端配置。Codex Meter 将切换用量视图，显示桌面端当前登录账户。")
    static let switchPrivateProfileInfo = text("account.switch.private_info", default: "请选择仅切换 Codex Meter，或同时退出 Codex 桌面端并通过 OpenAI 安全浏览器登录此账户。")
    static let addAccountTitle = text("account.add.title", default: "添加 Codex 账户")
    static let addAccountInfo = text("account.add.info", default: "请设置标签。Codex Meter 将打开 OpenAI 安全浏览器登录，为此 Mac 创建独立配置。密码和验证码只会留在 OpenAI 页面。")
    static func createAccountFailed(_ detail: String) -> String {
        format("error.create_account_failed", default: "无法创建账户配置：%@", detail)
    }

    static func deleteAccountTitle(_ name: String) -> String {
        format("account.delete.title", default: "删除 %@？", name)
    }

    static let deleteAccountInfo = text("account.delete.info", default: "这会从此 Mac 移除本地保存的 Codex 凭据和用量配置，但不会删除 OpenAI 账户。")
    static func deleteLocalAccountFailed(_ detail: String) -> String {
        format("error.delete_local_account_failed", default: "无法删除本地账户：%@", detail)
    }

    static func startCodexLoginFailed(_ detail: String) -> String {
        format("error.start_codex_login_failed", default: "无法启动 Codex 登录：%@", detail)
    }

    static let signInIncomplete = text("error.sign_in_incomplete", default: "OpenAI 登录已取消或未完成。准备好后可以重新添加账户。")
    static func savingsMilestone(currencyCode: String, amount: Int) -> String {
        format("celebration.savings_milestone", default: "已节省 %@ %d", currencyCode, amount)
    }

    static let savingsVersusSol = text("celebration.savings_versus_sol", default: "相较 GPT-5.6 Sol 的预计节省")
    static func tokenMilestoneDetail(_ millions: Int) -> String {
        format("celebration.token_milestone_detail", default: "已使用 %dM 本地 token", millions)
    }

    static func resetBankedDetail(_ count: Int) -> String {
        format("celebration.reset_banked_detail", default: "此账户现有 %d 次可用", count)
    }

    static func checkingAccount(_ name: String) -> String {
        format("account.checking", default: "正在检查 %@…", name)
    }

    static let signInPageOpenFailed = text("error.sign_in_page_open_failed", default: "无法在浏览器中打开 OpenAI 登录页面。")
    static let signedInAccountMissing = text("error.signed_in_account_missing", default: "登录后 Codex 未返回已登录账户。")
    static func signedInAccountMismatch(actual: String, expected: String) -> String {
        format("error.signed_in_account_mismatch", default: "Codex 登录了 %@，而不是 %@。请重新登录并选择目标账户。", actual, expected)
    }

    static func switchAccountFailed(_ detail: String) -> String {
        format("error.switch_account_failed", default: "切换 Codex 账户失败：%@", detail)
    }

    static let closeCodexFailed = text("error.close_codex_failed", default: "退出登录前无法关闭 Codex。请退出 Codex 后重试。")
    static func tightestWindowLow(_ percent: Int) -> String {
        format("celebration.tightest_window_low", default: "最紧张的用量周期剩余 %d%%", percent)
    }

    static func lowUsageNotificationBody(_ percent: Int, reset: String) -> String {
        format("notification.low.body", default: "剩余 %d%%。%@", percent, reset)
    }

    static let resetNotificationUnavailable = text("reset.notification.unavailable", default: "重置时间不可用。")
    static func resetNotification(_ time: String) -> String {
        format("reset.notification.time", default: "重置时间：%@。", time)
    }

    static let displayIconAndPercentage = text("display.icon_and_percentage", default: "图标与百分比")
    static let displayPercentage = text("display.percentage", default: "仅百分比")
    static let displayIcon = text("display.icon", default: "仅图标")
    static let displayActivity = text("display.activity", default: "活动图表")

    private static func makeFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = locale
        formatter.dateFormat = format
        return formatter
    }
}
