function [phreeqc_rm, bc_conc, c_init] = InitializePhreeqcFVTool(phreeqc_rm, input_file)
%INITIALIZEPHREEQCFVTOOL load initial/boundary conditions into a PhreeqcRM
%instance from a Phreeqc input file, for coupling to an FVTool transport grid.
%
% Assumes a 1:1 mapping between transport grid cells and reaction cells
% (phreeqc_rm.ncells). One block of each reactant keyword present in the input
% file is assumed per cell (block i -> cell i); see InitialConditions.
%
% Returns:
%   phreeqc_rm : updated PhreeqcRM object (initial conditions run once)
%   bc_conc    : boundary-condition concentrations (from SOLUTION 0)
%   c_init     : initial per-cell concentrations (ncomps*nxyz)
%
% See also PhreeqcFVToolTransport, InitialConditions, ParsePqmConfig.

% Map transport grid cells to reaction cells 1:1 (0-based indices for C).
nxyz = phreeqc_rm.ncells;
grid2chem = 0:nxyz-1;
phreeqc_rm.RM_CreateMapping(grid2chem);

workers = true;             % worker instances run the reaction calculations
initial_phreeqc = true;     % InitialPhreeqc accumulates initial + boundary conditions
utility = true;             % utility instance available for processing
phreeqc_rm.RM_RunFile(workers, initial_phreeqc, utility, input_file);

% Clear the worker/utility instances (keep the InitialPhreeqc definitions).
phreeqc_rm.RM_RunString(true, false, true, 'DELETE; -all');

% Number of components to transport.
ncomps = phreeqc_rm.RM_FindComponents();

% Read the (cleaned) input file to detect which reactant blocks are present.
C = ReadPhreeqcFile(input_file);

if any(contains(C, 'SELECTED_OUTPUT'))
    phreeqc_rm.RM_SetSelectedOutputOn(true);
end

% Assume one block of each present reactant per cell (block i -> cell i).
present = InitialConditions.detect(C);
if ~present(InitialConditions.SOLUTION)
    error('PhreeqcMatlab:missingSolution', ...
        'SOLUTION must be defined in the input file.');
end
[ic1, ic2, f1] = InitialConditions.vectors(present, nxyz);
phreeqc_rm.RM_InitialPhreeqc2Module(ic1, ic2, f1);

% Boundary condition: derived from SOLUTION 0 in the InitialPhreeqc instance.
nbound = 1;
bc1   = zeros(nbound, 1);      % solution 0 from the InitialPhreeqc instance
bc2   = -1 * ones(nbound, 1);  % no second solution to mix
bc_f1 = ones(nbound, 1);       % mixing fraction for bc1 = 1
bc_conc = zeros(ncomps * nbound, 1);
[~, bc_conc] = phreeqc_rm.RM_InitialPhreeqc2Concentrations(bc_conc, nbound, bc1, bc2, bc_f1);

% Run the cells once at t = 0 to obtain the initial transported concentrations.
phreeqc_rm.RM_SetTime(0.0);
phreeqc_rm.RM_SetTimeStep(0.0);
phreeqc_rm.RM_RunCells();
c_init = phreeqc_rm.GetConcentrations();
end
