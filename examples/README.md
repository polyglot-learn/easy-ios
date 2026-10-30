# Example apps

Ten complete apps, one per App Store category, each built with the easy-ios
defaults only: SwiftUI, iOS 17, MV with `@Observable`, SwiftData, URLSession,
a plain Xcode project, Swift Testing and XCUITest. No third-party packages.

They're open-source examples to learn from and copy from. They're not on the
App Store.

| App | Category | What it does | Worth reading for |
|---|---|---|---|
| [Tasks](Tasks) | Productivity | To-dos with due dates, priorities, filters, and search | Filtering and sorting logic kept out of views; `#Predicate` with raw-value enums |
| [Habits](Habits) | Health & Fitness | Daily habits with streaks, a 5-week grid, and a weekly chart | Streak math that survives "haven't checked in yet today"; Swift Charts |
| [Budget](Budget) | Finance | Monthly spending by category against a budget | `Decimal` for money; month summaries and projections; donut chart |
| [Flashcards](Flashcards) | Education | Decks of cards with spaced-repetition study sessions | Leitner scheduling; cascade-deleting relationships |
| [Recipes](Recipes) | Food & Drink | Recipes whose ingredients rescale with servings | Parsing "1 1/2 cups" and "½" and formatting friendly fractions |
| [Mood Journal](MoodJournal) | Lifestyle | Daily entries with a mood, trend chart, and "on this day" | Grouping by month; line chart with custom axis symbols |
| [Packing](Packing) | Travel | Trips with a suggested packing list | Rules that scale a list by trip length, weather, and activities |
| [Converter](Converter) | Utilities | Unit converter for length, weight, temperature, and more | An `@Observable` model without SwiftData; Foundation `Measurement` |
| [Forecast](Forecast) | Weather | City search and 7-day forecasts | `URLSession` networking, decoding real API JSON, caching, swappable service for tests |
| [Headlines](Headlines) | News | Hacker News reader with bookmarks | Parallel fetching with `TaskGroup` that keeps order; pagination; `SFSafariViewController` |

## Run one

Open `examples/<App>/<App>.xcodeproj` in Xcode, choose an iPhone simulator, and press Run.
No account or signing setup is needed for the simulator.

Or run its tests from the repo root:

```sh
make test APP=examples/Tasks
```

`make test-examples` runs all ten.

## How they're tested

- **Unit tests (Swift Testing)** cover the logic: filters, streaks, money math,
  scheduling, parsing, decoding, and caching. Dates and calendars are fixed in
  tests, so results don't depend on today's date or time zone.
- **One UI test per app (XCUITest)** walks through the main flow. Apps launched
  with `-ui-testing` use an in-memory database, and the two networked apps use
  canned responses, so UI tests never touch the network.

## Data sources

- Forecast uses [Open-Meteo](https://open-meteo.com/), which is free for non-commercial
  use without an API key. The app credits it, as its license requires.
- Headlines uses the [official Hacker News API](https://github.com/HackerNews/API).
