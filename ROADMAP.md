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

- [x] **Abstract `Reactant` base class** — DONE. `src/@Reactant/Reactant.m` holds the shared
      `name`/`number` identity, an abstract `phreeqc_string()`, and a concrete `input_string()`
      that returns one assembled Phreeqc string. `Solution`, `Phase`, `Surface`, `Gas`,
      `Exchange`, `Kinetics` now subclass it (name/number removed from each). `Surface` overrides
      `input_string()` to concatenate its three coupled blocks in order. `Exchange`/`Kinetics`
      carry a loud not-implemented `phreeqc_string` (real bodies land in M3) so they stay
      instantiable. Covered by `reactantPolymorphism` (7/7 tests pass).
- [ ] **Unify the run/equilibrate verb.** Today `Solution` uses `run()` while `Surface/Phase/Gas`
      use `equilibrate_with()`. Deferred into M3, where `Exchange`/`Kinetics`/`Gas`/`SingleCell`
      are implemented anyway — a shared `equilibrate_with(solution)` template on `Reactant`
      built on `input_string()` will land with them.
- [x] **Shared string-builder utility** — DONE. Added `src/Tools/PhreeqcBlock.m`, a fluent value
      builder (`kv`/`kvopt`/`flag`/`line`) with empty-field suppression, consistent scalar/vector
      numeric formatting, and deterministic spacing. Refactored `Solution`, `Gas`, `Phase`,
      `Surface` (all 3 sub-blocks), and `SelectedOutput` `phreeqc_string()` onto it; removed the
      `pe  `/`density 0` malformed lines and the fragile `num2str(vector)` calls. Every block
      round-trips through IPhreeqc with no parse error; covered by `stringBuilder` and
      `surfaceStringRoundTrip` tests.
- [x] **Centralize the initial-condition vector** — DONE (approach a). Added
      `src/Tools/InitialConditions.m` with named slot constants (`SOLUTION`…`KINETICS`), a
      `detect(C)` input scan, and `vectors(present, nxyz)` that builds ic1/ic2/f1 (single-cell
      1×7 or multi-cell nxyz×7). `PhreeqcSingleCell`, `InitializePhreeqcAdvection`,
      `InitializePhreeqcFVTool` now share it (was three copies of the keyword scan);
      `Solution.run`/`Surface.equilibrate_with` use the slot constants instead of magic indices.
      Behavior-preserving, covered by the `initialConditionsHelper` test. (Approach b — wiring
      the new per-reactant `RM_Initial*2Module` functions — is left for M4 when those get wrapped.)
- [x] **Robust result parsing** — DONE (Solution; Surface partially). Added
      `src/Tools/map_value.m` (safe `containers.Map` lookup with a fallback).
      `Solution.results_from_phreeqcrm` now reads every SELECTED_OUTPUT column via `map_value`,
      so a renamed/absent column yields `NaN` for that field instead of throwing and discarding
      the whole result. `Surface`'s EDL charge/potential lookups likewise robustified; its
      positional `keys()/values()` slicing is explicitly flagged FRAGILE to revisit in M3 with a
      CD-MUSIC equilibrate reference test (changing it blind is unsafe). While here, fixed two
      real bugs the now-tested `Solution.run` path exposed: a **missing `RM_FindComponents`**
      before `RunCells` (segfault) and a **block-concatenation regression** (`END` merged with
      the next keyword) — `combine_phreeqc_strings` made newline-robust. `Solution.run` now
      returns a populated `SolutionResult`; covered by `solutionRunResults`/`mapValueSafeLookup`.
      (Swapping scraped columns for the new `RM_GetTemperature/...` getters is left for M4.)
- [x] **Enum classes: use or lose** — DONE (deleted). `@solution_units`, `@phase_units`,
      `@exchange_units`, `@kinetics_units`, `@sites_units`, `@edl_layer` were unused dead code and
      wiring them would have broken the `strcmpi` string comparisons / `read_json` string
      assignments. Removed (recoverable via git); `src/classes` and its `addpath` are gone. The
      unit-number conventions they documented remain in inline comments at the `RM_SetUnits*` calls.
- [x] **Unify JSON** — DONE. Added `src/Tools/assign_json_fields.m` (shared JSON-field→property
      copier); refactored `Solution`, `Phase`, `Surface` `read_json` onto it (only the
      Composition/MasterSpecies/Reactions expansions stay bespoke). Added `Solution.to_struct` +
      `write_json` (round-trips; Composition via `containers.Map` so element names survive) and a
      `Solution.from_json(name[,file])` factory. Deleted the dead `Tools/read_json_ex.m` copy and
      the empty `Dan`/`HDan`/`Kraka` stubs in `solutions.json`. Covered by `jsonRoundTrip`.

**Milestone 2 complete.** 11/11 tests pass.

---

## Milestone 3 — Complete the stubbed classes ✅ COMPLETE

Goal: bring the half-built classes up to the `Solution`/`Surface` standard, on the M2 base class.

- [x] **`@Reactant` equilibration template** — added `ic_slot()` (each reactant's
      RM_InitialPhreeqc2Module slot) and a shared `equilibrate_with(solution)` /
      protected `run_with_solution()` that centralize the PhreeqcRM boilerplate previously
      duplicated in `Solution.run`/`Surface.equilibrate_with`.
- [x] `@Exchange` — real properties (sites/moles + optional master species, exchange reactions,
      `log_k`, `dh`), `phreeqc_string()`, three-block `input_string()`, `read_json()`/`from_json()`,
      inherited `equilibrate_with()`. Added `database/exchange.json`.
- [x] `@Kinetics` — reaction/rate fields (`-m0`, `-m`, `-parms`, `-tol`, `-steps`, RATES block),
      `phreeqc_string()`, `input_string()`, `read_json()`/`from_json()`, and `equilibrate_in_phreeqc()`
      (IPhreeqc, integrates `-steps`). Added `database/kinetics.json` with the manual calcite rate.
- [x] `@Gas` — implemented `equilibrate_in_phreeqc()`, inherited `equilibrate_with()`, fixed the
      broken `selected_output_string()`, added `read_json()`/`from_json()` and moved
      `damp_CO2()/flue_gas()` into `database/gases.json`.
- [x] `@Phase` — `equilibrate_with()` returns a `PhaseResult` (moles, moles transferred, SI) plus a
      `SolutionResult`, via one combined SELECTED_OUTPUT. (`combine_selected_output()` remains a
      `% TBD` helper — not needed by the object model.)
- [x] `@SingleCell.run()` — name-value constructor; builds the combined phreeqc string from all
      contained reactants, registers initial conditions per slot, `RM_RunCells`, returns a populated
      `SingleCellResult`.
- [x] Result classes `@PhaseResult`, `@SingleCellResult` — real parsed-output structures alongside
      `@SolutionResult`/`@SurfaceResult`.

Deferred to a later milestone: the `Surface.equilibrate_with` positional `keys()/values()` parsing
(still flagged FRAGILE) — needs a CD-MUSIC reference-value test before it can be refactored safely.

Tests: 17/17 pass (6 new — phase/exchange/kinetics/gas equilibration, `SingleCell.run`, JSON factories).

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
