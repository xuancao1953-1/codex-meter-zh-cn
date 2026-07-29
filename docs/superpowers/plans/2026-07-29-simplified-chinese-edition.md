# Codex Meter Simplified Chinese Edition Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and publicly release an independent, always-Simplified-Chinese macOS edition named `Codex Meter 中文版.app`.

**Architecture:** Add a fixed `zh-Hans` localization façade in the macOS app target, backed by a `Localizable.strings` resource and Chinese date/relative-time formatters. Route every AppKit, SwiftUI, notification, status, tooltip, and accessibility string through that façade, then package the app under a distinct bundle identity. A portable Python audit runs locally, while GitHub Actions performs the Swift tests, universal macOS build, signing verification, and tagged release packaging.

**Tech Stack:** Swift 6, SwiftUI, AppKit, Foundation localization resources, zsh build scripts, Python 3 audit, GitHub Actions on `macos-15`.

## Global Constraints

- Base exactly on upstream `TheJhyeFactor/codex-meter` version `1.5.0`, commit `75e3a1e8c4284afc842fb6d4910a4d8127fe203c`.
- Preserve the upstream Git history, unmodified MIT `LICENSE`, original copyright, and prominent upstream attribution.
- App filename and display name: `Codex Meter 中文版.app` and `Codex Meter 中文版`.
- Bundle identifier: `com.xuancao1953.codexmeter.zhcn`.
- Version: `1.5.0-zh.1`; minimum macOS version: 13.0.
- Language: fixed Simplified Chinese (`zh-Hans`), without a language selector.
- Keep `Codex`, `OpenAI`, model IDs, currency codes, and filesystem paths unchanged.
- Do not add analytics, credentials handling, a new data source, automatic updates, or Apple notarization claims.
- Release artifact: one ZIP containing only `Codex Meter 中文版.app`, plus a SHA-256 file beside it.

---

### Task 1: Establish the localization contract and fixed Chinese formatter

**Files:**
- Create: `Tests/LocalizationAudit.py`
- Create: `Sources/CodexMeter/L10n.swift`
- Create: `Resources/zh-Hans.lproj/Localizable.strings`
- Modify: `scripts/test.sh`

**Interfaces:**
- Consumes: `Bundle.main`, `Locale(identifier: "zh-Hans-CN")`, and the app bundle’s `zh-Hans.lproj`.
- Produces: `L10n.text(_:default:)`, `L10n.format(_:default:_:)`, `L10n.shortTime(_:)`, `L10n.dateTime(_:)`, `L10n.weekday(_:)`, and `L10n.relativeReset(_:now:)`.

- [ ] **Step 1: Write the failing localization audit**

Create `Tests/LocalizationAudit.py` with checks that:

```python
ROOT = Path(__file__).resolve().parents[1]
STRINGS = ROOT / "Resources/zh-Hans.lproj/Localizable.strings"
L10N = ROOT / "Sources/CodexMeter/L10n.swift"

assert STRINGS.is_file(), "missing zh-Hans Localizable.strings"
assert L10N.is_file(), "missing L10n.swift"

required_keys = {
    "app.name",
    "menu.refresh",
    "menu.quit",
    "quota.checking",
    "quota.unavailable",
    "settings.title",
    "account.add.title",
    "account.delete.title",
    "notification.low.title",
    "reset.unavailable",
}
catalog = parse_strings(STRINGS.read_text(encoding="utf-8"))
assert required_keys <= catalog.keys()
assert all(has_cjk(catalog[key]) for key in required_keys)
```

The parser must reject duplicate keys and compare printf placeholder sequences between each
`L10n.format` default value and the catalog value.

- [ ] **Step 2: Run the audit and verify RED**

Run: `python3 Tests/LocalizationAudit.py`

Expected: non-zero exit with `missing zh-Hans Localizable.strings`.

- [ ] **Step 3: Add the fixed-language localization façade and catalog**

Implement `L10n.swift` with:

```swift
enum L10n {
    static let locale = Locale(identifier: "zh-Hans-CN")

    private static let chineseBundle: Bundle = {
        guard let path = Bundle.main.path(forResource: "zh-Hans", ofType: "lproj"),
              let bundle = Bundle(path: path) else { return .main }
        return bundle
    }()

    static func text(_ key: String, default value: String) -> String {
        chineseBundle.localizedString(forKey: key, value: value, table: nil)
    }

    static func format(_ key: String, default value: String, _ arguments: CVarArg...) -> String {
        String(format: text(key, default: value), locale: locale, arguments: arguments)
    }
}
```

