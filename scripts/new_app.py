#!/usr/bin/env python3
"""Create a new iOS app that follows the easy-ios defaults.

Generates a plain Xcode project (SwiftUI, iOS 17, Swift Testing, XCUITest)
that uses folder-synchronized groups: files added to the app, test, or UI test
folders are picked up automatically, so the project file rarely changes and
doesn't cause merge conflicts.

Usage:
  scripts/new_app.py Name --category productivity --symbol checklist --color 0A84FF
"""

import argparse
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BUNDLE_PREFIX = "org.polyglotlearn.easyios"
CATEGORIES = [
    "books", "business", "developer-tools", "education", "entertainment",
    "finance", "food-and-drink", "games", "graphics-design", "healthcare-fitness",
    "lifestyle", "magazines-and-newspapers", "medical", "music", "navigation", "news",
    "photography", "productivity", "reference", "shopping", "social-networking", "sports",
    "travel", "utilities", "video", "weather",
]


def uid(name, key):
    """Stable 24-hex object id, so regenerating a project gives the same file."""
    return hashlib.md5(f"{name}:{key}".encode()).hexdigest()[:24].upper()


def pbxproj(name, display, category):
    i = {k: uid(name, k) for k in [
        "project", "main", "products", "projlist", "projdebug", "projrelease",
        "app", "app.product", "app.group", "app.src", "app.fw", "app.res", "app.list", "app.debug", "app.release",
        "ut", "ut.product", "ut.group", "ut.src", "ut.fw", "ut.res", "ut.list", "ut.debug", "ut.release", "ut.dep", "ut.proxy",
        "ui", "ui.product", "ui.group", "ui.src", "ui.fw", "ui.res", "ui.list", "ui.debug", "ui.release", "ui.dep", "ui.proxy",
    ]}
    bundle = f"{BUNDLE_PREFIX}.{name.lower()}"

    common = """				CLANG_ENABLE_MODULES = YES;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				GENERATE_INFOPLIST_FILE = YES;
				MARKETING_VERSION = 1.0;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_APPROACHABLE_CONCURRENCY = YES;
				SWIFT_VERSION = 6.0;
				TARGETED_DEVICE_FAMILY = "1,2";"""

    app_settings = f"""{common}
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				ENABLE_PREVIEWS = YES;
				INFOPLIST_KEY_CFBundleDisplayName = "{display}";
				INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.{category}";
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				PRODUCT_BUNDLE_IDENTIFIER = {bundle};
				SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor;
				SWIFT_EMIT_LOC_STRINGS = YES;"""

    ut_settings = f"""{common}
				BUNDLE_LOADER = "$(TEST_HOST)";
				PRODUCT_BUNDLE_IDENTIFIER = {bundle}.tests;
				SWIFT_EMIT_LOC_STRINGS = NO;
				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/{name}.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/{name}";"""

    ui_settings = f"""{common}
				PRODUCT_BUNDLE_IDENTIFIER = {bundle}.uitests;
				SWIFT_EMIT_LOC_STRINGS = NO;
				TEST_TARGET_NAME = {name};"""

    project_debug = """				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";"""

    project_release = """				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				VALIDATE_PRODUCT = YES;"""

    def phases(t):
        return "\n".join(
            f"""		{i[f'{t}.{k}']} /* {label} */ = {{
			isa = {isa};
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};"""
            for k, label, isa in [
                ("fw", "Frameworks", "PBXFrameworksBuildPhase"),
                ("res", "Resources", "PBXResourcesBuildPhase"),
                ("src", "Sources", "PBXSourcesBuildPhase"),
            ]
        )

    def target(t, tname, ptype, product, dep):
        deps = f"\n				{i[f'{t}.dep']} /* PBXTargetDependency */," if dep else ""
        return f"""		{i[t]} /* {tname} */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {i[f'{t}.list']} /* Build configuration list for PBXNativeTarget "{tname}" */;
			buildPhases = (
				{i[f'{t}.src']} /* Sources */,
				{i[f'{t}.fw']} /* Frameworks */,
				{i[f'{t}.res']} /* Resources */,
			);
			buildRules = (
			);
			dependencies = ({deps}
			);
			fileSystemSynchronizedGroups = (
				{i[f'{t}.group']} /* {tname} */,
			);
			name = {tname};
			packageProductDependencies = (
			);
			productName = {tname};
			productReference = {i[f'{t}.product']} /* {product} */;
			productType = "{ptype}";
		}};"""

    def configs(t, tname, settings):
        return "\n".join(
            f"""		{i[f'{t}.{c.lower()}']} /* {c} */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
{settings}
			}};
			name = {c};
		}};"""
            for c in ["Debug", "Release"]
        )

    def config_list(key, owner):
        return f"""		{i[key]} /* Build configuration list for {owner} */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{i[key.replace('list', 'debug')]} /* Debug */,
				{i[key.replace('list', 'release')]} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};"""

    def proxy_and_dep(t):
        return (
            f"""		{i[f'{t}.proxy']} /* PBXContainerItemProxy */ = {{
			isa = PBXContainerItemProxy;
			containerPortal = {i['project']} /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = {i['app']};
			remoteInfo = {name};
		}};""",
            f"""		{i[f'{t}.dep']} /* PBXTargetDependency */ = {{
			isa = PBXTargetDependency;
			target = {i['app']} /* {name} */;
			targetProxy = {i[f'{t}.proxy']} /* PBXContainerItemProxy */;
		}};""",
        )

    ut_proxy, ut_dep = proxy_and_dep("ut")
    ui_proxy, ui_dep = proxy_and_dep("ui")

    return f"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 77;
	objects = {{

/* Begin PBXContainerItemProxy section */
{ut_proxy}
{ui_proxy}
/* End PBXContainerItemProxy section */

/* Begin PBXFileReference section */
		{i['app.product']} /* {name}.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {name}.app; sourceTree = BUILT_PRODUCTS_DIR; }};
		{i['ut.product']} /* {name}Tests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = {name}Tests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};
		{i['ui.product']} /* {name}UITests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = {name}UITests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};
/* End PBXFileReference section */

/* Begin PBXFileSystemSynchronizedRootGroup section */
		{i['app.group']} /* {name} */ = {{
			isa = PBXFileSystemSynchronizedRootGroup;
			path = {name};
			sourceTree = "<group>";
		}};
		{i['ut.group']} /* {name}Tests */ = {{
			isa = PBXFileSystemSynchronizedRootGroup;
			path = {name}Tests;
			sourceTree = "<group>";
		}};
		{i['ui.group']} /* {name}UITests */ = {{
			isa = PBXFileSystemSynchronizedRootGroup;
			path = {name}UITests;
			sourceTree = "<group>";
		}};
/* End PBXFileSystemSynchronizedRootGroup section */

/* Begin PBXFrameworksBuildPhase section */
{phases("app")}
{phases("ut")}
{phases("ui")}
/* End build phase sections */

/* Begin PBXGroup section */
		{i['main']} = {{
			isa = PBXGroup;
			children = (
				{i['app.group']} /* {name} */,
				{i['ut.group']} /* {name}Tests */,
				{i['ui.group']} /* {name}UITests */,
				{i['products']} /* Products */,
			);
			sourceTree = "<group>";
		}};
		{i['products']} /* Products */ = {{
			isa = PBXGroup;
			children = (
				{i['app.product']} /* {name}.app */,
				{i['ut.product']} /* {name}Tests.xctest */,
				{i['ui.product']} /* {name}UITests.xctest */,
			);
			name = Products;
			sourceTree = "<group>";
		}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
{target("app", name, "com.apple.product-type.application", f"{name}.app", False)}
{target("ut", f"{name}Tests", "com.apple.product-type.bundle.unit-test", f"{name}Tests.xctest", True)}
{target("ui", f"{name}UITests", "com.apple.product-type.bundle.ui-testing", f"{name}UITests.xctest", True)}
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		{i['project']} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 2700;
				LastUpgradeCheck = 2700;
				TargetAttributes = {{
					{i['app']} = {{
						CreatedOnToolsVersion = 27.0;
					}};
					{i['ut']} = {{
						CreatedOnToolsVersion = 27.0;
						TestTargetID = {i['app']};
					}};
					{i['ui']} = {{
						CreatedOnToolsVersion = 27.0;
						TestTargetID = {i['app']};
					}};
				}};
			}};
			buildConfigurationList = {i['projlist']} /* Build configuration list for PBXProject "{name}" */;
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = {i['main']};
			minimizedProjectReferenceProxies = 1;
			preferredProjectObjectVersion = 77;
			productRefGroup = {i['products']} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{i['app']} /* {name} */,
				{i['ut']} /* {name}Tests */,
				{i['ui']} /* {name}UITests */,
			);
		}};
