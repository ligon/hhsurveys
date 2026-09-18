# Analysis of Household Surveys

A six-session workshop for PhD students and junior faculty, Department of
Economics, University of Ghana, taught in September 2026 and hosted by the
IGC and STEG.

The workshop teaches the analysis of household survey data end to end —
from raw survey files to a reproducible result — working in Python with
Ghana's Living Standards Surveys and the LSMS-ISA panels.

**Website:** https://hhsurveys-workshop.ligonresearch.org

The shared workshop hub closes at the end of September 2026. The notebooks
are ordinary Jupyter notebooks and run anywhere `LSMS_Library` is
installed; see the [installation
instructions](https://hhsurveys-workshop.ligonresearch.org/install.html).

## Layout

- `docs/` — the workshop website (GitHub Pages)
- `notebooks/` — session notebooks, delivered to the hub via nbgitpuller

## A note on data

This repository contains **no survey data**. The underlying microdata
belongs to the national statistics offices and the World Bank, and its
terms do not permit redistribution. During the workshop, derived extracts
were staged on the hub at `/srv/data/extracts`; installed locally, the
library fetches what it needs itself. Please keep it that way —
`.gitignore` is set up to help.

## Reference

Angus Deaton, *The Analysis of Household Surveys: A Microeconometric
Approach to Development Policy* (Johns Hopkins, 1997). The World Bank's
2018 reissue is open access:
https://documents.worldbank.org/curated/en/203811547671768139/pdf/133790-PUB.pdf
