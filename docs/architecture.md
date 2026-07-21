# Architecture

PhreeqcMatlab is layered from a thin FFI binding up to a convenience object
model. When you work on the code, work at the **lowest layer that satisfies the
task**.

```
 Layer 3   @Solution @Phase @Surface @Gas @Exchange @Kinetics @SingleCell
 (objects) + result classes            → generate Phreeqc input from properties
              │  (all subclass @Reactant)
 Layer 2   PhreeqcSingleCell · Advection1D · Transport1D · FVTool
 (workflows)  │                         → stitch RM_ calls into pipelines
 Layer 1   @PhreeqcRM  @IPhreeqc         → one method per C function (calllib)
 (FFI)        │
           libphreeqcrm.so / libiphreeqc.so  (native, via loadlibrary)
```

## Layer 1 — raw FFI wrappers

`src/@PhreeqcRM/PhreeqcRM.m` and `src/@IPhreeqc/IPhreeqc.m` are large classdefs
that mirror the C API, one method per C function via `calllib` against the
headers in `libs/`.

**Naming convention — this is how you tell wrapper from original:**

- Methods that map to an original library function keep the **`RM_` prefix**
  (PhreeqcRM) or the original IPhreeqc name, e.g. `RM_RunCells`,
  `RM_GetConcentrations`. Their docstrings are copied from the upstream C docs.
- Methods **added by this package** for convenience deliberately **omit the
  `RM_` prefix**, e.g. `GetConcentrations`, `GetComponents`, `GetDensity`,
  `GetSelectedOutput`. These typically allocate the output array and return it
  directly instead of the C-style `(status, out)` pair.

`loadlibrary` parses `libs/RM_interface_C.h` (the **3.8.6** header), so a native
function is only callable once its prototype is present there.

## Layer 2 — orchestration helpers

Free functions and pipeline scripts that stitch multiple `RM_` calls into a
workflow:

- `src/Bulk/PhreeqcSingleCell.m` — builds a 1-cell/1-thread PhreeqcRM from a
  Phreeqc input file, sets units, loads the database, runs, and auto-detects
  which reactant blocks are present (via `InitialConditions`) to set the initial
  conditions. The entry point for batch/sensitivity calculations.
- `src/Advection1D/` and `src/Transport1D/` — 1D reactive-transport drivers.
  `PhreeqcAdvection` loops: transport step → push concentrations into PhreeqcRM
  → `RM_RunCells` → read back. Configured by a `.pqm` control file
  (`ParsePqmConfig`).
- `src/FVTool/` — couples reactive transport to the external
  [FVTool](https://github.com/simulkade/FVTool) finite-volume package for
  multi-D transport (`PhreeqcFVToolTransport`, operator splitting). FVTool is an
  optional dependency; `fvtool_available` guards it.

## Layer 3 — high-level object model

Domain classes that represent Phreeqc concepts as MATLAB objects and generate
Phreeqc input strings from their properties, rather than requiring hand-written
input files. All six definition classes subclass the abstract
[`@Reactant`](../src/@Reactant/Reactant.m). See
[`object-model.md`](object-model.md) for the full reference.

## Value-class idiom (applies to every layer)

All wrapper classes are MATLAB **value classes**, not handles. A mutating method
returns a *new* object; you must reassign it or the change is lost:

```matlab
phrm = phrm.RM_SetComponentH2O(true);   % correct
phrm.RM_SetComponentH2O(true);          % wrong — result discarded
```

Instances hold native resources and must be destroyed explicitly
(`RM_Destroy` / `DestroyIPhreeqc`). `unloadlibrary` is intentionally **not**
called — it crashes the library.

## Path & database helpers (`src/Tools/`)

`database_file(name)` / `DATABASE_PATH` resolve database paths; `ReadPhreeqcFile`
reads and cleans input files; `combine_phreeqc_strings` concatenates keyword
blocks; `PhreeqcBlock` is the fluent keyword-block builder; `InitialConditions`
builds the `RM_InitialPhreeqc2Module` vectors; `ParsePqmConfig`/`ApplyRmSettings`
handle the `.pqm` control-file format; `assign_json_fields`/`map_value` support
JSON decoding and selected-output lookups.

Database `.dat` files ship in `database/`; any file dropped there is found
automatically. Phreeqc input files use `.pqi`/`.pqc`/`.phr`; `.pqm` files are
PhreeqcMatlab-specific transport control files.
