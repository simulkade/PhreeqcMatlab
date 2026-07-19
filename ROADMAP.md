# PhreeqcMatlab — Refactoring & Continuation Roadmap

Status of the codebase at time of writing: development peaked in 2021 and tapered to a
last commit in April 2024. Layer 1 (the FFI wrappers) is mature; Layer 2 (orchestration)
is partial; Layer 3 (the object model) stalled roughly one-third complete and internally
inconsistent. This document is the plan to stabilize, refactor, and continue the work.

## Decisions locked in

- **Native libraries: bump to PhreeqcRM/IPhreeqc `3.8.6-17100`.** Compiled binaries are
  installed at `/usr/local/lib` (`libphreeqcrm-3.8.6.so`, `libiphreeqc.so`) with headers in
  `/usr/local/include`, and source tarballs are in `~/download/`. The `simulkade/PhreeqcRM`
  release repo will be updated to 3.8.6 later so `startup.m` can download it.
- **Keep the value-class idiom** (`phrm = phrm.RM_...()`, reassign-or-lose). No migration to
  handle classes. This must be documented loudly and guarded, since it is the #1 footgun.
- **First focus: stabilize the foundation** (Milestone 1) before extending features.

### Version-bump compatibility (already verified)

Symbol-level diff of the current wrapper against the installed `3.8.6` `.so`:

- All **119** currently-wrapped `RM_` functions still exist in 3.8.6 → **no symbol-level breakage**.
- **26** new non-BMI functions available to wrap, notably the per-reactant initializers
  `RM_InitialSolutions2Module`, `RM_InitialEquilibriumPhases2Module`, `RM_InitialExchanges2Module`,
  `RM_InitialSurfaces2Module`, `RM_InitialGasPhases2Module`, `RM_InitialSolidSolutions2Module`,
  `RM_InitialKinetics2Module`, and getters `RM_GetTemperature/GetPressure/GetPorosity/GetViscosity/GetDensityCalculated/GetSaturationCalculated`.
- **53** BMI functions (`BMIPhreeqcRM`) — a standardized Basic Model Interface, available as a
  modern alternative binding path (Milestone 4, optional).

Signature changes are still possible even where names match; they are only provable by running,
which is exactly what the Milestone 1 test harness exists to catch.

---

## Milestone 1 — Stabilize the foundation

Goal: a version-bumped, test-covered, CI-checked, packageable baseline with the known-broken
code either fixed or safely guarded. Nothing here adds user-facing features.

### 1a. Library bump to 3.8.6 — DONE
- [x] Headers: verified the current curated `libs/RM_interface_C.h`/`IPhreeqc.h` are a valid
      **subset** of the 3.8.6 headers — all 119 wrapped functions are byte-for-byte
      signature-compatible (only whitespace differs on 4 density/saturation protos, and their
      old symbols persist in the 3.8.6 `.so`). No wrapper changes needed for the bump.
      New-function prototypes get added to the header in Milestone 4 when those functions are wrapped.
- [x] Rewrote `startup.m`: collapsed the four duplicated download blocks into one
      `ensure_library` helper; added a **local-lib fallback** (`PHREEQCMATLAB_LIB_PATH` →
      `/usr/local/lib`) that copies the installed `.so` into `libs/`; added a
      `libs/.phreeqc_version` stamp so a version bump auto-refreshes; version pinned via
      `*_VERSION` constants.
- [x] Discovered + solved the **libstdc++ / GLIBCXX_3.4.32** issue (MATLAB's bundled libstdc++
      tops out at 3.4.30; the modern-GCC 3.8.6 build needs 3.4.32). Added `run_matlab.sh`
      launcher that sets `LD_PRELOAD` to the system libstdc++, plus a preflight warning in
      `startup.m`.
- [x] Smoke-tested in MATLAB R2026a: `startup` → `loadlibrary` → `RM_LoadDatabase` →
      `RM_RunString` → `RM_FindComponents` returns correct components end to end.
