% Create PhreeqcRM
nxyz = 40;
hydraulic_K = (0:nxyz-1) * 2.0;

% OpenMP
nthreads = 3;
phreeqc_rm = PhreeqcRM(nxyz, nthreads);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% There's no need to run RM_Create() since it has been moved to the PhreeqcRM constructor.
% phreeqc_rm = phreeqc_rm.RM_Create();
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
status = phreeqc_rm.RM_SetErrorHandlerMode(1);
status = phreeqc_rm.RM_SetComponentH2O(false);
status = phreeqc_rm.RM_SetRebalanceFraction(0.5);
status = phreeqc_rm.RM_SetRebalanceByCell(true);
phreeqc_rm.RM_UseSolutionDensityVolume(false);
phreeqc_rm.RM_SetPartitionUZSolids(false);
status = phreeqc_rm.RM_SetFilePrefix('Advect');
phreeqc_rm.RM_OpenFiles();

% Set concentration units
status = phreeqc_rm.RM_SetUnitsSolution(2); % 1, mg/L; 2, mol/L; 3, kg/kgs
status = phreeqc_rm.RM_SetUnitsPPassemblage(1); % 0, mol/L cell; 1, mol/L water; 2 mol/L rock
status = phreeqc_rm.RM_SetUnitsExchange(1); % 0, mol/L cell; 1, mol/L water; 2 mol/L rock
status = phreeqc_rm.RM_SetUnitsSurface(1); % 0, mol/L cell; 1, mol/L water; 2 mol/L rock
status = phreeqc_rm.RM_SetUnitsGasPhase(1); % 0, mol/L cell; 1, mol/L water; 2 mol/L rock
status = phreeqc_rm.RM_SetUnitsSSassemblage(1); % 0, mol/L cell; 1, mol/L water; 2 mol/L rock
status = phreeqc_rm.RM_SetUnitsKinetics(1); % 0, mol/L cell; 1, mol/L water; 2 mol/L rock
% Set conversion from seconds to user units (days)
time_conversion = 1.0 / 86400;
status = phreeqc_rm.RM_SetTimeConversion(time_conversion);

% Set representative volume
rv = ones(1, nxyz);
status = phreeqc_rm.RM_SetRepresentativeVolume(rv);

% Set initial porosity
por = 0.2 * ones(1, nxyz);
status = phreeqc_rm.RM_SetPorosity(por);

% Set initial saturation
sat = ones(1, nxyz);
status = phreeqc_rm.RM_SetSaturation(sat);

% Set cells to print chemistry when print chemistry is turned on
print_chemistry_mask = zeros(1, nxyz);
print_chemistry_mask(1:nxyz/2) = 1;
status = phreeqc_rm.RM_SetPrintChemistryMask(print_chemistry_mask);
status = phreeqc_rm.RM_SetPartitionUZSolids(0);

% Demonstation of mapping, two equivalent rows by symmetry
grid2chem = -ones(1, nxyz);
grid2chem(1:nxyz/2) = 0:nxyz/2-1;
grid2chem(nxyz/2+1:end) = 0:nxyz/2-1;
status = phreeqc_rm.RM_CreateMapping(grid2chem);
if status < 0
    phreeqc_rm.RM_DecodeError(status);
end
nchem = phreeqc_rm.RM_GetChemistryCellCount();

% Set initial conditions
status = phreeqc_rm.RM_SetPrintChemistryOn(false, true, false); % workers, initial_phreeqc, utility
status = phreeqc_rm.RM_LoadDatabase('../database/phreeqc.dat');

if ~strcmp(status,'IRM_OK')
    error(phreeqc_rm.RM_GetErrorString());
end

workers = true; % Worker instances do the reaction calculations for transport
initial_phreeqc = true; % InitialPhreeqc instance accumulates initial and boundary conditions
utility = true; % Utility instance is available for processing
status = phreeqc_rm.RM_RunFile(workers, initial_phreeqc, utility, 'advect.pqi');

initial_phreeqc = false;
input = 'DELETE; -all';
status = phreeqc_rm.RM_RunString(workers, initial_phreeqc, utility, input);

ncomps = phreeqc_rm.RM_FindComponents();

% Print some of the reaction module information
disp(['Number of threads:                                ' num2str(phreeqc_rm.RM_GetThreadCount())]);
disp(['Number of MPI processes:                          ' num2str(phreeqc_rm.RM_GetMpiTasks())]);
disp(['MPI task number:                                  ' num2str(phreeqc_rm.RM_GetMpiMyself())]);
s_name = blanks(27);
phreeqc_rm.RM_GetFilePrefix(s_name, length(s_name))
disp(['File prefix:                                      ' s_name]);
disp(['Number of grid cells in the user''s model:         ' num2str(phreeqc_rm.RM_GetGridCellCount())]);
disp(['Number of chemistry cells in the reaction module: ' num2str(phreeqc_rm.RM_GetChemistryCellCount())]);
disp(['Number of components for transport:               ' num2str(phreeqc_rm.RM_GetComponentCount())]);

