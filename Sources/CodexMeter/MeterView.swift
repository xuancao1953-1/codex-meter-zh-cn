import Charts
import CodexMeterCore
import SwiftUI

struct MeterView: View {
    @ObservedObject var store: UsageStore
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("usageWindowsExpanded") private var usageWindowsExpanded = true
    @AppStorage("localActivityExpanded") private var localActivityExpanded = true
    @AppStorage("settingsExpanded") private var settingsExpanded = false

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                header
                Divider()
                content
                Divider()
                settings
            }
            if let celebration = store.celebration {
                CelebrationBanner(celebration: celebration)
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(2)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: store.celebration)
        .frame(width: 348)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.42), lineWidth: 0.75)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(colorScheme == .dark ? 0.28 : 0.14))
                Image(systemName: "gauge.with.dots.needle.50percent")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.appName)
                    .font(.system(size: 15, weight: .semibold))
                Text(headerSubtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            accountMenu
            Button {
                Task {
                    await store.refresh()
                    await store.refreshActivity()
                }
            } label: {
                if store.isRefreshing {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .rotationEffect(.degrees(store.isRefreshing ? 360 : 0))
                        .animation(.linear(duration: 0.8).repeatForever(autoreverses: false), value: store.isRefreshing)
                }
            }
            .buttonStyle(.plain)
            .help(L10n.refreshUsage)
            .disabled(store.isRefreshing)
            .accessibilityLabel(L10n.refreshCodexUsage)
        }
        .padding(16)
    }

    private var accountMenu: some View {
        Menu {
            Section(L10n.useAccount) {
                ForEach(store.accounts) { account in
                    Button {
                        store.requestAccountSwitch(to: account.id)
                    } label: {
                        if account.id == store.activeAccountID {
                            Label(account.displayName, systemImage: "checkmark")
                        } else {
                            Text(account.displayName)
                        }
                    }
                    .disabled(account.id == store.activeAccountID)
                }
            }
            Divider()
            Button(L10n.addAccount, systemImage: "person.badge.plus") {
                store.addAccount()
            }
            let removableAccounts = store.accounts.filter { $0.homePath != nil }
            if !removableAccounts.isEmpty {
                Menu(L10n.deleteAccount, systemImage: "trash") {
                    ForEach(removableAccounts) { account in
                        Button(account.displayName, role: .destructive) {
                            store.deleteAccount(id: account.id)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "person.crop.circle")
                Text(store.activeAccountDisplayName)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .font(.system(size: 11, weight: .medium))
            .frame(maxWidth: 112)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .disabled(store.isSwitchingCodexAccount)
        .help(L10n.switchCodexAccount)
        .accessibilityLabel(L10n.currentAccountAccessibility(store.activeAccountDisplayName))
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 0) {
            DisclosureGroup(isExpanded: $usageWindowsExpanded) {
                quotaContent
            } label: {
                SectionLabel(title: L10n.usageWindows, detail: store.activeAccountName)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.3), lineWidth: 0.6)
            }
            if let activity = store.activity {
                Divider()
                DisclosureGroup(isExpanded: $localActivityExpanded) {
                    LocalActivityView(activity: activity, rates: store.costRates, currency: store.currency, totalSavings: store.totalSavings)
                        .padding(.horizontal, -16)
                } label: {
                    SectionLabel(title: L10n.localActivity, detail: L10n.tokenCount(L10n.compactTokens(activity.total.totalTokens)))
                }
                .padding(16)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.3), lineWidth: 0.6)
                }
            } else if let activityError = store.activityError {
                Divider()
                HStack(alignment: .top, spacing: 9) {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.localActivityUnavailable)
                            .font(.system(size: 11, weight: .medium))
                        Text(activityError)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(16)
            }
        }
    }

    @ViewBuilder
    private var quotaContent: some View {
        if store.payload == nil && store.isRefreshing {
            VStack(spacing: 10) {
                ProgressView()
                    .controlSize(.small)
                Text(L10n.quotaChecking)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 148)
        } else if store.windows.isEmpty {
            EmptyState(message: store.errorMessage ?? L10n.usageDataUnavailable) {
                Task { await store.refresh() }
            }
        } else {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise.circle")
                        .foregroundStyle(Color.accentColor)
                    Text(L10n.bankedResets)
                        .font(.system(size: 10, weight: .medium))
                    Spacer()
                    Text(store.bankedResetCount.map(String.init) ?? "—")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .help(store.bankedResetCount == nil
                    ? L10n.bankedResetsUnknown
                    : L10n.bankedResetsAvailable)
                Divider().padding(.leading, 16)
                ForEach(Array(store.windows.enumerated()), id: \.offset) { index, window in
                    UsageRow(window: window)
                    if index < store.windows.count - 1 { Divider().padding(.leading, 16) }
                }
                if let error = store.errorMessage {
                    Text(error)
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                }
            }
        }
    }

    private var settings: some View {
        DisclosureGroup(isExpanded: $settingsExpanded) {
            footer
        } label: {
            SectionLabel(title: L10n.settingsTitle, detail: L10n.settingsDetail)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.3), lineWidth: 0.6)
        }
    }

    private var footer: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.activeAccount)
                        .font(.system(size: 12))
                    Text(store.activeAccountDisplayName)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Button(L10n.addShort) { store.addAccount() }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                Button(L10n.deleteShort) { store.deleteActiveAccount() }
                    .buttonStyle(.plain)
                    .foregroundStyle(store.canDeleteActiveAccount ? Color.red : Color.secondary)
                    .disabled(!store.canDeleteActiveAccount)
            }
            if let status = store.accountSwitchStatus {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text(status)
                        .font(.system(size: 10, weight: .medium))
                    Spacer()
                }
                .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                Text(L10n.desktopSwitchSignIn)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                Spacer()
                Button(L10n.openCodexEllipsis) { store.openCodex() }
                    .buttonStyle(.plain)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.accentColor)
            }
            HStack {
                Text(L10n.menuBar)
                    .font(.system(size: 12))
                Spacer()
                Picker(L10n.menuBarDisplay, selection: $store.displayMode) {
                    ForEach(MenuBarDisplayMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .labelsHidden()
                .frame(width: 150)
            }
            HStack {
                Text(L10n.currency)
                    .font(.system(size: 12))
                Spacer()
                Picker(L10n.currency, selection: $store.currency) {
                    ForEach(DisplayCurrency.allCases) { currency in
                        Text(currency.code).tag(currency)
                    }
                }
                .labelsHidden()
                .frame(width: 72)
            }
            HStack {
                Text(L10n.lowUsageAlert)
                    .font(.system(size: 12))
                Spacer()
                Picker(L10n.lowUsageAlert, selection: $store.alertThreshold) {
                    Text("10%").tag(10)
                    Text("20%").tag(20)
                    Text("30%").tag(30)
                }
                .labelsHidden()
                .frame(width: 72)
            }
            DisclosureGroup(L10n.fallbackPrice) {
                VStack(spacing: 7) {
                    CostRateField(label: L10n.priceInput, value: $store.inputRate)
                    CostRateField(label: L10n.priceCachedInput, value: $store.cachedInputRate)
                    CostRateField(label: L10n.priceOutput, value: $store.outputRate)
                    Text(L10n.fallbackPriceDetail)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 6)
            }
            .font(.system(size: 11))
            Toggle(L10n.launchAtLogin, isOn: Binding(
                get: { store.launchAtLogin },
                set: { store.setLaunchAtLogin($0) }
            ))
            .font(.system(size: 12))
            HStack {
                Button(L10n.openCodex) { store.openCodex() }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                Spacer()
                Button(L10n.quit) { NSApplication.shared.terminate(nil) }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
            }
            .font(.system(size: 12))
        }
        .padding(16)
    }

    private var headerSubtitle: String {
        if store.isStale { return L10n.lastUpdateStale }
        if let date = store.payload?.fetchedAt {
            return L10n.updated(L10n.shortTime(date), plan: store.planLabel)
        }
        return L10n.signedInThroughCodex
    }

}

