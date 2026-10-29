# easy-ios

Build an iOS app with as few decisions as possible.

iOS development is hard less because of Swift and more because of the choices
around it: project setup, architecture, storage, signing, CI, analytics, and so
on. Each choice has many "right" answers. This repo makes those choices small.

## The rules

1. **At most 2 options per decision, 3 only when the use cases are truly different.**
2. **The default is always free and beginner-friendly.** Accept every default and
   you get a working app with no paid services.
3. **Every alternative says when to pick it.** Advanced users can swap in what
   they need without reading a comparison blog post.
4. **If one answer is clearly right, it is not a question.** It goes into the
   fixed defaults instead.

These rules are enforced by `make validate`, not just written down.

## What it costs

| Goal | Cost |
|---|---|
| Build and run in the Simulator | Free |
| Run on your own iPhone | Free (with a free Apple ID; the app must be reinstalled every 7 days) |
| TestFlight, App Store, push notifications, in-app purchases | Apple Developer Program, **$99/year** |

Nothing in this repo removes the $99/year requirement for shipping. Everything
else on the default path is free.

## The catalog

`catalog/` holds every decision as a YAML file. It's data, not prose, so the
questionnaire (coming next) and any tooling can be generated from it.

- `catalog/fixed.yaml`: things that are decided for you, with the reason why.
- `catalog/<decision>.yaml`: one file per decision, with 2–3 options.
- `catalog/SCHEMA.md`: the format and the rules each file must follow.

### Fixed defaults

| Area | Choice |
|---|---|
| Package manager | Swift Package Manager |
| Unit tests | Swift Testing |
| UI tests | XCUITest |
| Localization | String Catalogs |
| Icons | SF Symbols |
| AI conventions | `CLAUDE.md` / `AGENTS.md` in the generated app |

### Decisions

| # | Decision | Default (free) | Alternatives |
|---|---|---|---|
| 1 | UI framework | SwiftUI | UIKit |
| 2 | Minimum iOS | iOS 17 | Latest iOS only |
| 3 | Project setup | Plain Xcode project | XcodeGen · Tuist |
| 4 | Architecture | MV with `@Observable` | MVVM · TCA |
| 5 | Local storage | SwiftData | GRDB (SQLite) |
| 6 | Backend / sync | None (local only) | CloudKit · Supabase |
| 7 | User accounts | No accounts | Sign in with Apple · Supabase Auth |
| 8 | Networking | URLSession + async/await | Alamofire |
| 9 | Lint / format | swift-format | SwiftLint + SwiftFormat |
| 10 | CI | None (build locally) | Xcode Cloud · GitHub Actions |
| 11 | Release / signing | Xcode automatic signing | Fastlane |
| 12 | Crashes / analytics | Xcode Organizer | Firebase Crashlytics · TelemetryDeck |
| 13 | In-app purchases | StoreKit 2 | RevenueCat |
| 14 | Push notifications | APNs directly | Firebase Cloud Messaging |

The YAML files are the source of truth. If this table and a YAML file disagree,
the YAML wins.

## Contributing

```sh
pip install pyyaml   # once
make validate
```

The validator fails on rule violations, for example a 4th option, a paid
default, or an option that depends on a choice that doesn't exist. It warns
when pricing information hasn't been verified, or was verified more than 180
days ago.

`make check-links` checks that every link in the catalog still loads. CI runs
it weekly.

## Roadmap

- [x] Decision catalog
- [ ] Questionnaire (beginner path: accept all defaults; advanced path: ask everything)
- [ ] App template generated from the answers
- [ ] `make new`, `make run`, `make test`, `make ship`