/* End PBXProject section */

/* Begin PBXTargetDependency section */
{ut_dep}
{ui_dep}
/* End PBXTargetDependency section */

/* Begin XCBuildConfiguration section */
		{i['projdebug']} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
{project_debug}
			}};
			name = Debug;
		}};
		{i['projrelease']} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
{project_release}
			}};
			name = Release;
		}};
{configs("app", name, app_settings)}
{configs("ut", f"{name}Tests", ut_settings)}
{configs("ui", f"{name}UITests", ui_settings)}
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
{config_list("projlist", f'PBXProject "{name}"')}
{config_list("app.list", f'PBXNativeTarget "{name}"')}
{config_list("ut.list", f'PBXNativeTarget "{name}Tests"')}
{config_list("ui.list", f'PBXNativeTarget "{name}UITests"')}
/* End XCConfigurationList section */
	}};
	rootObject = {i['project']} /* Project object */;
}}
"""


def scheme(name):
    def ref(key, product, blueprint):
        return f"""<BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{uid(name, key)}"
               BuildableName = "{product}"
               BlueprintName = "{blueprint}"
               ReferencedContainer = "container:{name}.xcodeproj">
            </BuildableReference>"""

    app = ref("app", f"{name}.app", name)
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "2700"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            {app}
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
         <TestableReference
            skipped = "NO"
            parallelizable = "YES">
            {ref("ut", f"{name}Tests.xctest", f"{name}Tests")}
         </TestableReference>
         <TestableReference
            skipped = "NO"
            parallelizable = "NO">
            {ref("ui", f"{name}UITests.xctest", f"{name}UITests")}
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         {app}
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         {app}
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""


def write(path, text, overwrite=True):
    if path.exists() and not overwrite:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)


def skeleton(base, name, display, color):
    """Starter sources. Never overwrites files that already exist."""
    src, tests, uitests = base / name, base / f"{name}Tests", base / f"{name}UITests"
    write(src / f"{name}App.swift", f"""import SwiftUI

