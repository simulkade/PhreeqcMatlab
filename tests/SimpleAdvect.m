nxyz = 20;
nthreads = 3;
phreeqc_rm = PhreeqcRM(nxyz, nthreads);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% There's no need to run RM_Create() since it has been moved to the PhreeqcRM constructor.
% phreeqc_rm = phreeqc_rm.RM_Create();
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set properties
status = phreeqc_rm.RM_SetComponentH2O(false);
phreeqc_rm.RM_UseSolutionDensityVolume(false);

% Open error, log, and output file
status = phreeqc_rm.RM_SetFilePrefix('SimpleAdvect_m');
phreeqc_rm.RM_OpenFiles();

% Set concentration units
status = phreeqc_rm.RM_SetUnitsSolution(2); % 1, mg/L; 2, mol/L; 3, kg/kgs
status = phreeqc_rm.RM_SetUnitsExchange(1); % 0, mol/L cell; 1, mol/L water; 2 mol/L rock

% Set conversion from seconds to user units (days)
time_conversion = 1.0 / 86400.0;
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set boundary condition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nbound = 1;
bc1 = zeros(1, nbound);
bc2 = -ones(1, nbound);
bc_f1 = ones(1, nbound);

bc_conc = phreeqc_rm.InitialPhreeqc2Concentrations(nbound, bc1, bc2, bc_f1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Transient loop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nsteps = 10;
pressure = ones(1, nxyz)*2.0;
temperature = ones(1, nxyz)*20.0;

status = phreeqc_rm.RM_SetPressure(pressure);
status = phreeqc_rm.RM_SetTemperature(temperature);
time_step = 86400;
status = phreeqc_rm.RM_SetTimeStep(time_step);

for isteps = 1:nsteps
    % Advection calculation
    str = sprintf('%s%10.1f%s', 'Beginning transport calculation      ', phreeqc_rm.RM_GetTime() * phreeqc_rm.RM_GetTimeConversion(), ' days\n');
    status = phreeqc_rm.RM_LogMessage(str);
    status = phreeqc_rm.RM_SetScreenOn(true);
    status = phreeqc_rm.RM_ScreenMessage(str);
    str = sprintf('%s%10.1f%s', '          Time step                  ', phreeqc_rm.RM_GetTimeStep() * phreeqc_rm.RM_GetTimeConversion(), ' days\n');
    status = phreeqc_rm.RM_LogMessage(str);
    status = phreeqc_rm.RM_ScreenMessage(str);

    % Advect one step (simpleadvection_c function assumed)
    c = simpleadvection(c, bc_conc, ncomps, nxyz, nbound);

    % Transfer data to PhreeqcRM for reactions
    status = phreeqc_rm.RM_SetConcentrations(c);          % Transported concentrations
    status = phreeqc_rm.RM_SetTimeStep(time_step);        % Time step for kinetic reactions
    time = time + time_step;
    status = phreeqc_rm.RM_SetTime(time);                 % Current time

    % Set print flag
    if isteps == nsteps
        status = phreeqc_rm.RM_SetSelectedOutputOn(1);       % enable selected output
        status = phreeqc_rm.RM_SetPrintChemistryOn(1, 0, 0); % print at last time step, workers, initial_phreeqc, utility
    else
        status = phreeqc_rm.RM_SetSelectedOutputOn(0);       % disable selected output
        status = phreeqc_rm.RM_SetPrintChemistryOn(0, 0, 0); % workers, initial_phreeqc, utility
    end

    % Run cells with transported conditions
    str = sprintf('%s%10.1f%s', 'Beginning reaction calculation       ', phreeqc_rm.RM_GetTime() * phreeqc_rm.RM_GetTimeConversion(), ' days\n');
    status = phreeqc_rm.RM_LogMessage(str);
    status = phreeqc_rm.RM_ScreenMessage(str);
    status = phreeqc_rm.RM_RunCells();

    % Transfer data from PhreeqcRM for transport
    c = phreeqc_rm.GetConcentrations();          % Concentrations after reaction
end

status = phreeqc_rm.RM_CloseFiles();
status = phreeqc_rm.RM_Destroy();

function c = simpleadvection(c, bc_conc, ncomps, nxyz, dim)
    for i = nxyz:-1:2
        for j = 1:ncomps
            c(i, j) = c(i - 1, j); % component j
        end
    end
    
    % Cell zero gets boundary condition
    for j = 1:ncomps
        c(1, j) = bc_conc(j* dim); % component j
    end
end
