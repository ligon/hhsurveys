# Workshop notebooks

Sixteen notebooks: six sessions, three tutorials, and seven exercises.
They are ordinary Jupyter notebooks and run anywhere the software is
installed — see the [installation
instructions](https://hhsurveys-workshop.ligonresearch.org/install.html).
Sessions 4 to 6 also import `datamat`, which is not pulled in as a
dependency of `LSMS_Library`, so install it alongside:

    pip install LSMS_Library datamat jupyterlab

The workshop was taught against `LSMS_Library` 0.14.0 and `CFEDemands`
0.10.0. On the workshop hub, run everything with the default **Python 3**
kernel; the hub closes at the end of September 2026.

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

`session1.ipynb` through `session6.ipynb`, one per meeting. Each follows the
slides projected in the room, so the headings match and you can find your
place. The sixth is online and asynchronous: frontiers, and the capstone.

1. `session1.ipynb` — design, sampling, and collection
2. `session2.ipynb` — describing welfare (theory; almost no computation)
3. `session3.ipynb` — elicitation of consumption and survey design
4. `session4.ipynb` — demand and welfare
5. `session5.ipynb` — from cross-sections to panels
6. `session6.ipynb` — capstone and frontiers

On the hub a few of them read pre-built extracts from `/srv/data/extracts`
(linked as `~/extracts`) rather than downloading survey data themselves,
which is why they start quickly. Installed locally, `LSMS_Library` fetches
what it needs itself.

## Exercises

`glss7_sample_design.ipynb` — a longer piece of work on the sample design of
the Ghana Living Standards Survey: reading a stratified two-stage design out
of the weights it produced, and what goes wrong when you ignore it.

Three shorter ones from session 3, all on Ghana 2016-17:

- `food_sources.ipynb` — own production is about 29% of the value of food
  and reaches the aggregate only if you value it; the multiplication nobody
  performed, and whether the pattern holds in other countries.
- `recall_and_diaries.ipynb` — the first of GLSS7's six food visits records
  20% more than the others; what that is, and what to do with it.
- `price_sources.ipynb` — the three price sources GLSS7 actually has, and
  what the survey's own valuation question turns out to measure.

Three more from the end of session 3, each scaffolding one of the deck's
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