Add deterministic Chinese formatters for short time, abbreviated date/time, weekday, and
relative reset text. Seed `Localizable.strings` with all keys used by `L10n.swift`; Chinese
defaults and catalog entries must carry matching `%@`, `%d`, or `%.0f` placeholders.

- [ ] **Step 4: Add the audit to the standard test entry point**

Insert `python3 "$ROOT/Tests/LocalizationAudit.py"` before Swift compilation in
`scripts/test.sh`, so catalog and source audits fail before the expensive build.

- [ ] **Step 5: Run the audit and verify GREEN**

Run: `python3 Tests/LocalizationAudit.py`

Expected: `Localization audit passed` and exit 0.

- [ ] **Step 6: Commit**

```bash
git add Tests/LocalizationAudit.py Sources/CodexMeter/L10n.swift \
  Resources/zh-Hans.lproj/Localizable.strings scripts/test.sh
git commit -m "feat: add fixed Simplified Chinese localization"
```

### Task 2: Route all macOS App text through the Chinese catalog

**Files:**
- Modify: `Sources/CodexMeter/CodexMeterApp.swift`
- Modify: `Sources/CodexMeter/MeterView.swift`
- Modify: `Sources/CodexMeter/UsageStore.swift`
- Modify: `Sources/CodexMeter/L10n.swift`
- Modify: `Resources/zh-Hans.lproj/Localizable.strings`
- Modify: `Tests/LocalizationAudit.py`

**Interfaces:**
- Consumes: Task 1’s `L10n` API.
- Produces: a macOS UI whose labels, dynamic statuses, notifications, alerts, tooltips, reset text, chart accessibility text, and account workflows are Simplified Chinese.

- [ ] **Step 1: Expand the audit with the English regression set**

Add an exact forbidden-phrase set covering the existing app literals, including:

```python
forbidden = {
    "Refresh usage",
    "Quit Codex Meter",
    "Usage windows",
    "Local activity unavailable",
    "Checking Codex usage",
    "Banked resets",
    "Display, alerts and accounts",
    "Launch at login",
    "API-equivalent",
    "Nearly exhausted",
    "Usage unavailable",
    "Switch Meter",
    "Delete Account",
    "Signing Codex out",
    "Codex usage is running low",
    "Reset time unavailable",
}
```

Scan `CodexMeterApp.swift`, `MeterView.swift`, and `UsageStore.swift`, and fail when a
forbidden phrase remains outside comments.

- [ ] **Step 2: Run the audit and verify RED**

Run: `python3 Tests/LocalizationAudit.py`

Expected: non-zero exit listing English phrases still present in the app source.

- [ ] **Step 3: Localize the application shell**

Replace the preview title, right-click menu items, tooltip composition, status icon
accessibility descriptions, stale/checking text, and seven-day activity description in
`CodexMeterApp.swift` with typed `L10n` properties/functions.

- [ ] **Step 4: Localize the popover and accessibility content**

Replace every user-facing literal in `MeterView.swift`, including:

- Header, account menu, usage windows, banked resets, empty/error states.
- Settings, account buttons, menu-bar mode names, cost fallback fields, launch at login.
- Local activity headings, chart axis/accessibility labels, Token totals and API estimates.
- Remaining-percentage accessibility text, warning labels, retry button, and reset time.

Use `L10n.weekday(_:)`, `L10n.shortTime(_:)`, and `L10n.relativeReset(_:now:)` instead of
system-locale `formatted`/`RelativeDateTimeFormatter` output.

- [ ] **Step 5: Localize dynamic store messages and AppKit alerts**

Replace `MenuBarDisplayMode.title`, default account labels, errors, account add/switch/delete
dialogs, celebration banners, switch progress, notification title/body, and
`ResetTimeFormatter` output in `UsageStore.swift`.

When a `CodexClientError` or system error is surfaced, prepend a Chinese action context while
preserving its technical detail. Preserve `Codex`, `OpenAI`, email addresses, model IDs, and
currency codes.

- [ ] **Step 6: Run the audit and verify GREEN**