@main
struct {name}App: App {{
    var body: some Scene {{
        WindowGroup {{
            ContentView()
        }}
    }}
}}
""", overwrite=False)
    write(src / "ContentView.swift", f"""import SwiftUI

struct ContentView: View {{
    var body: some View {{
        NavigationStack {{
            ContentUnavailableView("Welcome to {display}", systemImage: "sparkles")
                .navigationTitle("{display}")
        }}
    }}
}}

#Preview {{
    ContentView()
}}
""", overwrite=False)
    write(tests / f"{name}Tests.swift", f"""import Testing
@testable import {name}

struct {name}Tests {{
    @Test func example() {{
        #expect(true)
    }}
}}
""", overwrite=False)
    write(uitests / f"{name}UITests.swift", f"""import XCTest

final class {name}UITests: XCTestCase {{
    func testLaunches() {{
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.navigationBars["{display}"].waitForExistence(timeout: 5))
    }}
}}
""", overwrite=False)

    write(base / "CLAUDE.md", f"""# {display}

An iOS app built with the easy-ios defaults. Follow these conventions rather
than introducing new libraries or patterns.

- **UI:** SwiftUI only. Minimum iOS 17; don't use newer APIs without `if #available`.
- **State:** MV with `@Observable` models. Views read models directly; no view models
  unless a screen has logic worth unit testing on its own.
