# Changelog

All notable changes to PhreeqcMatlab are documented here.
The format is loosely based on [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased] — FVTool auto-provisioning + verified 2D transport

### Added
- `startup.m` now auto-provisions the optional **FVTool** dependency: if it is not on the path it
  is cloned into `external/FVTool` (gitignored) and initialized via `FVToolStartUp`, with the
  caller's current directory saved and restored (FVToolStartUp `cd`s internally). Multi-D reactive
  transport works out of the box when git + network are available.
- `reactiveTransport2D` regression test — runs the 2D CaCl2-flush / cation-exchange example
  end-to-end through FVTool + PhreeqcRM (skipped, via assumption, when FVTool is unavailable) and
  asserts the expected chemistry (Na displaced out, Ca breaks through). Suite: 21 pass + 1
  conditionally-skipped guard test.

### Changed
- README / CLAUDE.md / example / driver error message updated to reflect auto-provisioning and the
  new upstream (`FiniteVolumeTransportPhenomena/FVTool`).

## [Unreleased] — Milestone 5: documentation

### Added
- `docs/architecture.md` — the three-layer architecture, the `RM_` naming rule, and the value-class
  idiom, as user/contributor-facing documentation.
- `docs/object-model.md` — full Layer-3 reference: the `Reactant` contract, every definition class
  (`Solution`/`Phase`/`Surface`/`Gas`/`Exchange`/`Kinetics`), `SingleCell`, the result classes and
  the JSON templates.
- `CONTRIBUTING.md` — setup, conventions (value-class reassign-or-lose, explicit destroy, `RM_`
  naming), and how to add a wrapper / definition class / test.

### Changed
- `README.md` refreshed: a prominent value-class + explicit-destroy callout, accurate 3.8.6
  install/launch instructions (`run_matlab.sh`, `GLIBCXX`, local-install fallback), a high-level
  object-model quickstart, a "running the tests" section, and a roadmap pointer replacing the stale
  to-do list.

## [Unreleased] — Milestone 4: continue & extend

### Added
- **PhreeqcRM 3.8.6 C header** shipped in `libs/` (was still 3.7.x), plus `libs/irm_dll_export.h`
  in a loadlibrary-friendly form. `loadlibrary` now binds 193 functions (was ~119).
- New `@PhreeqcRM` wrappers for the 3.8.6 non-BMI API: `GetTemperature`, `GetPressure`,
  `GetPorosity`, `GetViscosity`, `GetDensityCalculated`, `GetSaturationCalculated`,
  `RM_GetCurrentSelectedOutputUserNumber`, `RM_SetNthSelectedOutput`,
  `RM_Get`/`SetIthConcentration`, `RM_Get`/`SetIthSpeciesConcentration`, `RM_SetDensityUser`,
  `RM_SetSaturationUser`, and the seven per-reactant `RM_Initial*2Module` initializers.
- `src/Tools/ParsePqmConfig.m` — parser for the `.pqm` control-file format (1D `cells`/`shifts`
  and multi-D `Nx`/`Ny`/`Lx`/`Ly`), and `src/Tools/ApplyRmSettings.m` — applies the parsed
  PhreeqcRM settings to an instance.
- `src/Tools/fvtool_available.m` and `src/FVTool/PhreeqcFVToolTransport.m` — an FVTool-coupled
  multi-dimensional reactive-transport driver (operator splitting) that guards the optional FVTool
  dependency. 2D example in `examples/transport/reactive_transport_2d.{m,pqm,pqc}`.
- Three new tests: `.pqm` parser (1D + 2D) and the FVTool-missing guard; plus `newApi386Getters`
  pinning water-at-25C golden values. Suite is 21/21.

### Changed
- `ReadAdvectionFile` now delegates to `ParsePqmConfig`/`ApplyRmSettings` (removing its duplicated
  `sscanf` ladder) and no longer calls `RM_Create` twice.
- `InitializePhreeqcFVTool` cleaned up: removed the stale "NOT DONE YET" banner, a stray trailing
  `end` (a latent parse error), and the redundant post-construction `RM_Create`.

## [Unreleased] — Milestone 3: complete the stubbed classes

### Added
- `@Reactant.ic_slot()` and a shared `equilibrate_with(solution)` template (with the protected
  `run_with_solution` helper), centralizing the PhreeqcRM equilibration boilerplate. Every reactant
  now reports the RM_InitialPhreeqc2Module slot it occupies.
- `@Exchange` — full implementation: exchange sites/moles, optional custom EXCHANGE_MASTER_SPECIES /
  EXCHANGE_SPECIES definitions, `phreeqc_string()`, three-block `input_string()`,
  `read_json()`/`from_json()`, and `Exchange.sodium_exchanger()`. New `database/exchange.json`.
- `@Kinetics` — full implementation: `-m0`/`-m`/`-parms`/`-tol` per reaction, `-steps ... in N steps`,
  an optional RATES (BASIC) block, `phreeqc_string()`/`input_string()`, `read_json()`/`from_json()`,
  `Kinetics.calcite()`, and `equilibrate_in_phreeqc()` (IPhreeqc, integrates `-steps`). New
  `database/kinetics.json` (the PHREEQC-manual calcite rate).
- `@Gas` — `equilibrate_in_phreeqc()`, `read_json()`/`from_json()`; `damp_CO2()`/`flue_gas()` now load
  from the new `database/gases.json`.
