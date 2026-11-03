# Exercise 1 — Traditional vs ontology access

**Time:** 10 minutes · **Groups:** 3–4 people · **No keyboard, no data to load**

> The instructor runs this exercise from the slides (Module 1, Exercise 1). This page is
> the same content as a printable or take-home handout.

This is a paper exercise. The five records below are a tiny made-up example (from the
slides), so nothing is stored in a database. You meet the same pattern with real names
in Lab 3, where the workshop data lives in `SC360_L0` and `SC360_EXT`.

Keep your completed worksheet: it becomes your **checklist for Lab 3**.

---

## The question

> **Factory F1 closes. Which customer orders are at risk, and can C18 replace C17?**

**Key:** `F1` = factory · `C17` = component that F1 makes · `C18` = candidate alternate
component · `M4` = module (sub-assembly) · `P9` = finished product · `V204` = vendor ID

## The records (as five teams hold them today)

| Team | Record |
|---|---|
| Procurement | Vendor `V204` is named "B Ltd". Factory `F1` supplies component `C17` |
| Engineering | `C17` is used in module `M4`. `M4` is used in product `P9` |
| Sales | Open customer orders exist for product `P9` |
| Quality | `C18`: qualified as a substitute for `C17` = **Y**, quality score = **89** |
| Slide deck | *"An alternate must be qualified and score at least 90."* |

---

## Step 1 (2 minutes): answer the question

Using only the records above, answer two questions. Circle one answer for each.

- **Q1.** Are any open customer orders at risk if `F1` closes? **Yes / No**
  If yes, for which product? ________
- **Q2.** Can `C18` replace `C17`? **Eligible / Blocked / Not enough evidence**

## Step 2 (5 minutes): tick the type of each piece of meaning

To get that answer, an analyst must *know* each statement below. None is written in a
single record. Tick one box per row.

- **Identity:** two names refer to the same thing.
- **Relationship:** how things connect.
- **Policy:** a rule that turns facts into a decision.

| # | What the analyst must know | Identity | Relationship | Policy |
|---|---|:-:|:-:|:-:|
| 1 | "B Ltd" and `V204` are the same supplier | ☐ | ☐ | ☐ |
| 2 | `C17` is a component, `M4` a module, `P9` a product | ☐ | ☐ | ☐ |
| 3 | `F1` supplies `C17` | ☐ | ☐ | ☐ |
| 4 | `C17` is part of `M4`, and `M4` is part of `P9` | ☐ | ☐ | ☐ |
| 5 | "Part of" chains up: `C17` is inside `P9` too | ☐ | ☐ | ☐ |
| 6 | "At risk" means open orders not yet shipped | ☐ | ☐ | ☐ |
| 7 | `C18` is a qualified substitute for `C17` | ☐ | ☐ | ☐ |
| 8 | The quality bar is 90 | ☐ | ☐ | ☐ |
| 9 | Qualified and ≥ 90 → eligible; < 90 → blocked; no data → review | ☐ | ☐ | ☐ |

**Bonus:** circle the one row a new analyst is most likely to get wrong.

## Debrief (3 minutes)

The instructor shows the answers. Where would you declare each row **once**, so every
team, BI tool and AI agent gets the same answer?
