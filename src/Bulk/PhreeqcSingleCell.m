function phreeqc_rm = PhreeqcSingleCell(input_file, data_base)
% PHREEQCSINGLECELL Creates a phreeqcrm intance that works on a single reaction cell
%   input_file: the full name or address to the phreeqc input file
% in the input file, all the phase, surface, exchange, etc must be numbered
% as number 1 for this function to work properly. See the example input
% file. The input file must be clean at the moment. No commenting out the
% lines, although I do a bit of clean up in the input file.

phreeqc_rm = PhreeqcRM(1, 1); % one cell, one thread (constructor also calls RM_Create)
status = phreeqc_rm.RM_SetComponentH2O(false);
status = phreeqc_rm.RM_SetUnitsSolution(2);           % 1, mg/L; 2, mol/L; 3, kg/kgs
status = phreeqc_rm.RM_SetUnitsPPassemblage(1);       % 0, mol/L cell; 1, mol/L water; 2 mol/L rock
status = phreeqc_rm.RM_SetUnitsExchange(1);           % 0, mol/L cell; 1, mol/L water; 2 mol/L rock
status = phreeqc_rm.RM_SetUnitsSurface(1);            % 0, mol/L cell; 1, mol/L water; 2 mol/L rock
status = phreeqc_rm.RM_SetUnitsGasPhase(1);           % 0, mol/L cell; 1, mol/L water; 2 mol/L rock
status = phreeqc_rm.RM_SetUnitsSSassemblage(1);       % 0, mol/L cell; 1, mol/L water; 2 mol/L rock
status = phreeqc_rm.RM_SetUnitsKinetics(1);           % 0, mol/L cell; 1, mol/L water; 2 mol/L rock
phreeqc_rm.RM_UseSolutionDensityVolume(true);

status = phreeqc_rm.RM_SetPorosity(1.0);             % If pororosity changes due to compressibility
status = phreeqc_rm.RM_SetSaturation(1.0);           % If saturation changes
    
status = phreeqc_rm.RM_LoadDatabase(database_file(data_base)); % load the database
status = phreeqc_rm.RM_RunFile(true, true, true, input_file); % run the input file

ncomps = phreeqc_rm.RM_FindComponents();
comp_name = phreeqc_rm.GetComponents();

% look for the keywords in the inputfile
C = ReadPhreeqcFile(input_file); % read and clean the input file

if any(contains(C, 'SELECTED_OUTPUT'))
    status = phreeqc_rm.RM_SetSelectedOutputOn(true);
end

% Detect which reactant blocks the input defines and build the 1-cell
% initial-condition vectors (see InitialConditions for the slot mapping).
present = InitialConditions.detect(C);
if ~present(InitialConditions.SOLUTION)
    error('PhreeqcMatlab: SOLUTION 1 must be defined in the input file.');
end
[ic1, ic2, f1] = InitialConditions.vectors(present, 1);

status = phreeqc_rm.RM_InitialPhreeqc2Module(ic1, ic2, f1);
status = phreeqc_rm.RM_RunCells();

end

