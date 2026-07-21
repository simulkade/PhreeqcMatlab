# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

`PhreeqcMatlab` is a MATLAB wrapper around the USGS geochemical engines **PhreeqcRM** (reactive transport, C interface) and **IPhreeqc** (single-instance Phreeqc). All communication with the native libraries goes through MATLAB's `loadlibrary`/`calllib` FFI against the C headers in `libs/`.

## Setup & Running

- **Always run `startup.m` first** in any MATLAB session. It adds all `src/*` subfolders and `database/` to the path, then ensures the native libraries (`libphreeqcrm.so`/`.dll`, `libiphreeqc.so`/`.dll`) are present in `libs/` at the pinned version. Resolution order per library: (1) a correctly versioned file already in `libs/` (tracked by `libs/.phreeqc_version`); (2) a local install — the `PHREEQCMATLAB_LIB_PATH` env var, else `/usr/local/lib` — copied into `libs/`; (3) download from the `simulkade/PhreeqcRM` GitHub releases. These binaries and the stamp file are `.gitignore`d — never committed.
- Native libs pin **PhreeqcRM 3.8.6** and **IPhreeqc 3.8.6** (`3.8.6-17100`). Bumping the version = edit the `*_VERSION` constants at the top of `startup.m`; the stamp file triggers an automatic refresh. macOS is unsupported (no prebuilt binary; must compile PhreeqcRM manually).
- **Linux launch:** the 3.8.6 binaries are built with a modern system GCC and need a newer `libstdc++` (`GLIBCXX_3.4.32`) than MATLAB bundles. Launch via **`./run_matlab.sh`** (which sets `LD_PRELOAD` to the system `libstdc++.so.6` and `PHREEQCMATLAB_LIB_PATH`) — e.g. `./run_matlab.sh -batch "runtests('tests')"`. Without it, `loadlibrary` fails with `GLIBCXX_... not found`; `startup.m` prints a hint pointing here.
- Windows also requires the VC++ 2019 redistributable and a configured MATLAB C/C++ compiler (MinGW-w64).
- **Assertion tests** (regression gate): `tests/PhreeqcMatlabTest.m` is a `matlab.unittest` suite with physically-grounded golden values. Run all via `./run_matlab.sh -batch "addpath('tests'); run_all_tests"` (errors on any failure — used by CI) or `runtests('tests')`. Fixtures live in `tests/fixtures/`.
- **Demo tests** (examples, not assertions): `cd tests && main.m` runs `SimpleAdvect`, `Advect`, `Species`, `Gas_m` to completion with plots. Run one directly, e.g. `run('tests/SimpleAdvect.m')`, after `startup`. Note these scripts reuse the variable `i`, so drive them from a function scope if wrapping.
- Examples live under `examples/` (`basetest/`, `transport/`, `benchmarks/`, `phreeqc/`); run individual `.m` scripts directly after `startup`.
- **Packaging**: `package_toolbox.m` builds `PhreeqcMatlab.mltbx` (headers shipped, binaries fetched at runtime). CI is `.github/workflows/ci.yml` (builds libs from source, then runs the suite).

## Architecture

The code is layered from a thin FFI binding up to convenience objects. When editing, work at the lowest layer that satisfies the task.

**Layer 1 — raw FFI wrappers.** `src/@PhreeqcRM/PhreeqcRM.m` and `src/@IPhreeqc/IPhreeqc.m` are large classdefs that mirror the C API one-method-per-C-function. Every method that maps to an original library function keeps its **`RM_` prefix** (PhreeqcRM) or original IPhreeqc name and is a near-direct `calllib` call. Methods added by this package for convenience deliberately **omit the `RM_` prefix** (e.g. `GetConcentrations`, `GetComponents`, `GetSelectedOutput`) — this naming convention is how you tell wrapper from original. Docstrings on `RM_` methods are copied from the upstream C documentation.

