function phreeqc_rm = PhreeqcAdvection(phreeqc_input_file, advection_input_file, data_base)
%PHREEQCTRANSPORT Reads a phreeqc input file (with the transport key) and
%creates a reactive transport simulation in FVTool and PhreeqcMatlab. This
%function works only on 1D domains. For the 2D and 3D domains, see the
%example folder.
%TODO: simple 2D cases based on modified phreeqc input files.
%   
nthreads = 1; % provide as an input later
% Read the input file
C = ReadPhreeqcFile(phreeqc_input_file); % read and clean the input file

% Find the transport or advection keys and create the tranport model
ind_cells = contains(C, '-cells');
nxyz = sscanf(C{ind_cells}, '-cells %f');

n_shifts = sscanf(C{contains(C, '-shifts')}, '-shifts %f');
if any(contains(C, '-time_step'))
    dt = sscanf(C{contains(C, '-time_step')}, '-time_step %f');
else
    dt = 1.0; % if no time step specified, dt = 1.0 s
    warning('No -time_step specified. A default value of 1.0 s is assigned');
end

% Create the phreeqcrm object
phreeqc_rm = PhreeqcRM(nxyz, nthreads);
phreeqc_rm = phreeqc_rm.RM_Create();

status = phreeqc_rm.RM_SetErrorHandlerMode(1);
status = phreeqc_rm.RM_SetComponentH2O(false);
status = phreeqc_rm.RM_SetRebalanceFraction(0.5);
status = phreeqc_rm.RM_SetRebalanceByCell(true);
phreeqc_rm.RM_UseSolutionDensityVolume(false);
phreeqc_rm.RM_SetPartitionUZSolids(false);
% status = phreeqc_rm.RM_SetFilePrefix('Advect');
% phreeqc_rm.RM_OpenFiles();

status = phreeqc_rm.RM_SetUnitsSolution(2);           % 1, mg/L; 2, mol/L; 3, kg/kgs
status = phreeqc_rm.RM_SetUnitsPPassemblage(1);       % 0, mol/L cell; 1, mol/L water; 2 mol/L rock
status = phreeqc_rm.RM_SetUnitsExchange(1);           % 0, mol/L cell; 1, mol/L water; 2 mol/L rock
status = phreeqc_rm.RM_SetUnitsSurface(1);            % 0, mol/L cell; 1, mol/L water; 2 mol/L rock
status = phreeqc_rm.RM_SetUnitsGasPhase(1);           % 0, mol/L cell; 1, mol/L water; 2 mol/L rock
status = phreeqc_rm.RM_SetUnitsSSassemblage(1);       % 0, mol/L cell; 1, mol/L water; 2 mol/L rock
status = phreeqc_rm.RM_SetUnitsKinetics(1);           % 0, mol/L cell; 1, mol/L water; 2 mol/L rock



% status = phreeqc_rm.RM_LoadDatabase(database_file(data_base)); % load the database
% status = phreeqc_rm.RM_RunFile(true, true, true, input_file); % run the input file
end

