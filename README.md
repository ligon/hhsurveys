# Analysis of Household Surveys

A five-session workshop for PhD students and junior faculty, Department of
Economics, University of Ghana.

The workshop teaches the analysis of household survey data end to end —
from raw survey files to a reproducible result — working in Python with
Ghana's Living Standards Surveys and the LSMS-ISA panels.

**Website:** https://ligon.github.io/hhsurveys/
**Workshop hub:** https://hhsurveys.ligonresearch.org

## Layout

- `docs/` — the workshop website (GitHub Pages)
- `notebooks/` — session notebooks, delivered to the hub via nbgitpuller

## A note on data

This repository contains **no survey data**. The underlying microdata
belongs to the national statistics offices and the World Bank, and its
terms do not permit redistribution. Derived extracts are staged on the
workshop hub at `/srv/data/extracts` and are read from there by the
notebooks. Please keep it that way — `.gitignore` is set up to help.

## Reference

Angus Deaton, *The Analysis of Household Surveys: A Microeconometric
Approach to Development Policy* (Johns Hopkins, 1997). The World Bank's
2018 reissue is open access:
https://documents.worldbank.org/curated/en/203811547671768139/pdf/133790-PUB.pdf
