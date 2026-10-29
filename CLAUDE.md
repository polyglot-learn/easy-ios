# easy-ios

A catalog of iOS development decisions, each limited to 2–3 options with a free,
beginner-friendly default. A questionnaire and an app template will be built on
top of it.

## Rules when editing `catalog/`

- Follow `catalog/SCHEMA.md`. Run `make validate` after every change; it must
  pass with no errors.
- Never add a 4th option. To add one, replace the weakest existing option.
- The default must stay free and beginner-level. Don't make a paid or
  free-tier service the default.
- If a decision has one clearly right answer, move it to `catalog/fixed.yaml`
  instead of keeping it as a question.
- Pricing and free-tier limits change. When you edit a `cost_note`, check the
  vendor's own pricing page and set `last_verified` to that day. Don't set
  `last_verified` without checking.
- Keep `why` and `pick_when` short and readable by a beginner.
- The YAML files are the source of truth. Update the README tables to match
  when you change a name, a default, or an option list.