gfw = phreeqc_rm.GetGfw(); % Returns a reference to a vector of doubles that contains the gram-formula weight of each component. 
for i = 1:ncomps
    components = phreeqc_rm.GetComponents(); 
    str = sprintf('%10s    %10.3f\n', components{i}, gfw(i));
    disp(str);
end

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

module_cells = zeros(1, 2);

module_cells(1) = 18;
module_cells(2) = 19;

status = phreeqc_rm.RM_InitialPhreeqcCell2Module(-1, module_cells, 2);

% Initial equilibration of cells
time = 0.0;
time_step = 0.0;
c = zeros(ncomps, nxyz);

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
density = ones(nxyz, 1);
pressure = 2.0 * ones(nxyz, 1);
temperature = 20.0 * ones(nxyz, 1);
sat_calc = zeros(nxyz, 1);

status = phreeqc_rm.RM_SetDensity(density);
status = phreeqc_rm.RM_SetPressure(pressure);
status = phreeqc_rm.RM_SetTemperature(temperature);
time_step = 86400;
status = phreeqc_rm.RM_SetTimeStep(time_step);

for isteps = 1:nsteps
    % Advection calculation
    str = sprintf('%s%10.1f%s', 'Beginning transport calculation      ', phreeqc_rm.RM_GetTime() * phreeqc_rm.RM_GetTimeConversion(), ' days\n');
    status = phreeqc_rm.RM_LogMessage(str);
    disp(str);
    status = phreeqc_rm.RM_SetScreenOn(1);
    str = sprintf('%s%10.1f%s', '          Time step                  ', phreeqc_rm.RM_GetTimeStep() * phreeqc_rm.RM_GetTimeConversion(), ' days\n');
    status = phreeqc_rm.RM_LogMessage(str);
    disp(str);
    c = advection(c, bc_conc, ncomps, nxyz, nbound);
    
    % Transfer data to PhreeqcRM for reactions
    status = phreeqc_rm.RM_SetPorosity(por);              % If porosity changes 
    status = phreeqc_rm.RM_SetSaturation(sat);        % If saturation changes
    status = phreeqc_rm.RM_SetTemperature(temperature);   % If temperature changes
    status = phreeqc_rm.RM_SetPressure(pressure);         % If pressure changes
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
    disp(str);
    
    % Demonstration of state 
    status = phreeqc_rm.RM_StateSave(1);
    status = phreeqc_rm.RM_StateApply(1);
    status = phreeqc_rm.RM_StateDelete(1);
    
    status = phreeqc_rm.RM_RunCells();
    
    % Transfer data from PhreeqcRM for transport
    c       = phreeqc_rm.GetConcentrations();          % Concentrations after reaction 
    density = phreeqc_rm.GetDensity();           % Density after reaction
    volume  = phreeqc_rm.GetSolutionVolume();     % Solution volume after reaction
    sat_calc = phreeqc_rm.GetSaturation();       % Saturation after reaction
    
    % Print results at last time step
    if isteps == nsteps
        
        % Loop through possible multiple selected output definitions
        for isel = 0:phreeqc_rm.RM_GetSelectedOutputCount()-1
            n_user = phreeqc_rm.RM_GetNthSelectedOutputUserNumber(isel);
            status = phreeqc_rm.RM_SetCurrentSelectedOutputUserNumber(n_user);
            fprintf("Selected output sequence number: %d\n", isel);
            fprintf("Selected output user number:     %d\n", n_user);
            
            % Get double array of selected output values
            col = phreeqc_rm.RM_GetSelectedOutputColumnCount();
            selected_out = phreeqc_rm.GetSelectedOutput(n_user);
            
            % Print results
            for i = 1:min(phreeqc_rm.RM_GetSelectedOutputRowCount()/2, 1)
                fprintf("Cell number %d\n", i);
                fprintf("     Density: %f\n", density(i));
                fprintf("     Volume:  %f\n", volume(i));
                fprintf("     Components: \n");
                for j = 1:ncomps
                    fprintf("          %2d %10s: %10.4f\n", j, components{j}, c((j - 1) * nxyz + i));
                end
                fprintf("     Selected output: \n");
                heading = phreeqc_rm.GetSelectedOutputHeadings(n_user);
                for j = 1:col
                    fprintf("          %2d %10s: %10.4f\n", j, heading{j}, selected_out((j - 1) * nxyz + i));
                end
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% finalize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Clean up
status = phreeqc_rm.RM_CloseFiles();
status = phreeqc_rm.RM_Destroy();

function c = advection(c, bc_conc, ncomps, nxyz, dim)
    for i = nxyz/2:-1:2
        for j = 1:ncomps
            c(i, j) = c(i - 1, j); % component j
        end
    end
    
    % Cell zero gets boundary condition
    for j = 1:ncomps
        c(1, j) = bc_conc(j* dim); % component j
    end
end
