function phreeqc_rm = PhreeqcSingleCell(input_file, data_base)
% PHREEQCSINGLECELL Creates a phreeqcrm intance that works on a single reaction cell
%   input_file: the full name or address to the phreeqc input file
% in the input file, all the phase, surface, exchange, etc must be numbered
% as number 1 for this function to work properly. See the example input
% file. The input file must be clean at the moment. No commenting out the
% lines, although I do a bit of clean up in the input file.

phreeqc_rm = PhreeqcRM(1, 1); % one cell, one thread
phreeqc_rm = phreeqc_rm.RM_Create(); % create a PhreeqcRM instance
phreeqc_rm.RM_UseSolutionDensityVolume(true);
status = phreeqc_rm.RM_LoadDatabase(database_file(data_base)); % load the database
status = phreeqc_rm.RM_RunFile(true, true, true, input_file); % run the input file

ncomps = phreeqc_rm.RM_FindComponents();
comp_name = phreeqc_rm.GetComponents();

ic1 = -1*ones(7, 1);
ic2 = -1*ones(7, 1);
f1 = ones(7, 1);

% look for the keywords in the inputfile
fid = fopen(input_file, 'r');
C = textscan(fid, '%s','Delimiter',''); % read the input file into a cell array
fclose(fid);
C = C{:}; % get rid of cells in cell C

% clean the comments:
ind_comment = cellfun(@(x)(x(1)=='#'), C);
C(ind_comment) = {' '};

if any(contains(C, 'SELECTED_OUTPUT')) % Surface 1
    status = phreeqc_rm.RM_SetSelectedOutputOn(true);
end

if ~any(contains(C, 'SOLUTION'))
    error('PhreeqcMatlab: SOLUTION 1 must be defined in the input file.');
end

ic1(1) = 1;              % Solution 1

% in phreeqc: EQUILIBRIUM_PHASES is the keyword for the data block. Optionally, EQUILIBRIUM , EQUILIBRIA , PURE_PHASES , PURE .
if any(contains(C, 'EQUILIBRIUM_PHASES')) ||  any(contains(C, 'EQUILIBRIUM')) || any(contains(C, ' EQUILIBRIA')) || any(contains(C, ' PURE_PHASES')) || any(contains(C, ' PURE'))
    ic1(2) = 1;      % Equilibrium phases
end

% Exchange species
if any(contains(C, 'EXCHANGE'))
    ic1(3) = 1;     % Exchange 1
end

% Surface species

if any(contains(C, 'SURFACE')) 
    ic1(4) = 1; % Surface 1
end

% Gas phase
if any(contains(C, 'GAS_PHASE')) % Surface 1
    ic1(5) = 1;    % Gas phase 1
end

% Solid solution
if any(contains(C, 'SOLID_SOLUTION')) % Surface 1
    ic1(6) = 1;    % Solid solutions 1
end

% Kinetics
if any(contains(C, 'KINETICS')) % Surface 1
    ic1(7) = 1;    % Kinetics 1
end

status = phreeqc_rm.RM_InitialPhreeqc2Module(ic1, ic2, f1);
status = phreeqc_rm.RM_RunCells();

end

