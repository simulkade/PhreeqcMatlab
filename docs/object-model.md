# Object model (Layer 3) reference

The Layer-3 object model lets you build geochemical entities as MATLAB objects
and have them generate Phreeqc input, instead of hand-writing input strings.

## The `Reactant` contract

Every definition class subclasses the abstract
[`@Reactant`](../src/@Reactant/Reactant.m) and shares:

| Member | Meaning |
| --- | --- |
| `name`, `number` | identity (the keyword block's user number) |
| `phreeqc_string()` | serialize this reactant to its Phreeqc keyword block |
| `input_string()` | single assembled input string (Surface/Exchange/Kinetics override it to emit their coupled blocks) |
| `ic_slot()` | the `RM_InitialPhreeqc2Module` slot this reactant occupies (an `InitialConditions.*` constant) |
| `equilibrate_with(solution [,db])` | equilibrate with a `Solution` in PhreeqcRM; returns the post-reaction aqueous `SolutionResult` (subclasses may return richer results) |

`equilibrate_with` is a template method built on the protected
`run_with_solution` helper, which centralizes the PhreeqcRM boilerplate
(assemble `{solution + reactant + selected output}`, load database, run string,
find components, `RM_InitialPhreeqc2Module`, `RM_RunCells`).

Because these are **value classes**, set properties by assignment and remember
that any mutating call must be reassigned.

## Definition classes

### `Solution`
Aqueous solution. Key properties: `unit`, `components`/`concentrations`, `pH`,
`pe`, `temperature`, `pressure`, `density`, `alkalinity`, charge-balance flags.

```matlab
s = Solution();               % pure water, 25 C, 1 atm
s.unit = "mol/kgw";
s.components = ["Na" "Cl"];  s.concentrations = [1 1];
s.pH = 7;  s.ph_charge_balance = true;
SR = s.run();                 % -> SolutionResult (PhreeqcRM path)
out = s.run_in_phreeqc();     % raw PHREEQC output string (IPhreeqc path)
```
Factories: `Solution.seawater()`, `Solution.from_json("NorthSeawater")`.
Serialization: `to_struct()`, `write_json(file)`, `read_json(struct)`.

### `Phase`
An `EQUILIBRIUM_PHASES` assemblage. Properties: `phase_names`,
`saturation_indices`, `moles`, `alternative_formula`, `dissolve_only`,
`precipitate_only`, `force_equality`.

```matlab
ph = Phase();
ph.phase_names = ["Gypsum" "Anhydrite"];
ph.saturation_indices = [0 0];
ph.moles = [1 1];
[phase_result, solution_result] = ph.equilibrate_with(Solution());
```
Factory: `Phase.chalk()`. Returns a `PhaseResult` (moles, moles transferred,
saturation index per phase) plus the aqueous `SolutionResult`.

### `Surface`
A surface-complexation model (DLM / CD-MUSIC). Emits three coupled blocks
(`SURFACE_MASTER_SPECIES`, `SURFACE_SPECIES`, `SURFACE`). Factories:
`Surface.calcite_surface()`, `Surface.calcite_surface_cd_music()`,
`Surface.oil_surface()`; templates in `database/surfaces.json`.
`equilibrate_with` returns `[SurfaceResult, SolutionResult]`.

### `Gas`
A `GAS_PHASE` (fixed pressure or fixed volume). Properties: `phase_names`,
`partial_pressure`, `temperature`, `volume`, `fixed_pressure`, `pressure`.
Factories: `Gas.damp_CO2()`, `Gas.flue_gas()`; templates in `database/gases.json`
(parallel `PhaseNames`/`PartialPressures` arrays, so identifiers like `CO2(g)`
survive `jsondecode`). `equilibrate_in_phreeqc(solution)` returns the raw PHREEQC
output; `equilibrate_with` returns the aqueous `SolutionResult`.

### `Exchange`
An ion exchanger. Minimal form: `exchange_species` (site names, e.g. `"X"`) and
`moles`; the default `X` exchanger is defined in `phreeqc.dat`. A custom
exchanger also sets `exchange_master_species` / `exchange_species_reactions` /
`log_k` / `dh`, and `input_string()` emits `EXCHANGE_MASTER_SPECIES`,
`EXCHANGE_SPECIES` and `EXCHANGE`.

```matlab
ex = Exchange.sodium_exchanger(0.001);
SR = ex.equilibrate_with(Solution.seawater());
```
Factories: `Exchange.sodium_exchanger([moles])`,
`Exchange.from_json("SodiumExchanger")`; templates in `database/exchange.json`.

### `Kinetics`
Rate-controlled reactions. Properties: `reaction_names`, `m0`, `m`, `parameters`
(per-reaction `-parms`), `tol`, `steps`, `step_count`, and `rates_definition`
(the `RATES` BASIC block). `input_string()` emits `RATES` before `KINETICS`.
Because kinetics are time-dependent, run them in IPhreeqc, which integrates
`-steps`:

```matlab
k = Kinetics.calcite();                       % manual calcite rate
out = k.equilibrate_in_phreeqc(Solution.seawater());
```
Factory: `Kinetics.calcite([seconds],[n_steps])`,
`Kinetics.from_json("CalciteKinetics")`; template in `database/kinetics.json`.
(PhreeqcRM time-stepping for standalone kinetics is a transport concern — see
Layer 2.)

## `SingleCell` — a batch reactor

Assemble a solution with any of the reactants above into one PhreeqcRM cell:

```matlab
sc = SingleCell(Solution.seawater(), ...
                'equilibrium_phase', Phase.chalk(), ...
                'gas_phase', Gas.damp_CO2(), ...
                'exchanger', Exchange.sodium_exchanger(), ...
                'data_base', 'phreeqc.dat');
R = sc.run();          % -> SingleCellResult
R.solution.pH          % aqueous SolutionResult
R.phase.saturation_indices   % PhaseResult (present only if the cell had phases)
```

Constructor name-value keys: `equilibrium_phase`|`phase`,
`surface`|`surface_specie`, `exchanger`|`exchange`, `kinetics`,
`gas_phase`|`gas`, `data_base`|`database`, `temperature`, `pressure`.

## Result classes

| Class | Holds |
| --- | --- |
| `SolutionResult` | pH, pe, temperature, ionic strength, density, viscosity, charge balance, components/species concentrations and activities, … |
| `PhaseResult` | per-phase moles, moles transferred, saturation index |
| `SurfaceResult` | surface species/elements, EDL charges/potentials, double-layer composition |
| `SingleCellResult` | the aqueous `SolutionResult` plus `PhaseResult`/`SurfaceResult` when present |

SELECTED_OUTPUT columns are looked up by their PHREEQC header via `map_value`,
so a renamed/absent column degrades to `NaN` for that field rather than
discarding the whole result.

## JSON templates

Definition classes load from JSON templates in `database/`:
`solutions.json`, `surfaces.json`, `gases.json`, `exchange.json`,
`kinetics.json`. Each class has a `read_json(struct)` (decode one entry) and a
`from_json(name [,file])` factory (look one up by name). Scalar fields are copied
by `assign_json_fields` via a per-class field map; composition-style fields are
expanded into the parallel name/amount arrays.
