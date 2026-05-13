# fiscal-free-lunch

Python port of the Dynare simulations.

Golden rule: generated Python CSVs must compare cleanly against Dynare CSVs.

```sh
uv run fiscal-free-lunch run all-figures --output ../../artifacts/python-data
uv run fiscal-free-lunch compare --dynare ../../artifacts/data --python ../../artifacts/python-data
```

Individual runs:

```sh
uv run fiscal-free-lunch run figure-1a
uv run fiscal-free-lunch run figure-1b
uv run fiscal-free-lunch run figure-2 --xip 0.8
uv run fiscal-free-lunch run figure-2 --xip 0.8 --gam-xgap 0.2 --gam-pi 1.5
uv run fiscal-free-lunch run figure-3 --xip 0.75
```