private struct SectionLabel: View {
    let title: String
    let detail: String

    var body: some View {
        HStack {
            Text(title).font(.system(size: 12, weight: .medium))
            Spacer()
            Text(detail).font(.system(size: 10)).foregroundStyle(.secondary)
        }
    }
}

private struct CelebrationBanner: View {
    let celebration: Celebration

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: celebration.symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 1) {
                Text(celebration.title)
                    .font(.system(size: 12, weight: .semibold))
                Text(celebration.subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.accentColor.opacity(0.35)))
        .padding(.horizontal, 12)
        .shadow(color: .black.opacity(0.15), radius: 8, y: 3)
    }
}

private struct LocalActivityView: View {
    let activity: LocalActivitySnapshot
    let rates: LocalCostRates
    let currency: DisplayCurrency
    let totalSavings: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.localActivity)
                        .font(.system(size: 12, weight: .medium))
                    Text(L10n.sevenDaysLocalLogs)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text(L10n.compactTokens(activity.total.totalTokens))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                    Text(L10n.tokens)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }

            Chart(activity.days) { day in
                BarMark(
                    x: .value(L10n.chartDay, day.date, unit: .day),
                    y: .value(L10n.chartTokens, day.usage.totalTokens)
                )
                .foregroundStyle(Color.accentColor)
                .cornerRadius(2)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(L10n.weekday(date))
                        }
                    }
                }
            }
            .chartYAxis(.hidden)
            .frame(height: 62)
            .accessibilityLabel(L10n.sevenDayLocalTokenActivity)
            .accessibilityValue(accessibilitySummary)

            if !activity.models.isEmpty {
                VStack(spacing: 6) {
                    ForEach(activity.models) { item in
                        HStack(spacing: 8) {
                            Text(item.model)
                                .font(.system(size: 10, weight: .medium))
                                .lineLimit(1)
                            Spacer()
                            Text(modelShare(item))
                                .foregroundStyle(.secondary)
                            Text(modelCost(item))
                                .monospacedDigit()
                                .frame(width: 54, alignment: .trailing)
                        }
                        .font(.system(size: 10))
                        .accessibilityElement(children: .combine)
                    }
                }
            }

            HStack {
                Text(L10n.todayTokens(L10n.compactTokens(activity.today.totalTokens)))
                Spacer()
                Text(L10n.apiEquivalent(formatted(automaticEstimate)))
            }
            .font(.system(size: 10))
            .foregroundStyle(.secondary)
            Text(L10n.apiPriceNote)
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
            if totalSavings > 0 {
                Text(L10n.estimatedSavingsVersusSol(formatted(totalSavings)))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(16)
    }

    private var automaticEstimate: Double {
        let usd = activity.models.reduce(0) { total, item in
            if let price = OpenAIPriceCatalog.price(for: item.model) { return total + price.estimate(item.usage) }
            return total + (rates.isConfigured ? rates.estimate(item.usage) : 0)
        }
        return currency.convertFromUSD(usd)
    }

    private func modelCost(_ item: ModelTokenUsage) -> String {
        if let price = OpenAIPriceCatalog.price(for: item.model) {
            return formatted(currency.convertFromUSD(price.estimate(item.usage)))
        }
        if rates.isConfigured { return formatted(currency.convertFromUSD(rates.estimate(item.usage))) + "*" }
        return L10n.unpriced
    }

    private func modelShare(_ item: ModelTokenUsage) -> String {
        guard activity.total.totalTokens > 0 else { return "0%" }
        return "\(Int((Double(item.usage.totalTokens) / Double(activity.total.totalTokens) * 100).rounded()))% · \(L10n.compactTokens(item.usage.totalTokens))"
    }

    private func formatted(_ amount: Double) -> String {
        L10n.currencyAmount(amount, symbol: currency.symbol)
    }

    private var accessibilitySummary: String {
        activity.days.map { day in
            L10n.dailyTokenAccessibility(
                weekday: L10n.weekday(day.date),
                tokens: day.usage.totalTokens
            )
        }.joined(separator: ", ")
    }
}

