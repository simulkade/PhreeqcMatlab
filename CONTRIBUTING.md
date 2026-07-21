# Contributing to PhreeqcMatlab

Contributions and suggestions are very welcome. This guide covers the setup, the
coding conventions, and the common "how do I add …" tasks.

## Setup & running

1. Clone the repo and **run `startup.m` first** in every MATLAB session — it
   sets the path and ensures the native libraries are in `libs/` (pinned to
   PhreeqcRM / IPhreeqc **3.8.6**).
2. **On Linux, launch MATLAB via [`./run_matlab.sh`](run_matlab.sh)** so the
   `LD_PRELOAD` workaround for `GLIBCXX_3.4.32` is applied — otherwise
   `loadlibrary` fails. See [README](README.md#installation) for details.
3. See [`docs/architecture.md`](docs/architecture.md) for the layer map.

## Running the tests

The assertion suite is the regression gate; run it before opening a PR:

```bash
./run_matlab.sh -batch "addpath('tests'); run_all_tests"   # errors on any failure
```

`tests/PhreeqcMatlabTest.m` is a `matlab.unittest` suite with **physically
grounded golden values** (pure-water pH 7, gypsum SI 0, water viscosity
0.90 mPa·s at 25 °C, …), not arbitrary snapshots — they also act as a
signature-drift gate for future library bumps. Add assertions for new behaviour
here; put fixtures in `tests/fixtures/`.

## Conventions

- **Value classes, reassign-or-lose.** All wrapper classes are value classes.
  A mutating method returns a new object — capture it (`phrm = phrm.RM_…()`) or
  the change is lost. Keep new classes value classes (the whole API and tests
  assume it).
- **Explicit cleanup.** Instances hold native resources; free them with
  `RM_Destroy` / `DestroyIPhreeqc`. Do **not** call `unloadlibrary` — it crashes
  the library (it is deliberately left commented out).
- **The `RM_` naming rule.** A method that maps one-to-one onto an original
  library function keeps its `RM_` prefix (or the original IPhreeqc name) and
  its upstream docstring. A convenience method added by this package **omits**
  the prefix (e.g. `GetConcentrations`). This is how readers tell wrapper from
  original — please preserve it.
- **Build keyword blocks with `PhreeqcBlock`**, not ad-hoc `strjoin`/`sprintf`;
  it handles empty-field suppression and consistent formatting.
- Match the surrounding style: copied C docstrings on `RM_` methods, concise
  help text on convenience methods.

## How to add a wrapper for a new native function

1. Confirm the prototype is in `libs/RM_interface_C.h` (the 3.8.6 header). If
   MATLAB `loadlibrary` doesn't expose it, it isn't in the header MATLAB parses.
2. Add an `RM_`-prefixed method in `src/@PhreeqcRM/PhreeqcRM.m` that is a direct
   `calllib(obj.libName, 'RM_Name', obj.id, …)`. For output-array functions,
   return `[status, out]` and (optionally) add an unprefixed convenience method
   that allocates the array and returns it — see `RM_GetDensity`/`GetDensity`.
3. Add a test that pins a physically sensible value.

> Note: `libs/irm_dll_export.h` is shipped with `IRM_DLL_EXPORT` defined empty.
> Upstream uses `__attribute__((visibility("default")))`, which MATLAB's thunk
> compiler cannot parse. The attribute only matters when *building* the `.so`
> (already built), so do not restore it.

## How to add a definition class / JSON template

- Subclass `@Reactant`; implement `phreeqc_string()`, `ic_slot()`, and (if the
  reactant emits coupled blocks) `input_string()`. `equilibrate_with` is
  inherited — override it only for a richer result type.
- Add a `read_json(struct)` and a `from_json(name [,file])` factory, and a
  template entry in the matching `database/*.json`. Use `assign_json_fields`
  for scalar fields. If composition keys contain characters `jsondecode`
  mangles (e.g. `CO2(g)`), use parallel name/amount arrays instead of a map
  (see `Gas`/`gases.json`).
- Add a string round-trip test (parse through IPhreeqc, assert no `ERROR:`) and,
  where feasible, an equilibration test with a golden value.

See [`docs/object-model.md`](docs/object-model.md) for the full contract.

## Roadmap

Planned work and its status live in [`ROADMAP.md`](ROADMAP.md); notable changes
are recorded in [`CHANGELOG.md`](CHANGELOG.md).
