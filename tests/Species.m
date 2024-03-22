% Create PhreeqcRM
nxyz = 40;
nthreads = 3;
phreeqc_rm = PhreeqcRM(nxyz, nthreads);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% There's no need to run RM_Create() since it has been moved to the PhreeqcRM constructor.
% phreeqc_rm = phreeqc_rm.RM_Create();
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
status = phreeqc_rm.RM_SetErrorHandlerMode(1); % 1 = throw exception on error
status = phreeqc_rm.RM_SetSpeciesSaveOn(true);

% Open files
status = phreeqc_rm.RM_SetFilePrefix('Species');
phreeqc_rm.RM_OpenFiles();

% Set concentration units
status = phreeqc_rm.RM_SetUnitsSolution(2);      % 1, mg/L; 2, mol/L; 3, kg/kgs
status = phreeqc_rm.RM_SetUnitsPPassemblage(1);  % 0, mol/L cell; 1, mol/L water; 2 mol/kg rock
status = phreeqc_rm.RM_SetUnitsExchange(1);      % 0, mol/L cell; 1, mol/L water; 2 mol/kg rock
status = phreeqc_rm.RM_SetUnitsSurface(1);       % 0, mol/L cell; 1, mol/L water; 2 mol/kg rock
status = phreeqc_rm.RM_SetUnitsGasPhase(1);      % 0, mol/L cell; 1, mol/L water; 2 mol/kg rock
status = phreeqc_rm.RM_SetUnitsSSassemblage(1);  % 0, mol/L cell; 1, mol/L water; 2 mol/kg rock
status = phreeqc_rm.RM_SetUnitsKinetics(1);      % 0, mol/L cell; 1, mol/L water; 2 mol/kg rock

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

% Demonstration of mapping, two equivalent rows by symmetry
grid2chem = -1 * ones(1, nxyz);
grid2chem(1:nxyz/2) = 0:nxyz/2-1;
grid2chem(nxyz/2+1:end) = 0:nxyz/2-1;
status = phreeqc_rm.RM_CreateMapping(grid2chem);

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

% Print some of the reaction module information
fprintf('Number of threads:                                %d\n', phreeqc_rm.RM_GetThreadCount());
fprintf('Number of grid cells in the user''s model:         %d\n', phreeqc_rm.RM_GetGridCellCount());
fprintf('Number of chemistry cells in the reaction module: %d\n', phreeqc_rm.RM_GetChemistryCellCount());
fprintf('Number of components for transport:               %d\n', phreeqc_rm.RM_GetComponentCount());

components = phreeqc_rm.GetComponents();
gfw = phreeqc_rm.GetGfw();

for i = 1:ncomps
    fprintf('%s    %.4f\n', components{i}, gfw(i));
end
fprintf('\n');

% Determine species information
species = phreeqc_rm.GetSpeciesNames();
species_z = phreeqc_rm.GetSpeciesZ();
%species_d = phreeqc_rm.GetSpeciesD25(); % failed to retreive data
species_on = phreeqc_rm.RM_GetSpeciesSaveOn();
nspecies = phreeqc_rm.RM_GetSpeciesCount();

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

c = phreeqc_rm.GetSpeciesConcentrations();
lg = phreeqc_rm.GetSpeciesLog10Gammas();
lm = phreeqc_rm.GetSpeciesLog10Molalities();
component_c = phreeqc_rm.GetConcentrations();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set boundary condition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nbound = 1;
nspecies = phreeqc_rm.RM_GetSpeciesCount();
bc1 = zeros(1, nbound);
bc2 = -ones(1, nbound);
bc_f1 = 1.0*ones(1, nbound);
bc_conc = 1.0*ones(1, nspecies*nbound);

[status,bc_conc] = phreeqc_rm.RM_InitialPhreeqc2SpeciesConcentrations(bc_conc, nbound, bc1, bc2, bc_f1);

% Transient loop
nsteps = 10;
initial_density = ones(1, nxyz);
temperature = 20.0 * ones(1, nxyz);
pressure = 2.0 * ones(1, nxyz);

phreeqc_rm.RM_SetDensity(initial_density);
phreeqc_rm.RM_SetTemperature(temperature);
phreeqc_rm.RM_SetPressure(pressure);

