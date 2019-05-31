function Phreeqc_rm = PhreeqcSingleCell(input_file, data_base)
%PHREEQCSINGLECELL Creates a phreeqcrm intance that works on a single reaction cell
%   input_file: the full name or address to the phreeqc input file
phreeqc_rm = PhreeqcRM(1, 1); % one cell, one thread
phreeqc_rm = phreeqc_rm.RM_Create(); % create a PhreeqcRM instance
phreeqc_rm.RM_UseSolutionDensityVolume(true);
status = phreeqc_rm.RM_LoadDatabase(databasefile(data_base)); % load the database
status = phreeqc_rm.RM_RunFile(true, true, true, input_file); % run the input file

ncomps = phreeqc_rm.RM_FindComponents();
comp_name = phreeqc_rm.GetComponents();

status = phreeqc_rm.RM_SetSelectedOutputOn(true);


ic1 = -1*ones(7, 1);
ic2 = -1*ones(7, 1);
f1 = ones(7, 1);

% look for the keywords in the inputfile
fid = fopen(input_file, 'r');
C = textscan(fid, '%s','Delimiter',''); % read the input file into a cell array
fclose(fid);
C = C{:}; % get rid of cells in cell

if any(contains(C, 'EQUILIBRIUM_PHASES'))
    ic1(2) = 1;      % Equilibrium phases
end



ic1(1) = 1;              % Solution 1
ic1(3) = -1;     % Exchange 1
ic1(4) = -1;    % Surface none
ic1(5) = -1;    % Gas phase none
ic1(6) = -1;    % Solid solutions none
ic1(7) = -1;    % Kinetics none
status = phreeqc_rm.RM_InitialPhreeqc2Module(ic1, ic2, f1);
end

