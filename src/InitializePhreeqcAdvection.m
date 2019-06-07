function [outputArg1,outputArg2] = InitializePhreeqcAdvection( ...
    phreeqc_rm, phreeqc_input_file, data_base)
%INITIALIZEPHREEQCADVECTION Initializes a phreeqc instance with the phreeqc
%input file for inital and boundary conditions

% map transport grid to the reaction cells (1 to 1 since it is only 1D)
nxyz = phreeqc_rm.ncells;
grid2chem = -1*ones(nxyz, 1);

C = ReadPhreeqcFile(input_file); % read and clean the input file

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

end

