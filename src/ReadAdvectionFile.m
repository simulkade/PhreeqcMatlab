function phreeqc_rm = ReadAdvectionFile(advection_input_file)
%READADVECTIONFILE Reads a PhreeqcMatlab advection input file (with the
%special PhreeqcMatlab keywords and creates and initializes a PhreeqcRM
%instance. See the documents and examples for the PhreeqcMatlab keywords.

% reads the input file and gets rid of the comments
C = ReadPhreeqcFile(advection_input_file);

% go through the input file and extract the relevant data for each keyword
nxyz = sscanf(C{contains(C, 'cells')}, 'cells %f');
nthreads = sscanf(C{contains(C, 'threads')}, 'threads %f');

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
end

