#!/usr/bin/env python3
"""Portable contract audit for the fixed Simplified Chinese catalog."""

from __future__ import annotations

import re
import plistlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
STRINGS = ROOT / "Resources/zh-Hans.lproj/Localizable.strings"
L10N = ROOT / "Sources/CodexMeter/L10n.swift"
SWIFT_SOURCES = ROOT / "Sources/CodexMeter"
BUILD_SCRIPT = ROOT / "scripts/build-app.sh"
INSTALL_SCRIPT = ROOT / "scripts/install.sh"
INFO_PLIST = ROOT / "Resources/Info.plist"
README = ROOT / "README.md"
UPSTREAM = ROOT / "UPSTREAM.md"
CI_WORKFLOW = ROOT / ".github/workflows/ci.yml"
RELEASE_WORKFLOW = ROOT / ".github/workflows/release.yml"
ARCHIVE_NAME = "Codex-Meter-ZH-CN-1.5.0-zh.1.zip"
UPSTREAM_COMMIT = "75e3a1e8c4284afc842fb6d4910a4d8127fe203c"
ENGLISH_UI_SOURCES = {
    ROOT / "Sources/CodexMeter/CodexMeterApp.swift",
    ROOT / "Sources/CodexMeter/MeterView.swift",
    ROOT / "Sources/CodexMeter/UsageStore.swift",
}
FORBIDDEN_ENGLISH_UI = {
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

ENTRY = re.compile(
    r'"(?P<key>(?:\\.|[^"\\])*)"\s*=\s*"(?P<value>(?:\\.|[^"\\])*)"\s*;',
    re.DOTALL,
)
LOCALIZATION_CALL = re.compile(
    r'(?:L10n\.)?(?:text|format)\(\s*"(?P<key>(?:\\.|[^"\\])*)"\s*,\s*'
    r'default:\s*"(?P<value>(?:\\.|[^"\\])*)"',
    re.DOTALL,
)
FORMAT_CALL = re.compile(
    r'(?:L10n\.)?format\(\s*"(?P<key>(?:\\.|[^"\\])*)"\s*,\s*'
    r'default:\s*"(?P<value>(?:\\.|[^"\\])*)"',
    re.DOTALL,
)
PRINTF = re.compile(
    r'%(?:\d+\$)?[-+ #0\']*(?:\d+|\*)?(?:\.(?:\d+|\*))?'
    r'(?:hh|h|ll|l|L|z|j|t)?[@diuoxXfFeEgGaAcCsSp]'
)
STRING_ESCAPE = re.compile(r'\\(?:(?P<unicode>U[0-9A-Fa-f]{4})|(?P<simple>[\\"nrt]))')
INVALID_ESCAPE = re.compile(r'\\(?!U[0-9A-Fa-f]{4}|[\\"nrt])')


def strip_comments(source: str) -> str:
    """Remove comments while preserving source strings."""
    result: list[str] = []
    index = 0
    length = len(source)
    string_hashes: int | None = None
    string_quotes = 0

    while index < length:
        if string_hashes is not None:
            closing = '"' * string_quotes + "#" * string_hashes
            if source.startswith(closing, index):
                result.append(closing)
                index += len(closing)
                string_hashes = None
                string_quotes = 0
                continue
            if string_hashes == 0 and source[index] == "\\" and index + 1 < length:
                result.append(source[index : index + 2])
                index += 2
                continue
            result.append(source[index])
            index += 1
            continue

        if source.startswith("//", index):
            newline = source.find("\n", index + 2)
            if newline == -1:
                break
            result.append("\n")
            index = newline + 1
            continue

        if source.startswith("/*", index):
            depth = 1
            index += 2
            while index < length and depth:
                if source.startswith("/*", index):
                    depth += 1
                    index += 2
                elif source.startswith("*/", index):
                    depth -= 1
                    index += 2
                else:
                    if source[index] == "\n":
                        result.append("\n")
                    index += 1
            continue

        hash_count = 0
        while index + hash_count < length and source[index + hash_count] == "#":
            hash_count += 1
        quote_index = index + hash_count
        if quote_index < length and source[quote_index] == '"':
            quote_count = 3 if source.startswith('"""', quote_index) else 1
            opening = "#" * hash_count + '"' * quote_count
            result.append(opening)
            index += len(opening)
            string_hashes = hash_count
            string_quotes = quote_count
            continue

        result.append(source[index])
        index += 1

    return "".join(result)


def decode(value: str) -> str:
    """Decode the escapes supported by Localizable.strings values."""
    invalid = INVALID_ESCAPE.search(value)
    assert invalid is None, f"invalid Localizable.strings escape: {invalid.group(0)!r}"

    def replace(match: re.Match[str]) -> str:
        if unicode := match.group("unicode"):
            return chr(int(unicode[1:], 16))
        return {
            "\\": "\\",
            '"': '"',
            "n": "\n",
            "r": "\r",
            "t": "\t",
        }[match.group("simple")]

    decoded = STRING_ESCAPE.sub(replace, value)
    return decoded.encode("utf-16", "surrogatepass").decode("utf-16")


def parse_strings(source: str) -> dict[str, str]:
    """Parse a strict, duplicate-free Localizable.strings catalog."""
    catalog: dict[str, str] = {}
    cursor = 0
    for match in ENTRY.finditer(source):
        ignored = strip_comments(source[cursor : match.start()]).strip()
        assert not ignored, f"invalid Localizable.strings syntax near: {ignored[:40]!r}"
        key = decode(match.group("key"))
        assert key not in catalog, f"duplicate localization key: {key}"
        catalog[key] = decode(match.group("value"))
        cursor = match.end()

    ignored = strip_comments(source[cursor:]).strip()
    assert not ignored, f"invalid Localizable.strings syntax near: {ignored[:40]!r}"
    return catalog


def has_cjk(value: str) -> bool:
    return any("\u4e00" <= character <= "\u9fff" for character in value)


def placeholders(value: str) -> list[str]:
    return PRINTF.findall(value.replace("%%", ""))


def verify_build_resource_copy(source: str) -> None:
    copy = re.compile(
        r'cp\s+-R\s+"\$ROOT/Resources/zh-Hans\.lproj"\s+"\$APP/Contents/Resources/?"'
    )
    assert copy.search(source), "build script does not copy zh-Hans.lproj into app resources"


def verify_chinese_app_packaging(build_source: str, install_source: str) -> None:
    app_name = "Codex Meter 中文版.app"
    archive_name = "Codex-Meter-ZH-CN-1.5.0-zh.1.zip"
    assert app_name in build_source, "build script does not name the Chinese app bundle"
    assert archive_name in build_source, "build script does not name the Chinese ZIP archive"
    assert f'ARCHIVE_NAME="{archive_name}"' in build_source, (
        "build script does not define a portable ZIP basename"
    )
    assert 'CHECKSUM_NAME="$ARCHIVE_NAME.sha256"' in build_source, (
        "build script does not define the checksum basename"
    )
    assert 'cd "$OUTPUT"' in build_source, "build script does not checksum from the output directory"
    assert 'shasum -a 256 "$ARCHIVE_NAME" > "$CHECKSUM_NAME"' in build_source, (
        "checksum must contain the ZIP basename, not its output path"
    )
    assert 'shasum -a 256 "$ARCHIVE"' not in build_source, (
        "checksum must not contain an absolute or output-relative archive path"
    )
    archive_commands = re.findall(r"^\s*ditto\s+-c\s+-k\b[^\n]*$", build_source, re.MULTILINE)
    assert len(archive_commands) == 1, "build script must create exactly one ZIP archive"
    assert re.search(
        r'ditto\s+-c\s+-k\s+--sequesterRsrc\s+--keepParent\s+"\$FINAL_APP"\s+"\$ARCHIVE"',
        archive_commands[0],
    ), "ZIP archive must have the Chinese app as its only input"
    assert app_name in install_source, "install script does not target the Chinese app bundle"
    assert "/Applications/Codex Meter.app" not in install_source, (
        "install script must not target the English app bundle"
    )
    final_verification = re.search(
        r'codesign\s+--verify\s+--deep\s+--strict\s+(?:"\$APP_PATH"|"/Applications/Codex Meter 中文版\.app")',
        install_source,
    )
    assert final_verification, "install script does not verify the final Chinese app"
    backup_cleanups = list(re.finditer(r'rm\s+-rf\s+"\$BACKUP"', install_source))
    assert backup_cleanups, "install script does not clean up its Chinese app backup"
    assert final_verification.start() < backup_cleanups[-1].start(), (
        "install script removes the backup before final app verification"
    )
    assert re.search(
        r'if\s+!\s+codesign\s+--verify\s+--deep\s+--strict\s+"\$APP_PATH";\s*then'
        r'\s*restore_previous\s*\n\s*exit\s+1\s*\n\s*fi',
        install_source,
    ), "final verification failure must restore the previous Chinese app"
    assert 'if [[ -e "$APP_PATH" || -L "$APP_PATH" ]]; then' in install_source, (
        "install script must back up an existing file, directory, or symbolic link"
    )
    assert "NEW_APP_INSTALLED=0" in install_source, (
        "install script must track whether this run placed a new app"
    )
    assert re.search(
        r'if\s+!\s+mv\s+"\$STAGE/Codex Meter 中文版\.app"\s+"\$APP_PATH";\s*then'
        r'\s*restore_previous\s*\n\s*exit\s+1\s*\n\s*fi'
        r'\s*NEW_APP_INSTALLED=1',
        install_source,
    ), "install script must mark the new app only after the staged move succeeds"
    assert re.search(
        r'restore_previous\(\)\s*\{\s*if\s+\(\(\s+NEW_APP_INSTALLED\s+\)\);\s+then'
        r'\s*rm\s+-rf\s+"\$APP_PATH"\s*\n\s*fi',
        install_source,
    ), "restore must delete the target only when this run installed a new app"


def verify_chinese_bundle_identity(plist: dict[str, object]) -> None:
    assert plist["CFBundleIdentifier"] == "com.xuancao1953.codexmeter.zhcn"
    assert plist["CFBundleDisplayName"] == "Codex Meter 中文版"
    assert plist["CFBundleShortVersionString"] == "1.5.0-zh.1"
    assert plist["CFBundleDevelopmentRegion"] == "zh-Hans"
    assert plist["CFBundleLocalizations"] == ["zh-Hans"]


def verify_public_documentation(readme: str, upstream: str) -> None:
    required_readme_phrases = {
        "基于 TheJhyeFactor/codex-meter 制作的简体中文独立版本",
        "https://github.com/TheJhyeFactor/codex-meter",
        "Jhye / The Jhye Factor",
        "MIT License",
        "非官方社区项目",
    }
    missing = sorted(phrase for phrase in required_readme_phrases if phrase not in readme)
    assert not missing, f"README is missing attribution/disclosure text: {missing}"
    assert "UPSTREAM.md" in readme, "README does not link to UPSTREAM.md"
    assert UPSTREAM_COMMIT in upstream, "UPSTREAM.md does not pin the imported upstream commit"
    assert "https://github.com/TheJhyeFactor/codex-meter" in upstream, (
        "UPSTREAM.md does not identify the upstream repository"
    )
    assert "MIT License" in upstream, "UPSTREAM.md does not preserve the upstream license notice"


def verify_zip_root_contract(source: str, workflow_name: str) -> None:
    contract = re.compile(
        r'(?m)^          EXPECTED_APP="\$STAGE/Codex Meter 中文版\.app"\n'
        r"          shopt -s nullglob dotglob\n"
        r'          ROOT_ENTRIES=\("\$STAGE"/\*\)\n'
        r"          shopt -u nullglob dotglob\n"
        r'          test "\$\{#ROOT_ENTRIES\[@\]\}" -eq 1\n'
        r'          test "\$\{ROOT_ENTRIES\[0\]\}" = "\$EXPECTED_APP"\n'
        r'          ARCHIVED_APP="\$EXPECTED_APP"$'
    )
    assert contract.search(source), (
        f"{workflow_name} must safely require the Chinese app as the only ZIP root entry"
    )


def verify_ci_workflow(source: str) -> None:
    required = {
        "macos-15": "CI must run on macos-15",
        "actions/checkout@v5": "CI must use actions/checkout@v5",
        "python3 Tests/LocalizationAudit.py": "CI does not run the localization audit",
        "SKIP_LIVE_CODEX_CHECK=1 ./scripts/test.sh": "CI does not run offline tests",
        "./scripts/build-app.sh dist": "CI does not build the Chinese app",
        'APP="dist/Codex Meter 中文版.app"': "CI does not target the Chinese app",
        'lipo "$APP/Contents/MacOS/CodexMeter" -verify_arch arm64 x86_64': (
            "CI does not verify both architectures in the app"
        ),
        'lipo "dist/codex-meter" -verify_arch arm64 x86_64': (
            "CI does not verify both architectures in the CLI"
        ),
        'codesign --verify --deep --strict "$APP"': "CI does not verify the app signature",
        'codesign --verify --strict "dist/codex-meter"': "CI does not verify the CLI signature",
        "cmp Resources/zh-Hans.lproj/Localizable.strings": (
            "CI does not verify the packaged Chinese resources"
        ),
        'unzip -tq "$ZIP"': "CI does not test the ZIP archive",
        "actions/upload-artifact@v4": "CI does not upload a build artifact",
        f"path: dist/{ARCHIVE_NAME}": "CI does not upload the versioned Chinese ZIP",
    }
    for needle, message in required.items():
        assert needle in source, message
    verify_zip_root_contract(source, "CI")


def verify_release_workflow(source: str) -> None:
    assert re.search(r"(?m)^permissions:\n  contents: write$", source), (
        "release workflow must grant contents: write"
    )
    release_step = re.search(
        r"(?m)^      - name: Create GitHub release\n"
        r"        env:\n"
        r"          GH_TOKEN: \$\{\{ github\.token \}\}\n"
        r"        run: \|\n"
        r"(?P<body>(?:          .*(?:\n|$))+)",
        source,
    )
    assert release_step, "release creation step must receive GH_TOKEN from github.token"
    assert 'gh release create "$GITHUB_REF_NAME" "$ZIP" "$CHECKSUM"' in release_step.group(
        "body"
    ), "authenticated release step must upload both the ZIP and SHA-256 file"
    required = {
        'tags: ["v*-zh.*"]': "release tags must use the v*-zh.* pattern",
        "macos-15": "release must run on macos-15",
        "actions/checkout@v5": "release must use actions/checkout@v5",
        "python3 Tests/LocalizationAudit.py": "release does not run the localization audit",
        "SKIP_LIVE_CODEX_CHECK=1 ./scripts/test.sh": "release does not run offline tests",
        "./scripts/build-app.sh dist": "release does not build the Chinese app",
        'test "v${VERSION}" = "$GITHUB_REF_NAME"': (
            "release does not require the tag to exactly match the bundle version"
        ),
        'lipo "$APP/Contents/MacOS/CodexMeter" -verify_arch arm64 x86_64': (
            "release does not verify both architectures in the app"
        ),
        'lipo "dist/codex-meter" -verify_arch arm64 x86_64': (
            "release does not verify both architectures in the CLI"
        ),
        'codesign --verify --deep --strict "$APP"': (
            "release does not verify the app signature"
        ),
        'codesign --verify --strict "dist/codex-meter"': (
            "release does not verify the CLI signature"
        ),
        "cmp Resources/zh-Hans.lproj/Localizable.strings": (
            "release does not verify the packaged Chinese resources"
        ),
        'unzip -tq "$ZIP"': "release does not test the ZIP archive",
        'CHECKSUM="dist/Codex-Meter-ZH-CN-${VERSION}.zip.sha256"': (
            "release does not select the generated SHA-256 file"
        ),
        'shasum -a 256 -c "Codex-Meter-ZH-CN-${VERSION}.zip.sha256"': (
            "release does not verify the generated SHA-256 checksum"
        ),
        'gh release create "$GITHUB_REF_NAME" "$ZIP" "$CHECKSUM"': (
            "release does not upload both the ZIP and SHA-256 file"
        ),
    }
    for needle, message in required.items():
        assert needle in source, message
    verify_zip_root_contract(source, "release")


def verify_catalog_lookups(catalog: dict[str, str], source: str, path: Path) -> None:
    for match in LOCALIZATION_CALL.finditer(source):
        key = decode(match.group("key"))
        assert key in catalog, f"{path}: missing catalog key for L10n lookup: {key}"


def verify_format_defaults(catalog: dict[str, str], source: str, path: Path) -> None:
    for match in FORMAT_CALL.finditer(source):
        key = decode(match.group("key"))
        default = decode(match.group("value"))
        assert key in catalog, f"{path}: missing catalog key for L10n.format: {key}"
        assert placeholders(default) == placeholders(catalog[key]), (
            f"{path}: printf placeholders differ for {key}: "
            f"default={placeholders(default)!r}, catalog={placeholders(catalog[key])!r}"
        )


def verify_no_forbidden_english_ui(source: str, path: Path) -> None:
    uncommented = strip_comments(source)
    remaining = sorted(phrase for phrase in FORBIDDEN_ENGLISH_UI if phrase in uncommented)
    assert not remaining, f"{path}: forbidden English UI phrases: {remaining}"


def verify_comment_scanner() -> None:
    fixture = r'''
let settingsURL = URL(string: "codex://settings")
let escaped = "保留 \"//\" 与 Quit Codex Meter"
// hidden line comment
let visible = "Refresh usage"
/* hidden block comment */
'''
    uncommented = strip_comments(fixture)
    assert '"codex://settings"' in uncommented, (
        "comment scanner removed // from a string literal"
    )
    assert r'"保留 \"//\" 与 Quit Codex Meter"' in uncommented, (
        "comment scanner did not preserve escaped quotes and string content"
    )
    assert '"Refresh usage"' in uncommented, (
        "string content must remain visible to the forbidden-English audit"
    )
    assert "hidden line comment" not in uncommented
    assert "hidden block comment" not in uncommented
    try:
        verify_no_forbidden_english_ui(fixture, Path("<comment-scanner-regression>"))
    except AssertionError as error:
        message = str(error)
        assert "Quit Codex Meter" in message
        assert "Refresh usage" in message
    else:
        raise AssertionError("forbidden-English audit ignored strings containing //")
    verify_no_forbidden_english_ui(
        "// Quit Codex Meter\n/* Refresh usage */",
        Path("<comment-only-regression>"),
    )


def verify_fixed_localization_contract(catalog: dict[str, str], l10n_source: str) -> None:
    expected = {
        "menu.quit": "退出 Codex Meter 中文版",
        "account.add.title": "添加 Codex 账户",
        "plan.plus": "Plus 套餐",
        "plan.pro": "Pro 套餐",
        "plan.team": "团队套餐",
        "plan.business": "商业套餐",
        "plan.enterprise": "企业套餐",
        "plan.edu": "教育套餐",
        "plan.free": "免费套餐",
        "plan.unknown": "其他套餐（%@）",
    }
    for key, value in expected.items():
        assert catalog.get(key) == value, (
            f"fixed localization differs for {key}: "
            f"expected={value!r}, actual={catalog.get(key)!r}"
        )
    assert 'menuQuit = text("menu.quit", default: "退出 Codex Meter 中文版")' in l10n_source
    assert 'addAccountTitle = text("account.add.title", default: "添加 Codex 账户")' in l10n_source


def verify_plan_label_contract(l10n_source: str, usage_source: str) -> None:
    assert ".capitalized" not in usage_source, (
        "plan labels must not expose title-cased English planType values"
    )
    assert "return L10n.planName(planType)" in usage_source, (
        "UsageStore planLabel must use the centralized Chinese plan-name mapping"
    )
    expected_cases = {
        "plus": "plan.plus",
        "pro": "plan.pro",
        "team": "plan.team",
        "business": "plan.business",
        "enterprise": "plan.enterprise",
        "edu": "plan.edu",
        "free": "plan.free",
    }
    for raw_value, key in expected_cases.items():
        assert f'case "{raw_value}": return text("{key}",' in l10n_source, (
            f"L10n plan-name mapping is missing {raw_value!r}"
        )
    assert (
        'return format("plan.unknown", default: "其他套餐（%@）", rawValue)'
        in l10n_source
    ), "unknown plan labels must preserve the raw technical value in Chinese context"


def verify_fixed_number_formatting(l10n_source: str, meter_source: str) -> None:
    assert "static func compactTokens(_ value: Int64) -> String" in l10n_source
    assert "static func currencyAmount(_ amount: Double, symbol: String) -> String" in l10n_source
    assert 'String(format: "%.1f", locale: locale,' in l10n_source
    assert 'String(format: "%.2f", locale: locale,' in l10n_source
    assert not re.search(r"(?<!L10n\.)compactTokens\(", meter_source), (
        "MeterView must use the centralized compact-token formatter"
    )
    assert ".formatted(.number" not in meter_source, (
        "MeterView amount formatting must not inherit the system locale"
    )


def main() -> None:
    assert STRINGS.is_file(), "missing zh-Hans Localizable.strings"
    assert L10N.is_file(), "missing L10n.swift"
    assert SWIFT_SOURCES.is_dir(), "missing CodexMeter Swift source directory"
    assert BUILD_SCRIPT.is_file(), "missing build-app.sh"
    assert INSTALL_SCRIPT.is_file(), "missing install.sh"
    assert INFO_PLIST.is_file(), "missing Info.plist"
    assert README.is_file(), "missing README.md"
    assert CI_WORKFLOW.is_file(), "missing CI workflow"
    assert RELEASE_WORKFLOW.is_file(), "missing release workflow"

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
    assert required_keys <= catalog.keys(), (
        f"missing required localization keys: {sorted(required_keys - catalog.keys())}"
    )
    assert all(has_cjk(catalog[key]) for key in required_keys), (
        "required localization values must contain Simplified Chinese text"
    )
    l10n_source = L10N.read_text(encoding="utf-8")
    usage_source = (SWIFT_SOURCES / "UsageStore.swift").read_text(encoding="utf-8")
    meter_source = (SWIFT_SOURCES / "MeterView.swift").read_text(encoding="utf-8")
    verify_comment_scanner()
    verify_fixed_localization_contract(catalog, l10n_source)
    verify_plan_label_contract(l10n_source, usage_source)
    verify_fixed_number_formatting(l10n_source, meter_source)
    build_source = BUILD_SCRIPT.read_text(encoding="utf-8")
    verify_build_resource_copy(build_source)
    verify_chinese_app_packaging(build_source, INSTALL_SCRIPT.read_text(encoding="utf-8"))
    with INFO_PLIST.open("rb") as file:
        verify_chinese_bundle_identity(plistlib.load(file))
    verify_public_documentation(
        README.read_text(encoding="utf-8"),
        UPSTREAM.read_text(encoding="utf-8") if UPSTREAM.is_file() else "",
    )
    verify_ci_workflow(CI_WORKFLOW.read_text(encoding="utf-8"))
    verify_release_workflow(RELEASE_WORKFLOW.read_text(encoding="utf-8"))
    for source_path in sorted(SWIFT_SOURCES.glob("*.swift")):
        source = source_path.read_text(encoding="utf-8")
        verify_catalog_lookups(catalog, source, source_path)
        verify_format_defaults(catalog, source, source_path)
        if source_path in ENGLISH_UI_SOURCES:
            verify_no_forbidden_english_ui(source, source_path)
    print("Localization audit passed")


if __name__ == "__main__":
    main()