- [ ] TODO (deferred): checksum verification of downloaded binaries — deferred until the
      `simulkade/PhreeqcRM` release is updated to 3.8.6 (the download path isn't exercised yet).

### 1b. Fix the known-broken code (audit findings) — DONE
- [x] `@SingleCellResult/SingleCellResult.m` — renamed classdef `SingleCellResults` → matching
      `SingleCellResult`; rewrote as a minimal loadable placeholder (full fields in M3).
- [x] `@Phase/Phase.m:49` — `phase string` → `phase_string`; also corrected the keyword to the
      plural PHREEQC `EQUILIBRIUM_PHASES`.
- [x] `@Phase/Phase.m:114-118` — `selected_output_object()` now writes `content(1..4)` so all
      four lines survive.
- [x] `@Phase/Phase.m:274-277` — `read_json()` now populates `phase_names` (and matching `moles`)
      instead of the nonexistent `components`.
- [x] `@Gas/Gas.m:41` — wrapped `partial_pressure(i)` in `num2str`; guarded the empty-`pressure`
      case and put each GAS_PHASE identifier on its own line.
- [x] `PhreeqcSingleCell.m` and `@SingleCell/SingleCell.m` — removed the redundant `RM_Create()`.
- [x] Broad `catch` in `run()/run_in_phreeqc()/equilibrate_in_phreeqc()` (Solution.m, Phase.m,
      Surface.m) — now surfaces the real `ME.message` via a `PhreeqcMatlab:runFailed` warning
      instead of a generic line. (Full type-stable return-contract redesign deferred to M2.)
- [x] Removed the template-boilerplate `method1`/`Property1` from `@Exchange`, `@Kinetics`,
      `@PhaseResult`, `@SingleCellResult` so the classes load cleanly.
- Verified in MATLAB R2026a: all touched classes construct; `Phase`/`Gas` `phreeqc_string`,
  `Phase.read_json`, and the result classes work; **all 4 demo tests (SimpleAdvect, Advect,
  Species, Gas_m) pass** against 3.8.6.
- [ ] Deferred to M3: `@SingleCell.run()` (undefined `iph_string`, ignores `varargin`) — left
      non-functional for now; it is completed as part of the M3 object-model work.

### 1c. Test harness — DONE
- [x] Added `tests/PhreeqcMatlabTest.m` (`matlab.unittest`) with **physically-grounded** golden
      values: pure-water pH=7 & μ≈1e-7 (IPhreeqc); gypsum SI=0 / anhydrite SI≈−0.30 at 25 °C
      (IPhreeqc); gypsum solubility Ca=S≈15 mmol/L + component set (`PhreeqcSingleCell`); and a
      deterministic `Solution.phreeqc_string()` well-formedness check. Fixture:
      `tests/fixtures/gypsum_anhydrite.pqc`.
- [x] Single entry point `tests/run_all_tests.m` (`runtests` + errors on any failure, for CI).
      **All 4 tests pass** against 3.8.6.
- [x] The demo scripts (`SimpleAdvect`, `Advect`, `Species`, `Gas_m`) remain as examples;
      `runtests` ignores them (not test classes).
- Findings for M2 (robustness): `GetConcentrations` **segfaults** if called before the module is
  initialized (`RM_InitialPhreeqc2Module` + `RM_RunCells`) — the wrapper should guard the
  precondition rather than pass an unbacked buffer to the native side. Also `GetComponents`
  returns a column cell array (orientation matters for callers).

### 1d. Packaging — DONE
- [x] `package_toolbox.m` builds `PhreeqcMatlab.mltbx` via `matlab.addons.toolbox.ToolboxOptions`
      (no hand-written `.prj` needed). Validated locally: 3.8 MB, ships source + databases + C
      headers + tests + examples; native binaries are fetched by `startup.m`, not bundled.
- [x] `CHANGELOG.md` added (Keep-a-Changelog style).
- CI (GitHub Actions) intentionally dropped per maintainer preference; tests are run locally via
  `./run_matlab.sh -batch "addpath('tests'); run_all_tests"`.

---

## Milestone 2 — Refactor the object model core (Layer 3)

Goal: make Layer 3 consistent and robust so the remaining classes can be completed cheaply.
This is the highest-leverage refactor; do it before finishing individual classes.

- [ ] **Abstract `Reactant` base class.** Enforce common fields (`name`, `number`), an abstract
      `phreeqc_string()`, a shared `equilibrate_with(solution)` template, and a uniform
      `read_json(struct)` contract. `Solution`, `Phase`, `Surface`, `Gas`, `Exchange`,
      `Kinetics` become subclasses that only fill in their block-specific pieces.
- [ ] **Unify the run/equilibrate verb.** Today `Solution` uses `run()` while `Surface/Phase/Gas`
      use `equilibrate_with()`. Pick one contract on the base class so reactants are polymorphic.
- [ ] **Shared string-builder utility.** Replace the fragile nested
      `strjoin(...)/sprintf(char(...))` pattern (used in every `phreeqc_string()`) with a helper
      that: suppresses empty/unspecified fields (fixes Solution.m:55 "not smart enough" note and
      the `pe  \n` / `density  \n` malformed lines), formats numbers via `num2str` consistently,
      and controls spacing deterministically.
- [ ] **Centralize the initial-condition vector.** The hardcoded 7-slot `ic1` vector is
      duplicated across `Solution.m:188`, `Surface.m:238`, `SingleCell.m:65`,
      `PhreeqcSingleCell.m:45`, `InitializePhreeqcAdvection.m:44`, `InitializePhreeqcFVTool.m:45`.
      Replace with either (a) a single helper that maps reactant type → slot, or preferably
      (b) the new per-reactant `RM_Initial*2Module` functions from 3.8.6, so each reactant
      registers itself.
- [ ] **Robust result parsing.** Replace hardcoded PHREEQC column-header keys
      (Solution.m:205-229) and positional column arithmetic (Surface.m:262-288) with a
      header→field mapping layer that validates presence and fails loudly. Use the new
      `RM_GetTemperature/GetPressure/GetViscosity/GetDensityCalculated` getters where they
      replace scraped `SELECTED_OUTPUT` columns.
- [ ] **Enum classes: use or lose.** `src/classes/@solution_units`, `@phase_units`,
      `@exchange_units`, `@kinetics_units`, `@sites_units`, `@edl_layer` are dead code (typed
      properties use plain `string`). Either wire them into the property type declarations for
      validation, or delete them.
- [ ] **Unify JSON.** One reusable decode/validate helper instead of per-class `isfield` ladders;
      fold the duplicated `Tools/read_json_ex.m` (a verbatim copy of `Solution.read_json`, with a
      hardcoded Windows path) into it; add `write_json` for round-tripping; define a schema.
      Fill the empty `Dan`/`HDan`/`Kraka` stubs in `database/solutions.json` or remove them.

---

## Milestone 3 — Complete the stubbed classes

Goal: bring the half-built classes up to the `Solution`/`Surface` standard, on the M2 base class.

- [ ] `@Exchange` — real properties (master species, exchange reactions, `log_k`, `dh`),
      `phreeqc_string()`, `read_json()`, `equilibrate_with()`. Add `database/exchange.json`.
- [ ] `@Kinetics` — add reaction/rate fields (rate name, formula, parameters, steps, `-m0`, etc.),
      `phreeqc_string()`, `read_json()`. Add `database/kinetics.json`.
- [ ] `@Gas` — finish `equilibrate_in_phreeqc()`/`equilibrate_with()` (currently empty), add
      `read_json()` and move hardcoded `damp_CO2()/flue_gas()` definitions into JSON.
- [ ] `@Phase` — finish `equilibrate_with()` (empty stub) and `combine_selected_output()` (`% TBD`).
- [ ] `@SingleCell.run()` — implement properly: build the combined phreeqc string from all
      contained reactants, register initial conditions, `RM_RunCells`, and return a populated
      `SingleCellResult`. Fix the constructor to consume `varargin` (the reactant fields).
- [ ] Result classes `@PhaseResult`, `@SingleCellResult` — real parsed-output structures matching
      `@SolutionResult`/`@SurfaceResult`.

---

## Milestone 4 — Continue & extend

- [ ] Wrap the 26 new non-BMI 3.8.6 functions (getters + per-reactant initializers) in `@PhreeqcRM`.
- [ ] **Finish multi-D reactive transport.** `FVTool/InitializePhreeqcFVTool.m` is marked
      "NOT DONE YET!"; complete it and the `.pqm` custom-input parser (the FVTool + PhreeqcMatlab
      link format sampled in `sample_initialize_fvtool.pqm`). Add a 2D benchmark with a known
      solution. Document the external FVTool dependency and guard for its absence.
- [ ] **(Optional) BMI binding path.** Evaluate wrapping `BMIPhreeqcRM` (53 functions) as a
      modern, standardized alternative to the `RM_` C interface.

---

## Milestone 5 — Documentation

Woven throughout, consolidated here:

- [ ] Loudly document the value-class reassign-or-lose idiom and the explicit-destroy requirement
      (top-level README + class headers).
- [ ] API reference (from doc-comments), expanded examples, and a contributor guide.
- [ ] Keep `CLAUDE.md` current as the architecture evolves (base class, JSON path, lib version).
- [ ] Migrate/expand the GitHub wiki content that the README points at.

---

## Suggested sequencing

1. **M1a + M1b** first (bump + fixes) — small, high-confidence, unblocks a trustworthy baseline.
2. **M1c** (tests) immediately after — locks the baseline and validates the bump.
3. **M1d** (CI/packaging) — automates the gate.
4. **M2** (object-model core refactor) — the pivot that makes M3 cheap.
5. **M3** (complete classes), then **M4** (new features / transport), with **M5** continuous.