- **Storage:** SwiftData (`@Model`, `@Query`). Store enums as raw values so `#Predicate` works.
- **Networking:** `URLSession` with async/await. No third-party networking libraries.
- **Concurrency:** Swift 6, app target defaults to `@MainActor` isolation. Mark pure value
  types (structs/enums with logic but no UI) `nonisolated` so `@Model` classes and tests can use them.
- **Dependencies:** Swift Package Manager only, and only when Apple's frameworks can't do it.
- **Tests:** Swift Testing in `{name}Tests` for logic; XCUITest in `{name}UITests` for one
  happy-path flow per main feature. UI tests launch with `-ui-testing`, which uses an
  in-memory store.
- **Text:** user-facing strings go through String Catalogs (`Localizable.xcstrings`).
- **Icons:** SF Symbols.

Files added to `{name}/`, `{name}Tests/`, or `{name}UITests/` are picked up by Xcode
automatically; there's no need to edit the project file.

Run the tests: `make test APP=<path to this folder>` from the easy-ios repo root.
""", overwrite=False)

    assets = src / "Assets.xcassets"
    write(assets / "Contents.json", json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2) + "\n")
    r, g, b = (int(color[k:k + 2], 16) / 255 for k in (0, 2, 4))
    write(assets / "AccentColor.colorset" / "Contents.json", json.dumps({
        "colors": [{"color": {"color-space": "srgb", "components": {
            "alpha": "1.000", "red": f"{r:.3f}", "green": f"{g:.3f}", "blue": f"{b:.3f}"}}, "idiom": "universal"}],
        "info": {"author": "xcode", "version": 1},
    }, indent=2) + "\n")
    write(assets / "AppIcon.appiconset" / "Contents.json", json.dumps({
        "images": [{"filename": "AppIcon.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}],
        "info": {"author": "xcode", "version": 1},
    }, indent=2) + "\n")
    write(src / "Localizable.xcstrings",
          json.dumps({"sourceLanguage": "en", "strings": {}, "version": "1.0"}, indent=2) + "\n", overwrite=False)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("name", help="App and target name, e.g. Tasks (letters and digits only)")
    p.add_argument("--display", help="Name shown on the home screen (default: name)")
    p.add_argument("--category", required=True, choices=CATEGORIES, help="App Store category")
    p.add_argument("--symbol", default="app", help="SF Symbol for the generated icon")
    p.add_argument("--color", default="0A84FF", help="Accent and icon color as hex, e.g. 0A84FF")
    p.add_argument("--dir", default="apps", help="Parent directory (default: apps)")
    a = p.parse_args()

    if not re.fullmatch(r"[A-Z][A-Za-z0-9]*", a.name):
        sys.exit("name must start with a capital letter and contain only letters and digits")
    if not re.fullmatch(r"[0-9A-Fa-f]{6}", a.color):
        sys.exit("color must be 6 hex digits, e.g. 0A84FF")
    display = a.display or a.name

    base = ROOT / a.dir / a.name
    proj = base / f"{a.name}.xcodeproj"
    write(proj / "project.pbxproj", pbxproj(a.name, display, a.category))
    write(proj / "xcshareddata" / "xcschemes" / f"{a.name}.xcscheme", scheme(a.name))
    skeleton(base, a.name, display, a.color)

    icon = base / a.name / "Assets.xcassets" / "AppIcon.appiconset" / "AppIcon.png"
    subprocess.run(["swift", str(ROOT / "scripts" / "make_icon.swift"), a.symbol, a.color, str(icon)], check=True)

    def shown(path):
        return path.relative_to(ROOT) if path.is_relative_to(ROOT) else path

    print(f"Created {shown(base)}. Open {shown(proj)} in Xcode, or run:")
    print(f"  make test APP={shown(base)}")


if __name__ == "__main__":
    main()