time_step = 86400.0;
status = phreeqc_rm.RM_SetTimeStep(time_step);

component_c = zeros(nxyz * ncomps, 1);

for isteps = 1:nsteps
    % Transport calculation here
    fprintf('Beginning transport calculation             %.2f days\n', phreeqc_rm.RM_GetTime() * phreeqc_rm.RM_GetTimeConversion());
    fprintf('          Time step                         %.2f days\n', phreeqc_rm.RM_GetTimeStep() * phreeqc_rm.RM_GetTimeConversion());

    c = speciesAdvection(c, bc_conc, nspecies, nxyz, nbound);

    % Set print flag
    if isteps == nsteps
        status = phreeqc_rm.RM_SetSelectedOutputOn(1);       % enable selected output
        status = phreeqc_rm.RM_SetPrintChemistryOn(1, 0, 0); % print at last time step, workers, initial_phreeqc, utility
    else
        status = phreeqc_rm.RM_SetSelectedOutputOn(0);       % disable selected output
        status = phreeqc_rm.RM_SetPrintChemistryOn(0, 0, 0); % workers, initial_phreeqc, utility
    end

    status = phreeqc_rm.RM_SetPorosity(por);
    status = phreeqc_rm.RM_SetSaturation(sat);
    status = phreeqc_rm.RM_SetTemperature(temperature);
    status = phreeqc_rm.RM_SetPressure(pressure);
    status = phreeqc_rm.RM_SpeciesConcentrations2Module(c);
    status = phreeqc_rm.RM_SetTimeStep(time_step);
    time = time + time_step;
    status = phreeqc_rm.RM_SetTime(time);

    % Run cells with transported conditions
    fprintf('Beginning reaction calculation              %.2f days\n', time * phreeqc_rm.RM_GetTimeConversion());

    status = phreeqc_rm.RM_RunCells();

    % Transfer data from PhreeqcRM for transport
    c = phreeqc_rm.GetSpeciesConcentrations();

    lg = phreeqc_rm.GetSpeciesLog10Gammas();
    lm = phreeqc_rm.GetSpeciesLog10Molalities();
    component_c = phreeqc_rm.GetConcentrations();

    density = phreeqc_rm.GetDensity();
    volume = phreeqc_rm.GetSolutionVolume();

    % Print results at last time step
    if isteps == nsteps
        % Loop through possible multiple selected output definitions
        for isel = 0:phreeqc_rm.RM_GetSelectedOutputCount()-1
            n_user = phreeqc_rm.RM_GetNthSelectedOutputUserNumber(isel);
            status = phreeqc_rm.RM_SetCurrentSelectedOutputUserNumber(n_user);
            fprintf('Selected output sequence number: %d\n', isel);
            fprintf('Selected output user number:     %d\n', n_user);
            
            % Get double array of selected output values
            col = phreeqc_rm.RM_GetSelectedOutputColumnCount();
            selected_out = zeros(nxyz, col);
            [status, selected_out] = phreeqc_rm.RM_GetSelectedOutput(selected_out);
            
            % Print results
            for i = 1:1
                fprintf('Cell number %d\n', i);
                fprintf('     Density: %f\n', density(i));
                fprintf('     Volume:  %f\n', volume(i));
                fprintf('     Components: \n');
                for j = 1:ncomps
                    fprintf('          %2d %10s: %10.4f\n', j, components{j}, component_c(i, j));
                end
                fprintf('     Species: \n');
                str = phreeqc_rm.GetSpeciesNames();
                for j = 1:nspecies
                    fprintf('          %2d %10s: %10.2e %10.4f %10.2e\n', j, str{j}, c(i, j), lg(i, j), lm(i, j));
                end
                fprintf('     Selected output: \n');
                heading = phreeqc_rm.GetSelectedOutputHeadings(n_user);
                for j = 1:col
                    fprintf('          %2d %10s: %10.4f\n', j, heading{j}, selected_out(i, j));
                end
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Additional features and finalize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Clean up
status = phreeqc_rm.RM_CloseFiles();
status = phreeqc_rm.RM_Destroy();

function c = speciesAdvection(c, bc_conc, ncomps, nxyz, dim)
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
