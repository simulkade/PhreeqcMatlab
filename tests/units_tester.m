% Create PhreeqcRM
nxyz = 3;
nthreads = 3;
phreeqc_rm = PhreeqcRM(nxyz, nthreads);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% There's no need to run RM_Create() since it has been moved to the PhreeqcRM constructor.
% phreeqc_rm = phreeqc_rm.RM_Create();
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
status = phreeqc_rm.RM_SetErrorOn(true);
status = phreeqc_rm.RM_SetErrorHandlerMode(1);
status = phreeqc_rm.RM_SetFilePrefix('Advect_cpp');
if (phreeqc_rm.RM_GetMpiMyself() == 0)
    phreeqc_rm.RM_OpenFiles();
end

% Set concentration units
status = phreeqc_rm.RM_SetUnitsSolution(1);      %  1, mg/L; 2, mol/L; 3, kg/kgs
status = phreeqc_rm.RM_SetUnitsPPassemblage(2);  %  0, mol/L cell; 1, mol/L water; 2 mol/L rock
status = phreeqc_rm.RM_SetUnitsExchange(1);      %  0, mol/L cell; 1, mol/L water; 2 mol/L rock
status = phreeqc_rm.RM_SetUnitsSurface(1);       %  0, mol/L cell; 1, mol/L water; 2 mol/L rock
status = phreeqc_rm.RM_SetUnitsGasPhase(1);      %  0, mol/L cell; 1, mol/L water; 2 mol/L rock
status = phreeqc_rm.RM_SetUnitsSSassemblage(1);  %  0, mol/L cell; 1, mol/L water; 2 mol/L rock
status = phreeqc_rm.RM_SetUnitsKinetics(1);      %  0, mol/L cell; 1, mol/L water; 2 mol/L rock
% Set representative volume
rv = ones(1, nxyz);

status = phreeqc_rm.RM_SetRepresentativeVolume(rv);

% Set current porosity
por = 0.2 * ones(1, nxyz);

status = phreeqc_rm.RM_SetPorosity(por);

% Set saturation
sat = ones(1, nxyz);
status = phreeqc_rm.RM_SetSaturation(sat);
% Set printing of chemistry file
status = phreeqc_rm.RM_SetPrintChemistryOn(false, true, false); % workers, initial_phreeqc, utility

% --------------------------------------------------------------------------
% Set initial conditions
% --------------------------------------------------------------------------

% Load database
status = phreeqc_rm.RM_LoadDatabase('../database/phreeqc.dat');
% Run file to define solutions and reactants for initial conditions, selected output
workers = true;
initial_phreeqc = true;
utility = false;
status = phreeqc_rm.RM_RunFile(workers, initial_phreeqc, utility, 'units.pqi');
status = phreeqc_rm.RM_RunString(true, false, true, 'DELETE; -all');
%status = phreeqc_rm.SetFilePrefix("Units_InitialPhreeqc_2");
if (phreeqc_rm.RM_GetMpiMyself() == 0)
    phreeqc_rm.RM_OpenFiles();
end
% Set reference to components
ncomps = phreeqc_rm.RM_FindComponents();
components = phreeqc_rm.GetComponents();

% Set initial conditions
cell_numbers = 0;
status = phreeqc_rm.RM_InitialPhreeqcCell2Module(1, cell_numbers, 1);
cell_numbers = 1;
status = phreeqc_rm.RM_InitialPhreeqcCell2Module(2, cell_numbers, 1);
cell_numbers = 2;
status = phreeqc_rm.RM_InitialPhreeqcCell2Module(3, cell_numbers, 1);

% Retrieve concentrations
status = phreeqc_rm.RM_SetFilePrefix('Advect_cpp_units_worker');
if (phreeqc_rm.RM_GetMpiMyself() == 0)
    phreeqc_rm.RM_OpenFiles();
end
print_mask = ones(1, 3);
phreeqc_rm.RM_SetPrintChemistryMask(print_mask);
phreeqc_rm.RM_SetPrintChemistryOn(true, true, true);
status = phreeqc_rm.RM_RunCells();
c = phreeqc_rm.GetConcentrations();
so = phreeqc_rm.GetSelectedOutput(1);
headings = phreeqc_rm.GetSelectedOutputHeadings(1);
disp(headings);
for i = 1:nxyz
    fprintf('%d   %.4f\n', i - 1, so(i));
end

status = phreeqc_rm.RM_CloseFiles();
status = phreeqc_rm.RM_Destroy();