Run: `python3 Tests/LocalizationAudit.py`

Expected: `Localization audit passed`, with no forbidden UI phrase and no missing or mismatched
catalog key.

- [ ] **Step 7: Commit**

```bash
git add Sources/CodexMeter/CodexMeterApp.swift \
  Sources/CodexMeter/MeterView.swift Sources/CodexMeter/UsageStore.swift \
  Sources/CodexMeter/L10n.swift Resources/zh-Hans.lproj/Localizable.strings \
  Tests/LocalizationAudit.py
git commit -m "feat: translate Codex Meter interface"
```

### Task 3: Give the Chinese app an independent identity and package

**Files:**
- Modify: `Resources/Info.plist`
- Modify: `Resources/INSTALL.txt`
- Modify: `scripts/build-app.sh`
- Modify: `scripts/install.sh`
- Modify: `Tests/LocalizationAudit.py`

**Interfaces:**
- Consumes: translated source and `zh-Hans.lproj`.
- Produces: `dist/Codex Meter 中文版.app`, `dist/Codex-Meter-ZH-CN-1.5.0-zh.1.zip`, and `dist/Codex-Meter-ZH-CN-1.5.0-zh.1.zip.sha256`.

- [ ] **Step 1: Add identity and package assertions**

Extend `Tests/LocalizationAudit.py` to parse `Resources/Info.plist` and assert:

```python
assert plist["CFBundleIdentifier"] == "com.xuancao1953.codexmeter.zhcn"
assert plist["CFBundleDisplayName"] == "Codex Meter 中文版"
assert plist["CFBundleShortVersionString"] == "1.5.0-zh.1"
assert plist["CFBundleDevelopmentRegion"] == "zh-Hans"
assert plist["CFBundleLocalizations"] == ["zh-Hans"]
```

Also assert that build/install scripts reference `Codex Meter 中文版.app`, copy
`Resources/zh-Hans.lproj`, and never target `/Applications/Codex Meter.app`.

- [ ] **Step 2: Run the audit and verify RED**

Run: `python3 Tests/LocalizationAudit.py`

Expected: non-zero exit because the original bundle identifier and English app path remain.

- [ ] **Step 3: Update bundle metadata**

Set the exact identity values above, retain `LSUIElement`, `LSMinimumSystemVersion=13.0`, and
the original copyright in `Info.plist`. Add `CFBundleLocalizations` with only `zh-Hans`.

- [ ] **Step 4: Update build and installation scripts**

Make `scripts/build-app.sh`:

- Build and merge both existing macOS architecture triples.
- Copy `Info.plist` and `Resources/zh-Hans.lproj` into the App.
- Sign and verify the App.
- Zip only `Codex Meter 中文版.app`.
- Generate SHA-256 with `shasum -a 256`.

Make `scripts/install.sh` stage, back up, replace, verify, and open only
`/Applications/Codex Meter 中文版.app`. Translate `Resources/INSTALL.txt` and document the
Control-click first-launch path.

- [ ] **Step 5: Run identity and shell syntax checks**

Run:

```bash
python3 Tests/LocalizationAudit.py
zsh -n scripts/build-app.sh scripts/install.sh scripts/test.sh
```

Expected: audit success and zsh syntax exit 0.

- [ ] **Step 6: Commit**

```bash
git add Resources/Info.plist Resources/INSTALL.txt \
  scripts/build-app.sh scripts/install.sh Tests/LocalizationAudit.py
git commit -m "build: package independent Chinese app"
```

### Task 4: Publish transparent Chinese documentation and macOS automation

**Files:**
- Modify: `README.md`
- Create: `UPSTREAM.md`
- Modify: `.github/workflows/ci.yml`
- Modify: `.github/workflows/release.yml`
- Modify: `Tests/LocalizationAudit.py`

**Interfaces:**
- Consumes: Task 3’s app and ZIP output.
- Produces: an attributed public repository, pull-request CI, and tagged GitHub Releases.

- [ ] **Step 1: Add documentation and workflow assertions**

Extend the audit to require the README phrases:

```text
基于 TheJhyeFactor/codex-meter 制作的简体中文独立版本
https://github.com/TheJhyeFactor/codex-meter
Jhye / The Jhye Factor
MIT License
非官方社区项目
```

