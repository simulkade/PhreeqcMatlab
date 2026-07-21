[![DOI](https://zenodo.org/badge/187366776.svg)](https://zenodo.org/badge/latestdoi/187366776)
[![View PhreeqcMatlab on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://se.mathworks.com/matlabcentral/fileexchange/99394-phreeqcmatlab)
# PhreeqcMatlab
[Documents (work in progress)](https://github.com/simulkade/PhreeqcMatlab/wiki)

## Easily calling PhreeqcRM and IPhreeqc from Matlab  
`PhreeqcMatlab` is a wrapper for the [PhreeqcRM](https://www.usgs.gov/software/phreeqc-version-3) [C interface](https://wwwbrr.cr.usgs.gov/projects/GWC_coupled/phreeqcrm/_r_m__interface___c_8h.html) and [IPhreeqc](https://wwwbrr.cr.usgs.gov/projects/GWC_coupled/iphreeqc/IPhreeqc_8h.html). Most of the functions are wrapped, with the exception of MPI function (that I neither use nor know how to wrap). In general, the C++ interface of PhreeqcRM has more functionality and is easier to call. Therefore, I have implemented several classes and functions to make the usage of this package more convenient, similar to its c++ interface and better. All the original PhreeqcRM functions start with `RM_`. The additional utility functions that I have added do not have this extra `RM_`.

# Installation

Clone or download this repository and **run `startup.m` first in every MATLAB session**. It adds the source folders to the path and makes sure the native libraries are present in `libs/`.

`PhreeqcMatlab` pins **PhreeqcRM / IPhreeqc 3.8.6** (`3.8.6-17100`). For each library, `startup.m` resolves it in this order: (1) a correctly versioned file already in `libs/`; (2) a local install — the `PHREEQCMATLAB_LIB_PATH` environment variable, else `/usr/local/lib`; (3) download from the [`simulkade/PhreeqcRM`](https://github.com/simulkade/PhreeqcRM) releases. The binaries are not committed.

- **Linux — launch via [`./run_matlab.sh`](run_matlab.sh).** The 3.8.6 binaries are built with a modern GCC and need a newer `libstdc++` (`GLIBCXX_3.4.32`) than MATLAB bundles. `run_matlab.sh` sets `LD_PRELOAD` to the system `libstdc++.so.6` (and `PHREEQCMATLAB_LIB_PATH`) so `loadlibrary` succeeds — e.g. `./run_matlab.sh -batch "runtests('tests')"`. Without it you'll see a `GLIBCXX_... not found` error.
- **Windows** requires the [Visual C++ Redistributable for VC 2019](https://www.microsoft.com/en-us/download/details.aspx?id=48145) and a configured [C/C++ compiler](https://www.mathworks.com/matlabcentral/fileexchange/52848-matlab-support-for-mingw-w64-c-c-compiler) (MinGW-w64).
- **macOS** is unsupported (no prebuilt binary); compile PhreeqcRM yourself and point `PHREEQCMATLAB_LIB_PATH` at the resulting `.dylib`.

## ⚠️ Two things that bite everyone

**1. This is a *value-class* library — reassign or your change is lost.** The wrapper objects are MATLAB value classes, not handles. A mutating method returns a *new* object; if you don't capture it, nothing changes:

```matlab
phrm = phrm.RM_SetComponentH2O(true);   % ✅ correct — reassign
phrm.RM_SetComponentH2O(true);          % ❌ wrong — the result is discarded
```

**2. Destroy instances explicitly** to free the native side (`unloadlibrary` is intentionally *not* called — it crashes the library):

```matlab
phrm.RM_Destroy();       % PhreeqcRM
iph.DestroyIPhreeqc();   % IPhreeqc
```

# Test cases

[`SimpleAdvect.m`](tests/SimpleAdvect.m) and [`Advect.m`](tests/Advect.m) demonstrate advection simulation for Phreeqc reactive transport modeling software. It sets up initial conditions, defines boundary conditions, and runs a transient loop simulating advection.
[`Species.m`](tests/Species.m) demonstrates species transport using PhreeqcRM.
[`Gas_m.m`](tests/Gas_m.m) demonstrates the equilibration of gas with an aqueous phase

You can run all tests by executing [`main.m`](tests/main.m).

Need more examples? Go to the [examples](examples/basetest) folder and run the files. 

Don't forget to run the [`startup`](startup.m) file before running the examples.  

## Simple cases
### Running a Phreeqc input file or string:
```matlab
iph = IPhreeqc(); % load the library
iph = iph.CreateIPhreeqc(); % create an IPhreeqc instance
iph_string = ['SOLUTION 1 brine \n' ...
    'pH      7.0 \n' ...
    'temp    25.0 \n' ...
    'Na    1.0 \n' ...
    'Cl    1.0 \n' ...
    'END \n' ...
    'SELECTED_OUTPUT 1 \n'...
    '-reset false \n'...
    '-totals Na Cl \n'...
    'END']; % create the Phreeqc string
out_string = iph.RunPhreeqcString(iph_string, database_file('phreeqc.dat')); % Run the string
disp(out_string)       % display the results
iph.DestroyIPhreeqc(); % kill the phreeqc instance
```  
Alternatively, you can save the string in a file and call it with `RunPhreeqcFile` function as shown [here](https://github.com/simulkade/PhreeqcMatlab/tree/master/examples/IPhreeqc).  

## Sensitivity analysis
In [this folder](https://github.com/simulkade/PhreeqcMatlab/tree/master/examples/batch), there are a couple of examples that shows how to investigate the effect of temperature on the dissolution of anhydrite and gypsum. Save the following Phreeqc input in a file named `ex2_input.pqc` (example 2 of Phreeqc manual) 
```phreeqc
#TITLE Example 2.--Temperature dependence of solubility of gypsum and anhydrite
SOLUTION 1 Pure water
        pH      7.0
        temp    25.0                
EQUILIBRIUM_PHASES 1
        Gypsum          0.0     1.0
        Anhydrite       0.0     1.0
END

SELECTED_OUTPUT 1
        -reset false
        -si     Anhydrite  Gypsum
USER_PUNCH
        -headings equi_anhydrite
        10 PUNCH EQUI("Anhydrite")

END
```  
and run the following script to calculate and plot the solubility in different temperatures:  
```matlab
phreeqc_rm = PhreeqcSingleCell('ex2_input.pqc', 'phreeqc.dat');
n_data = 51;
h_out = phreeqc_rm.GetSelectedOutputHeadings(1);
temperature = linspace(25.0, 75.0, n_data); % degree C
s_out = zeros(n_data, length(h_out));
for i = 1:length(temperature)
    phreeqc_rm.RM_SetTemperature(temperature(i));
    status = phreeqc_rm.RM_RunCells();
    c_out = phreeqc_rm.GetConcentrations();
    s_out(i, :) = phreeqc_rm.GetSelectedOutput(1);
end
plot(temperature, s_out, '-s');
legend(string(h_out));
xlabel('T (C)');
ylabel('SI');
status = phreeqc_rm.RM_Destroy();
```  

## High-level object model
Instead of hand-writing Phreeqc input strings, you can build geochemical entities as MATLAB objects and let them generate the input for you. Every definition class (`Solution`, `Phase`, `Surface`, `Gas`, `Exchange`, `Kinetics`) subclasses `Reactant`: it has a `phreeqc_string()` that serializes its properties to a Phreeqc keyword block, an `equilibrate_with(solution)` that runs it in PhreeqcRM, and `read_json`/`from_json` factories that build objects from the JSON templates in `database/`.

```matlab
% Equilibrate seawater with a gypsum/anhydrite assemblage
ph = Phase();
ph.phase_names = ["Gypsum" "Anhydrite"];
ph.saturation_indices = [0 0];
ph.moles = [1 1];
[phase_result, solution_result] = ph.equilibrate_with(Solution());
phase_result.saturation_indices     % ~[0, -0.30]
solution_result.pH                  % aqueous result after reaction

% Or assemble a batch reactor from several reactants and run it in one cell
sc = SingleCell(Solution.seawater(), ...
                'equilibrium_phase', Phase.chalk(), ...
                'gas_phase', Gas.damp_CO2());
R = sc.run();          % -> SingleCellResult (R.solution, R.phase)
```

Results come back as typed objects (`SolutionResult`, `PhaseResult`, `SurfaceResult`, `SingleCellResult`). See [`docs/object-model.md`](docs/object-model.md) for the full reference, and [`docs/architecture.md`](docs/architecture.md) for how the layers fit together.

## Running the tests
The assertion suite (`tests/PhreeqcMatlabTest.m`, physically-grounded golden values) is the regression gate:
```bash
./run_matlab.sh -batch "addpath('tests'); run_all_tests"   # errors on any failure
```
or, from inside MATLAB, `runtests('tests')`. The demo scripts (`tests/main.m`) run the advection/species/gas examples with plots.

## And more
Look at the [example folder](https://github.com/simulkade/PhreeqcMatlab/tree/master/examples) for many more examples of batch and transport geochemical calculations.  

# Reactive transport
1D advection is built in (`PhreeqcAdvection`, no external dependency). Multi-dimensional reactive transport couples PhreeqcRM to the finite-volume package [FVTool](https://github.com/FiniteVolumeTransportPhenomena/FVTool) via `PhreeqcFVToolTransport` (operator splitting). FVTool is provisioned automatically: `startup.m` clones it into `external/FVTool` on first run (when git and network are available) and adds it to the path. Transport runs are configured with a small `.pqm` control file; a worked 2D example (a CaCl₂ flush of a Na/K exchanger) is in [`examples/transport/reactive_transport_2d.m`](examples/transport/reactive_transport_2d.m). You can help by contributing reactive-transport cases with analytical solutions.

# Other packages you might like
There are at least two more packages that have some of the functionalities of `PhreeqcMatlab`, and inspired me to write this package.

  + [TReacLab](https://github.com/TReacLab/TReacLab)
  + [CRP](https://github.com/nbengdahl/CRP)

# Roadmap & contributing
The refactoring/continuation plan and its progress live in [`ROADMAP.md`](ROADMAP.md); notable changes are tracked in [`CHANGELOG.md`](CHANGELOG.md). Milestones 1–4 (library bump to 3.8.6, object-model refactor on the `Reactant` base class, completed definition classes, the new 3.8.6 API wrappers and the `.pqm`/FVTool transport path) are done; the remaining work (BMI binding, more examples, GUI) is listed there. Contributions and suggestions are very welcome — see [`CONTRIBUTING.md`](CONTRIBUTING.md) for setup, the coding conventions (the `RM_` naming rule, the value-class idiom) and how to add a wrapper or a test.

# Author
The original package was written by [Ali A. Eftekhari](https://www.dtu.dk/english/Person/ali-akbar-eftekhari?id=112240&entity=profile) in his free time. It is/will be used in some of the projects/publications at the [Danish Offshore Technology Centre](https://offshore.dtu.dk/) (DOTC) at the [Technical University of Denmark](https://www.dtu.dk/). Some of the current development is done as part of an ongoing project at the DOTC.

# Citation
Please cite as
```
Eftekhari, Ali A., and Behzad Hosseinzadeh. Simulkade/PhreeqcMatlab: Preliminary Release of PhreeqcMatlab. Zenodo, 2021, doi:10.5281/ZENODO.5513713.
```