- `@Phase.equilibrate_with()` now returns a populated `@PhaseResult` (final moles, moles transferred,
  saturation index per phase) plus the aqueous `@SolutionResult`.
- `@SingleCell` — name-value constructor and a working `run()` that assembles a solution with any
  contained equilibrium phases / surface / exchanger / gas / kinetics into one PhreeqcRM cell and
  returns a populated `@SingleCellResult` (aqueous + per-phase results).
- Six new regression tests (phase/exchange/kinetics/gas equilibration, `SingleCell.run`, JSON
  factories); suite is 17/17.

### Fixed
- `@Gas.selected_output_string()` was malformed (`strjoin` of literal `"\n"` tokens); rebuilt with
  `PhreeqcBlock`. `@Gas.equilibrate_in_phreeqc`/`equilibrate_with` were empty stubs.
- `@Exchange`/`@Kinetics` `phreeqc_string()` no longer throw `notImplemented`; empty definitions
  serialize to `''` so they are skippable when assembling a `SingleCell`.

## [Unreleased] — Milestone 2: object-model refactor (in progress)

### Added
- `src/Tools/PhreeqcBlock.m` — fluent builder for Phreeqc keyword blocks with empty-field
  suppression, consistent numeric formatting, and deterministic spacing.
- `src/@Reactant/Reactant.m` — abstract base class unifying reactant identity (`name`/`number`)
  and serialization (`phreeqc_string`/`input_string`). `@Solution`, `@Phase`, `@Surface`, `@Gas`,
  `@Exchange`, `@Kinetics` now subclass it and can be handled polymorphically.
- `src/Tools/InitialConditions.m` — named reactant-slot constants + `detect`/`vectors` helpers
  for RM_InitialPhreeqc2Module, replacing the 7-slot `ic1` vector duplicated across
  `PhreeqcSingleCell`, `InitializePhreeqcAdvection`, `InitializePhreeqcFVTool` (and the magic
  indices in `Solution`/`Surface`).
- `src/Tools/map_value.m` — safe `containers.Map` lookup used to read SELECTED_OUTPUT tables by
  header, so a missing/renamed column degrades to a fallback instead of discarding the result.
- `src/Tools/assign_json_fields.m` — shared JSON-field→property copier, replacing the per-class
  `isfield` ladders in `read_json`.
- `Solution.from_json(name[,file])` factory, and `Solution.to_struct`/`write_json` for
  serializing a solution back to JSON (round-trips).

### Removed
- Dead code: the six unused enum classes under `src/classes/` (and its `addpath`), the
  non-runnable `Tools/read_json_ex.m` duplicate, and the empty `Dan`/`HDan`/`Kraka` entries in
  `database/solutions.json`.

### Fixed
- `Solution.run` was non-functional (untested): added the missing `RM_FindComponents` before
  `RunCells` (was a segfault) and fixed block concatenation so `END` no longer merges with the
  following `SELECTED_OUTPUT` keyword. `combine_phreeqc_strings` is now newline-robust.

### Changed
- `@Solution`, `@Gas`, `@Phase`, `@Surface`, `@SelectedOutput` `phreeqc_string()` now build
  their blocks with `PhreeqcBlock` instead of ad-hoc `strjoin`/`sprintf`. Fixes malformed
  empty-field lines (`pe`, `density 0`) and fragile `num2str(vector)` formatting. All blocks
  verified to round-trip through IPhreeqc without parse errors.

## [Unreleased] — Milestone 1: stabilize the foundation

### Changed
- **Bumped native libraries to PhreeqcRM / IPhreeqc 3.8.6** (`3.8.6-17100`) from 3.7.1/3.7.0.
  All 119 wrapped `RM_` functions verified signature-compatible; no wrapper changes required.
- Rewrote `startup.m`: single `ensure_library` helper (was four duplicated download blocks),
  local-install fallback (`PHREEQCMATLAB_LIB_PATH` → `/usr/local/lib`), and a
  `libs/.phreeqc_version` stamp that auto-refreshes on a version bump.

### Added
- `run_matlab.sh` launcher that sets `LD_PRELOAD` (system `libstdc++` for `GLIBCXX_3.4.32`) and
  `PHREEQCMATLAB_LIB_PATH`, plus a preflight warning in `startup.m`.
- `tests/PhreeqcMatlabTest.m` — assertion-based `matlab.unittest` suite with physically-grounded
  golden values; `tests/run_all_tests.m` single entry point; `tests/fixtures/`.
- `ROADMAP.md` — refactoring & continuation plan.

### Fixed
- `@SingleCellResult` classdef name mismatch (class could not load).
- `@Phase`: `phase_string` typo, `EQUILIBRIUM_PHASES` keyword, four-fold `selected_output`
  overwrite, and `read_json` populating the nonexistent `components` instead of `phase_names`.
- `@Gas`: missing `num2str` on partial pressures, empty-`pressure` emission, and GAS_PHASE
  identifiers now newline-separated.
- Removed redundant `RM_Create()` calls (`PhreeqcSingleCell`, `@SingleCell`).
- Run methods now surface the real error message instead of swallowing it.
- Removed leftover IDE-template `method1`/`Property1` from `@Exchange`, `@Kinetics`,
  `@PhaseResult`, `@SingleCellResult`.