Require CI to run `python3 Tests/LocalizationAudit.py`, `SKIP_LIVE_CODEX_CHECK=1
./scripts/test.sh`, build the Chinese App, verify both architectures/signature/resources, and
upload the ZIP artifact. Require release workflow tags `v*-zh.*`, exact version validation,
SHA-256 upload, and `gh release create`.

- [ ] **Step 2: Run the audit and verify RED**

Run: `python3 Tests/LocalizationAudit.py`

Expected: non-zero exit because the original English README and original workflow artifact
paths remain.

- [ ] **Step 3: Replace README with the Chinese project page**

Document project origin at the top, features, privacy, requirements, download/install,
first-launch Gatekeeper instructions, coexistence, clean build commands, update policy, MIT
license, and independence from both upstream and OpenAI. Link `UPSTREAM.md` for the pinned
commit and a concise list of Chinese-edition changes.

- [ ] **Step 4: Update CI and release workflows**

Use `macos-15` and `actions/checkout@v5`. CI must upload
`dist/Codex-Meter-ZH-CN-1.5.0-zh.1.zip` via `actions/upload-artifact@v4`. Release must verify
that `v${CFBundleShortVersionString}` equals `GITHUB_REF_NAME`, rerun tests/build checks, and
publish both ZIP and `.sha256` using the runner’s authenticated `gh`.

- [ ] **Step 5: Run documentation and workflow checks**

Run:

```bash
python3 Tests/LocalizationAudit.py
zsh -n scripts/build-app.sh scripts/install.sh scripts/test.sh
git diff --check
```

Expected: all commands exit 0.

- [ ] **Step 6: Commit**

```bash
git add README.md UPSTREAM.md .github/workflows/ci.yml \
  .github/workflows/release.yml Tests/LocalizationAudit.py
git commit -m "docs: publish attributed Chinese edition"
```

### Task 5: Verify, publish, and produce the first GitHub release

**Files:**
- Review: all tracked changes since upstream commit `75e3a1e8c4284afc842fb6d4910a4d8127fe203c`
- Modify only if verification exposes a concrete defect.

**Interfaces:**
- Consumes: Tasks 1–4.
- Produces: a public GitHub repository, passing macOS Actions run, and release
`v1.5.0-zh.1`.

- [ ] **Step 1: Run fresh local verification**

Run:

```bash
python3 Tests/LocalizationAudit.py
zsh -n scripts/build-app.sh scripts/install.sh scripts/test.sh
git diff --check 75e3a1e8c4284afc842fb6d4910a4d8127fe203c..HEAD
git status -sb
```

Expected: audit success, shell syntax success, no whitespace errors, and no uncommitted files.

- [ ] **Step 2: Review scope and attribution**

Run:

```bash
git log --oneline 75e3a1e8c4284afc842fb6d4910a4d8127fe203c..HEAD
git diff --stat 75e3a1e8c4284afc842fb6d4910a4d8127fe203c..HEAD
git diff -- LICENSE
```

Expected: only design, localization, packaging, automation, and documentation changes;
`git diff -- LICENSE` prints nothing.

- [ ] **Step 3: Publish the branch to the user’s public repository**

Point `origin` to the user-provided `codex-meter-zh-cn` repository, push
`agent/simplified-chinese-edition`, and open a draft pull request to `main`. If the empty
repository has no default branch, push the reviewed commit history as `main` instead and
verify the repository is public through the connected GitHub account.

- [ ] **Step 4: Confirm macOS CI**

Inspect the new Actions run. Success requires:

- Swift/core tests exit 0.
- Localization audit exits 0.
- Universal App build exits 0.
- `lipo` reports `arm64` and `x86_64`.
- `codesign --verify --deep --strict` exits 0.
- ZIP artifact contains exactly the Chinese App.

- [ ] **Step 5: Tag and publish the release**

Create and push annotated tag `v1.5.0-zh.1` only after CI succeeds. Inspect the release
workflow and GitHub Release, then verify that both the ZIP and SHA-256 assets are downloadable.

- [ ] **Step 6: Final handoff**

Report the repository URL, release URL, exact artifact name, CI evidence, installation steps,
and the ad-hoc-signing first-launch instruction. If GitHub repository creation or macOS CI is
blocked, report the exact blocker without claiming the App has been built.
