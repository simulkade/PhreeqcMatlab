# Changelog

All notable changes to PhreeqcMatlab are documented here.
The format is loosely based on [Keep a Changelog](https://keepachangelog.com/).

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
