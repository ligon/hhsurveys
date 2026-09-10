# Workshop notebooks

Notebooks are added here before each session. On the workshop hub, use the
"Get the materials" link on the website — it pulls this folder into your
account and merges later updates without overwriting your own work.

Each notebook records the kernel it needs, and JupyterLab picks it when you
open the file. Most run on the default **Python 3** kernel (the released
`lsms_library`). Session 2 and its four food exercises open on **Python 3
(LSMS dev …)**, the library's development branch, which has the Lorenz
curve function and data fixes the release lacks; if a notebook shows the
wrong kernel in its top-right corner, click it and choose the one the
notebook names.

## Start here

**1. `jupyter_basics.ipynb`** — ten minutes on the notebook itself: what a
cell is, how to run one, why the order you run them in matters, and how to
get help without leaving the page. Read this first even if you have written
Python before; it is about the tool, not the language.

**2. Then one of these**, whichever fits — same material, twenty minutes,
different explanations:

- `python_from_stata.ipynb` — if you have used Stata. Explains each idea by
  what it corresponds to in Stata, and where the obvious translation goes
  quietly wrong.
- `python_from_scratch.ipynb` — if you have not. The same ground, built up
  from the beginning without assuming the comparison.

None of the three is required to follow the sessions, but they will make
them easier.

## Session notebooks

`session1.ipynb` through `session5.ipynb`, one per meeting. Each follows the
slides projected in the room, so the headings match and you can find your
place.

The notebooks read pre-built extracts from `/srv/data/extracts` on the hub
(linked as `~/extracts` in your account) rather than downloading survey data
themselves, which is why they start quickly.

## Exercises

`glss7_sample_design.ipynb` — a longer piece of work on the sample design of
the Ghana Living Standards Survey: reading a stratified two-stage design out
of the weights it produced, and what goes wrong when you ignore it.

Three shorter ones from session 2, all on Ghana 2016-17:

- `food_sources.ipynb` — own production is about 29% of the value of food
  and reaches the aggregate only if you value it; the multiplication nobody
  performed, and whether the pattern holds in other countries.
- `recall_and_diaries.ipynb` — the first of GLSS7's six food visits records
  20% more than the others; what that is, and what to do with it.
- `price_sources.ipynb` — the three price sources GLSS7 actually has, and
  what the survey's own valuation question turns out to measure.

Three more from the end of session 2, each scaffolding one of the deck's
closing exercises:

- `equivalence_scales.ipynb` — vary theta in C/A^theta and watch the
  regional ranking; what moves is mostly the line, not the welfare.
- `spatial_deflation.ipynb` — a regional Paasche index from the survey's own
  unit values, and how much of the north–south gradient survives it (most).
- `poverty_line.ipynb` — a food bundle from the second and third deciles,
  priced and scaled to 2,900 kcal per adult equivalent.

## Licence

CC BY-NC-SA 4.0 — see `LICENSE`. The survey microdata is not covered; see
the workshop site.
