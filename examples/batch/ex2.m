% a simple phreeqc example that plays with solution concentration
% adapted from phreeqc ex2 file. Change the temperature and observe its
% effect on the solubility of two minerals
clc
% phreeqc_rm = PhreeqcRM(1, 1); % one cell, one thread
phreeqc_rm.RM_UseSolutionDensityVolume(true);
status = phreeqc_rm.RM_LoadDatabase('../../database/phreeqc.dat');
status = phreeqc_rm.RM_RunFile(true, true, true, 'ex2_input.pqc');

ncomps = phreeqc_rm.RM_FindComponents();
comp_name = phreeqc_rm.GetComponents();

status = phreeqc_rm.RM_SetSelectedOutputOn(true);


ic1 = -1*ones(7, 1);
ic2 = -1*ones(7, 1);
f1 = ones(7, 1);
ic1(1) = 1;              % Solution 1
ic1(2) = 1;      % Equilibrium phases none
ic1(3) = -1;     % Exchange 1
ic1(4) = -1;    % Surface none
ic1(5) = -1;    % Gas phase none
ic1(6) = -1;    % Solid solutions none
ic1(7) = -1;    % Kinetics none
status = phreeqc_rm.RM_InitialPhreeqc2Module(ic1, ic2, f1);

temperature = 25.0; % degree C
phreeqc_rm.RM_SetTemperature(temperature);

status = phreeqc_rm.RM_RunCells();
c_out = phreeqc_rm.GetConcentrations();




status = phreeqc_rm.RM_Destroy();


