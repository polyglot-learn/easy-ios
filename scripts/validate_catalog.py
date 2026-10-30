#!/usr/bin/env python3
"""Check that catalog/ follows the rules in catalog/SCHEMA.md.

Exits 1 if any rule is broken. Stale or missing pricing dates are warnings.
"""

import datetime
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.exit("PyYAML is required: pip install pyyaml")

CATALOG = Path(__file__).resolve().parent.parent / "catalog"
COSTS = {"free", "free-tier", "included", "paid"}
LEVELS = {"beginner", "advanced"}
DECISION_FIELDS = {"id", "order", "title", "question", "why", "skip_for_beginners", "last_verified", "options"}
OPTION_FIELDS = {"id", "name", "cost", "level", "pick_when", "tradeoffs"}
FIXED_FIELDS = {"id", "area", "choice", "why"}
STALE_AFTER_DAYS = 180

errors = []
warnings = []


def load(path):
    with path.open() as f:
        return yaml.safe_load(f)


def check_fixed(path):
    entries = load(path)
    if not isinstance(entries, list):
        errors.append(f"{path.name}: must be a list")
        return
    seen = set()
    for i, entry in enumerate(entries):
        if not isinstance(entry, dict):
            errors.append(f"{path.name}[{i}]: must be a mapping")
            continue
        missing = FIXED_FIELDS - entry.keys()
        if missing:
            errors.append(f"{path.name}[{i}]: missing {sorted(missing)}")
        if entry.get("id") in seen:
            errors.append(f"{path.name}: duplicate id {entry.get('id')!r}")
        seen.add(entry.get("id"))


def check_decision(path, d):
    name = path.name
    missing = DECISION_FIELDS - d.keys()
    if missing:
        errors.append(f"{name}: missing {sorted(missing)}")
    if d.get("id") != path.stem:
        errors.append(f"{name}: id {d.get('id')!r} must match the filename")

    options = d.get("options") or []
    if not isinstance(options, list) or not all(isinstance(o, dict) for o in options):
        errors.append(f"{name}: options must be a list of mappings")
        d["options"] = options = []
    if not 2 <= len(options) <= 3:
        errors.append(f"{name}: has {len(options)} options; must have 2 or 3")

    option_ids = [o.get("id") for o in options]
    if len(option_ids) != len(set(option_ids)):
        errors.append(f"{name}: duplicate option ids")

    for o in options:
        label = f"{name}/{o.get('id')}"
        missing = OPTION_FIELDS - o.keys()
        if missing:
            errors.append(f"{label}: missing {sorted(missing)}")
        if o.get("cost") not in COSTS:
            errors.append(f"{label}: cost must be one of {sorted(COSTS)}")
        if o.get("level") not in LEVELS:
            errors.append(f"{label}: level must be one of {sorted(LEVELS)}")

    defaults = [o for o in options if o.get("default")]
    if len(defaults) != 1:
        errors.append(f"{name}: has {len(defaults)} defaults; must have exactly 1")
    for o in defaults:
        if o.get("cost") != "free":
            errors.append(f"{name}: default {o.get('id')!r} must be free")
        if o.get("level") != "beginner":
            errors.append(f"{name}: default {o.get('id')!r} must be beginner level")

    if any(o.get("cost") != "free" for o in options):
        verified = d.get("last_verified")
        if verified is None:
            warnings.append(f"{name}: has non-free options but pricing is unverified (last_verified: null)")
        elif not isinstance(verified, datetime.date):
            errors.append(f"{name}: last_verified must be a date (YYYY-MM-DD) or null")
        elif (datetime.date.today() - verified).days > STALE_AFTER_DAYS:
            warnings.append(f"{name}: pricing last verified {verified}, over {STALE_AFTER_DAYS} days ago")


def check_requires(decisions):
    defaults = {
        key: next((o.get("id") for o in d.get("options", []) if o.get("default")), None)
        for key, d in decisions.items()
    }
    for key, d in decisions.items():
        for o in d.get("options", []):
            label = f"{key}.yaml/{o.get('id')}"
            requires = o.get("requires") or {}
            if not isinstance(requires, dict):
                errors.append(f"{label}: requires must map decision ids to lists of option ids")
                continue
            for dep, allowed in requires.items():
                if not isinstance(allowed, list):
                    errors.append(f"{label}: requires.{dep} must be a list of option ids")
                    continue
                if dep not in decisions:
                    errors.append(f"{label}: requires unknown decision {dep!r}")
                    continue
                dep_ids = {x.get("id") for x in decisions[dep].get("options", [])}
                for a in allowed:
                    if a not in dep_ids:
                        errors.append(f"{label}: requires unknown option {dep}/{a}")
                if o.get("default") and defaults[dep] not in allowed:
                    errors.append(
                        f"{label}: default requires {dep} in {allowed}, "
                        f"but that decision's default is {defaults[dep]!r}"
                    )


def main():
    decisions = {}
    orders = {}
    for path in sorted(CATALOG.glob("*.yaml")):
        if path.name == "fixed.yaml":
            check_fixed(path)
            continue
        d = load(path)
        if not isinstance(d, dict):
            errors.append(f"{path.name}: must be a mapping")
            continue
        check_decision(path, d)
        decisions[d.get("id")] = d
        order = d.get("order")
        if order in orders:
            errors.append(f"{path.name}: order {order} already used by {orders[order]}")
        orders[order] = path.name

    check_requires(decisions)

    for w in warnings:
        print(f"warning: {w}")
    for e in errors:
        print(f"error: {e}")
    print(f"{len(decisions)} decisions, {len(errors)} errors, {len(warnings)} warnings")
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
