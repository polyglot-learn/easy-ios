# Catalog schema

## Decision files (`catalog/<id>.yaml`)

```yaml
id: persistence              # must match the filename
order: 5                     # position in the questionnaire, unique
title: Local storage         # short label
question: "Where should the app store data on the device?"
why: "One sentence a beginner can understand about why this matters."
skip_for_beginners: true     # beginners get the default without being asked
note: "Optional. Applies to every option, e.g. a membership requirement."
last_verified: 2026-10-29    # date someone checked the cost/pricing facts, or null
options:
  - id: swiftdata
    name: SwiftData
    default: true            # exactly one option per decision
    cost: free               # free | free-tier | included | paid
    cost_note: "Optional detail, e.g. the free-tier limits."
    level: beginner          # beginner | advanced
    pick_when: "When this option is the right choice."
    tradeoffs: "What you give up."
    url: https://developer.apple.com/documentation/swiftdata
    requires:                # optional: other decisions this option depends on
      backend: [supabase]    # decision id -> allowed option ids
```

### Cost values

| Value | Meaning |
|---|---|
| `free` | No cost at any scale (open source, or built into Apple's tools) |
| `free-tier` | Free up to a limit, then paid |
| `included` | Included with the Apple Developer Program ($99/year), with a usage cap |
| `paid` | Costs money from the start |

## Rules (enforced by `make validate`)

1. A decision has 2 or 3 options.
2. Exactly one option is the default.
3. The default has `cost: free` and `level: beginner`.
4. The defaults work together: accepting every default must satisfy every
   default's `requires`.
5. `requires` refers only to decisions and options that exist.
6. `id` matches the filename; ids and `order` values are unique.
7. Every decision has a `last_verified` field. When any option is not `free`,
   a `null` date or one older than 180 days is a warning, not an error.

## Fixed defaults (`catalog/fixed.yaml`)

A list of entries with `id`, `area`, `choice`, `why`, and an optional `url`.
Something belongs here instead of in a decision when one answer is right for
almost everyone.
