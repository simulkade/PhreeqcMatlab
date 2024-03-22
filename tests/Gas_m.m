% Create PhreeqcRM
nxyz = 20;
nthreads = 3;

phreeqc_rm = PhreeqcRM(nxyz, nthreads);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% There's no need to run RM_Create() since it has been moved to the PhreeqcRM constructor.
% phreeqc_rm = phreeqc_rm.RM_Create();
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Open files
status = phreeqc_rm.RM_SetFilePrefix('Gas_matlab');
phreeqc_rm.RM_OpenFiles();

% Set concentration units
status = phreeqc_rm.RM_SetUnitsSolution(2); % 1, mg/L; 2, mol/L; 3, kg/kgs
status = phreeqc_rm.RM_SetUnitsGasPhase(0); % 0, mol/L cell; 1, mol/L water; 2 mol/L rock

% Set initial porosity
por = 0.2 * ones(1, nxyz);
status = phreeqc_rm.RM_SetPorosity(por);

% Set initial saturation
sat = 0.5 * ones(1, nxyz);
status = phreeqc_rm.RM_SetSaturation(sat);

% Set printing of chemistry file
status = phreeqc_rm.RM_SetPrintChemistryOn(false, true, false); % workers, initial_phreeqc, utility

% Load database
status = phreeqc_rm.RM_LoadDatabase('../database/phreeqc.dat');

% Run file to define solutions and gases for initial conditions
status = phreeqc_rm.RM_RunFile(true, true, true, 'gas.pqi');

% Determine number of components and gas components
ncomps = phreeqc_rm.RM_FindComponents();
ngas = phreeqc_rm.RM_GetGasComponentsCount();

% Get list of gas component names
gcomps = phreeqc_rm.GetGasComponentsNames();

% Set array of initial conditions
ic1 = -1*ones(nxyz*7, 1);
ic2 = -1*ones(nxyz*7, 1);
f1 = ones(nxyz*7, 1);

for i = 1:nxyz
    ic1(i) = 1;              % Solution 1
    ic1(nxyz + i) = -1;      % Equilibrium phases none
    ic1(2*nxyz + i) = -1;     % Exchange 1
    ic1(3*nxyz + i) = -1;    % Surface none
    ic1(4*nxyz + i) = mod(i-1,3) + 1;    % Gas phase none
    ic1(5*nxyz + i) = -1;    % Solid solutions none
    ic1(6*nxyz + i) = -1;    % Kinetics none
end

status = phreeqc_rm.RM_InitialPhreeqc2Module(ic1,ic2,f1);

% Get gases
gas_moles = phreeqc_rm.GetGasCompMoles();
gas_p = phreeqc_rm.GetGasCompPressures();
gas_phi = phreeqc_rm.GetGasCompPhi();
PrintCells(gcomps, gas_moles, gas_p, gas_phi, nxyz, 'Initial conditions');

% multiply by 2
gas_moles = gas_moles * 2.0;
status = phreeqc_rm.RM_SetGasCompMoles(gas_moles);
gas_moles = phreeqc_rm.GetGasCompMoles();
gas_p = phreeqc_rm.GetGasCompPressures();
gas_phi = phreeqc_rm.GetGasCompPhi();
PrintCells(gcomps, gas_moles, gas_p, gas_phi, nxyz, 'Initial conditions times 2');

% eliminate CH4 in cell 0
gas_moles(1) = -1.0;
% Gas phase is removed from cell 1
gas_moles([2, nxyz + 2, 2 * nxyz + 2]) = -1.0;
status = phreeqc_rm.RM_SetGasCompMoles(gas_moles);
status = phreeqc_rm.RM_RunCells();
gas_moles = phreeqc_rm.GetGasCompMoles();
gas_p = phreeqc_rm.GetGasCompPressures();
gas_phi = phreeqc_rm.GetGasCompPhi();
PrintCells(gcomps, gas_moles, gas_p, gas_phi, nxyz, 'Remove some components');

% add CH4 in cell 0
gas_moles(1) = 0.02;
% Gas phase is added to cell 1; fixed pressure by default
gas_moles([2, nxyz + 2, 2 * nxyz + 2]) = [0.01, 0.02, 0.03];
status = phreeqc_rm.RM_SetGasCompMoles(gas_moles);
% Set volume for cell 1 and convert to fixed pressure gas phase
gas_volume = -ones(1, nxyz);
gas_volume(2) = 12.25;
status = phreeqc_rm.RM_SetGasPhaseVolume(gas_volume);
status = phreeqc_rm.RM_RunCells();
gas_moles = phreeqc_rm.GetGasCompMoles();
gas_p = phreeqc_rm.GetGasCompPressures();
gas_phi = phreeqc_rm.GetGasCompPhi();
PrintCells(gcomps, gas_moles, gas_p, gas_phi, nxyz, 'Add components back');

% Clean up
status = phreeqc_rm.RM_CloseFiles();

function PrintCells(gcomps, gas_moles, gas_p, gas_phi, nxyz, str)
    disp([' ', str]);
    % print cells 0,1,2
    for j = 1:3 % cell
        disp(['Cell: ', num2str(j - 1)]);
        disp('               Moles         P         Phi');
        for i = 1:3 % component
            k = (i - 1) * nxyz + j;
            fprintf('%8s  %10.4f  %10.4f  %10.4f\n', gcomps{i}, gas_moles(k), gas_p(k), gas_phi(k));
        end
    end
end