**Layer 2 — orchestration helpers.** Free functions and pipeline scripts that stitch multiple `RM_` calls into a workflow:
- `src/Bulk/PhreeqcSingleCell.m` — builds a 1-cell/1-thread `PhreeqcRM` from a Phreeqc input file, sets units, loads the database, runs, and auto-detects which reactant blocks (`SOLUTION`, `EQUILIBRIUM_PHASES`, `EXCHANGE`, `SURFACE`, `GAS_PHASE`, `SOLID_SOLUTION`, `KINETICS`) are present by text-scanning the input to set the `ic1` initial-conditions vector. This is the entry point for batch/sensitivity calculations.
- `src/Advection1D/` and `src/Transport1D/` — 1D reactive-transport drivers. `PhreeqcAdvection.m` reads a Phreeqc advection input + an advection control file, then loops: transport step (`SimpleAdvection1D`) → push concentrations into PhreeqcRM (`RM_SetConcentrations`) → `RM_RunCells` → read back (`GetConcentrations`). `ReadAdvectionFile`/`InitializePhreeqcAdvection` do the setup.
- `src/FVTool/` — couples reactive transport to the external [FVTool](https://github.com/simulkade/FVTool) finite-volume package for multi-D transport. `PhreeqcFVToolTransport` is the 2D driver (operator splitting); `InitializePhreeqcFVTool` sets initial/boundary conditions. FVTool is an *optional* dependency — `fvtool_available` guards it and the driver errors helpfully when it is absent.

**Layer 3 — high-level object model (in progress).** Domain classes that represent Phreeqc concepts as MATLAB objects and generate Phreeqc input strings from their properties, rather than requiring hand-written input files:
- Definition classes: `@Solution`, `@Phase`, `@Surface`, `@Exchange`, `@Gas`, `@Kinetics`, `@SelectedOutput`, `@SingleCell`, `@Datafile`.
- The core pattern: each definition class has a `phreeqc_string()` method that serializes its properties into a Phreeqc keyword block, a `run_in_phreeqc()` / `run()` method that creates a (I)Phreeqc instance, executes, and returns results, and `read_json()` to build objects from the JSON templates in `database/` (`solutions.json`, `surfaces.json`).
- Result classes (`@SolutionResult`, `@PhaseResult`, `@SurfaceResult`, `@SingleCellResult`) hold parsed output.
- All six definition classes subclass the abstract `@Reactant` base (`src/@Reactant/`), which holds the shared `name`/`number` identity and a uniform `input_string()`; each subclass implements `phreeqc_string()`. Blocks are assembled with the `PhreeqcBlock` builder (`src/Tools/PhreeqcBlock.m`), JSON is decoded via `assign_json_fields`, initial-condition vectors via `InitialConditions`, and SELECTED_OUTPUT columns read via `map_value` (all in `src/Tools/`).

**Path helpers** in `src/Tools/`: `database_file(name)` and `DATABASE_PATH` resolve database file paths; `ReadPhreeqcFile` reads and cleans input files; `combine_phreeqc_strings` concatenates keyword blocks. `ParsePqmConfig` parses the `.pqm` control-file format (1D `cells`/`shifts` and multi-D `Nx`/`Ny`/`Lx`/`Ly`) into a config struct and `ApplyRmSettings` pushes those settings onto a PhreeqcRM instance (both used by `ReadAdvectionFile` and the FVTool driver).

The `libs/` C headers are the **3.8.6** interface (`RM_interface_C.h` + `irm_dll_export.h`); `loadlibrary` parses them, so a new native function is only callable once its prototype is present there.

## Conventions

- MATLAB value-class idiom: mutating methods return a new object (`phrm = phrm.RM_Create()`), because these are value classes, not handles. Reassign the return value or the change is lost.
- Instances must be explicitly destroyed (`RM_Destroy`, `DestroyIPhreeqc`) to free the native side. Note `unloadlibrary` is intentionally left commented out in `RM_Destroy` — calling it crashes the library.
- Database `.dat` files ship in `database/`; any file dropped there is found automatically by `database_file`.
- Phreeqc input files use extensions like `.pqi`, `.pqc`, `.phr`; `.pqm` files are PhreeqcMatlab-specific input files.