private struct CostRateField: View {
    let label: String
    @Binding var value: Double

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", value: $value, format: .number.precision(.fractionLength(0...2)))
                .multilineTextAlignment(.trailing)
                .frame(width: 58)
            Text(L10n.pricePerMillion)
                .foregroundStyle(.secondary)
        }
    }
}

private struct UsageRow: View {
    let window: RateLimitWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(L10n.usageWindowName(durationMinutes: window.durationMinutes))
                            .font(.system(size: 12, weight: .medium))
                        if let warningText {
                            Text(warningText)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(meterColor)
                        }
                    }
                    Text(ResetTimeFormatter.relativeText(for: window.resetsAt))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .help(ResetTimeFormatter.absoluteText(for: window.resetsAt) ?? "")
                }
                Spacer()
                Text(L10n.percentage(window.remainingPercent))
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .accessibilityLabel(L10n.remainingPercent(window.remainingPercent))
            }

            ProgressView(value: Double(window.remainingPercent), total: 100)
                .progressViewStyle(.linear)
                .tint(meterColor)
                .animation(.easeInOut(duration: 0.45), value: window.remainingPercent)
                .accessibilityLabel(L10n.usageWindowName(durationMinutes: window.durationMinutes))
                .accessibilityValue(
                    L10n.remainingWithResetAccessibility(
                        window.remainingPercent,
                        reset: ResetTimeFormatter.relativeText(for: window.resetsAt)
                    )
                )
        }
        .padding(16)
    }

    private var meterColor: Color {
        if window.remainingPercent <= 10 { return .red }
        if window.remainingPercent <= 25 { return .orange }
        return .accentColor
    }

    private var warningText: String? {
        if window.remainingPercent <= 10 { return L10n.nearlyExhausted }
        if window.remainingPercent <= 25 { return L10n.runningLow }
        return nil
    }
}

private struct EmptyState: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 24))
                .foregroundStyle(.secondary)
            Text(L10n.quotaUnavailable)
                .font(.system(size: 13, weight: .semibold))
            Text(message)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 260)
            Button(L10n.tryAgain, action: retry)
                .controlSize(.small)
        }
        .frame(maxWidth: .infinity, minHeight: 166)
        .padding(.horizontal, 20)
    }
}
