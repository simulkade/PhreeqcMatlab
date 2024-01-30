nxyz = 20;
nthreads = 3;
phreeqc_rm = PhreeqcRM(nxyz, nthreads);
phreeqc_rm = phreeqc_rm.RM_Create();
% Set properties
status = phreeqc_rm.RM_SetComponentH2O(false);
phreeqc_rm.RM_UseSolutionDensityVolume(false);

% Open files
status = phreeqc_rm.RM_SetFilePrefix('SimpleAdvect');
phreeqc_rm.RM_OpenFiles();

% Set concentration units
status = phreeqc_rm.RM_SetUnitsSolution(2); % 1, mg/L; 2, mol/L; 3, kg/kgs
status = phreeqc_rm.RM_SetUnitsExchange(1); % 0, mol/L cell; 1, mol/L water; 2 mol/L rock

% Set conversion from seconds to user units (days)
time_conversion = 1.0 / 86400;
status = phreeqc_rm.RM_SetTimeConversion(time_conversion);

% Set initial porosity
por = ones(1, nxyz) * 0.2;
status = phreeqc_rm.RM_SetPorosity(por);

% Set cells to print chemistry when print chemistry is turned on
print_chemistry_mask = ones(1, nxyz);
status = phreeqc_rm.RM_SetPrintChemistryMask(print_chemistry_mask);

nchem = phreeqc_rm.RM_GetChemistryCellCount();

% Set initial conditions
status = phreeqc_rm.RM_SetPrintChemistryOn(false, true, false); % workers, initial_phreeqc, utility

% Load database
status = phreeqc_rm.RM_LoadDatabase('../database/phreeqc.dat');

% Run file to define solutions and reactants for initial conditions, selected output
status = phreeqc_rm.RM_RunFile(true, true, true, 'advect.pqi');

% Clear contents of workers and utility
input = 'DELETE; -all';
status = phreeqc_rm.RM_RunString(true, false, true, input);

% Determine number of components to transport
ncomps = phreeqc_rm.RM_FindComponents();

% Get component information
components = phreeqc_rm.GetComponents();

for i = 1:ncomps
    fprintf('%s\n', components{i});
end
fprintf('\n');

% Set array of initial conditions
ic1 = -1*ones(nxyz*7, 1);
ic2 = -1*ones(nxyz*7, 1);
f1 = ones(nxyz*7, 1);

for i = 1:nxyz
    ic1(i) = 1;              % Solution 1
    ic1(nxyz + i) = -1;      % Equilibrium phases none
    ic1(2*nxyz + i) = 1;     % Exchange 1
    ic1(3*nxyz + i) = -1;    % Surface none
    ic1(4*nxyz + i) = -1;    % Gas phase none
    ic1(5*nxyz + i) = -1;    % Solid solutions none
    ic1(6*nxyz + i) = -1;    % Kinetics none
end

status = phreeqc_rm.RM_InitialPhreeqc2Module(ic1,ic2,f1);

% Initial equilibration of cells
time = 0.0;
time_step = 0.0;
status = phreeqc_rm.RM_SetTime(time);
status = phreeqc_rm.RM_SetTimeStep(time_step);
status = phreeqc_rm.RM_RunCells();
c = phreeqc_rm.GetConcentrations();
status = phreeqc_rm.RM_Destroy();
% Set bou
