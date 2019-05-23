% This script is adopted from the advection_cpp.cpp file of phreeqcrm

clc

nxyz = 40;
nthreads = 2;

phreeqc_rm = PhreeqcRM(nxyz, nthreads);

status = phreeqc_rm.RM_SetErrorHandlerMode(1);
status = phreeqc_rm.RM_SetComponentH2O(false);
status = phreeqc_rm.RM_SetRebalanceFraction(0.5);
status = phreeqc_rm.RM_SetRebalanceByCell(true);
phreeqc_rm.RM_UseSolutionDensityVolume(false);
phreeqc_rm.RM_SetPartitionUZSolids(false);
status = phreeqc_rm.RM_SetFilePrefix('Advect_cpp');
phreeqc_rm.RM_OpenFiles();

status = phreeqc_rm.RM_SetUnitsSolution(2);           % 1, mg/L; 2, mol/L; 3, kg/kgs
status = phreeqc_rm.RM_SetUnitsPPassemblage(1);       % 0, mol/L cell; 1, mol/L water; 2 mol/L rock
status = phreeqc_rm.RM_SetUnitsExchange(1);           % 0, mol/L cell; 1, mol/L water; 2 mol/L rock
status = phreeqc_rm.RM_SetUnitsSurface(1);            % 0, mol/L cell; 1, mol/L water; 2 mol/L rock
status = phreeqc_rm.RM_SetUnitsGasPhase(1);           % 0, mol/L cell; 1, mol/L water; 2 mol/L rock
status = phreeqc_rm.RM_SetUnitsSSassemblage(1);       % 0, mol/L cell; 1, mol/L water; 2 mol/L rock
status = phreeqc_rm.RM_SetUnitsKinetics(1);           % 0, mol/L cell; 1, mol/L water; 2 mol/L rock

time_conversion = 1.0/86400;
status = phreeqc_rm.RM_SetTimeConversion(time_conversion);

% Set representative volume
rv = ones(nxyz, 1);
status = phreeqc_rm.RM_SetRepresentativeVolume(rv);
% Set initial porosity
por = ones(nxyz, 1)*0.2;
status = phreeqc_rm.RM_SetPorosity(por);
% Set initial saturation
sat = ones(nxyz, 1)*1.0;
status = phreeqc_rm.RM_SetSaturation(sat);
% Set cells to print chemistry when print chemistry is turned on
print_chemistry_mask = zeros(nxyz, 1);
print_chemistry_mask(1:nxyz/2) = 1;
status = phreeqc_rm.RM_SetPrintChemistryMask(print_chemistry_mask);
% test getters (they are not available in the C interface)
% const std::vector<int> & print_chemistry_mask1 = phreeqc_rm.RM_GetPrintChemistryMask();
% const std::vector<bool> & print_on = phreeqc_rm.RM_GetPrintChemistryOn();
% bool rebalance = phreeqc_rm.RM_GetRebalanceByCell();
% double f_rebalance = phreeqc_rm.RM_GetRebalanceFraction();
% bool so_on = phreeqc_rm.RM_GetSelectedOutputOn();
% int units_exchange = phreeqc_rm.RM_GetUnitsExchange();
% int units_gas_phase = phreeqc_rm.RM_GetUnitsGasPhase();
% int units_kinetics = phreeqc_rm.RM_GetUnitsKinetics();
% int units_pp_assemblage = phreeqc_rm.RM_GetUnitsPPassemblage();
% int units_solution = phreeqc_rm.RM_GetUnitsSolution();
% int units_ss_exchange = phreeqc_rm.RM_GetUnitsSSassemblage();
% int units_surface = phreeqc_rm.RM_GetUnitsSurface();
% Demonstation of mapping, two equivalent rows by symmetry
grid2chem = -1*ones(nxyz, 1);
grid2chem(1:nxyz/2) = (1:nxyz/2)-1; % 0 indexing for C
grid2chem(nxyz/2+1:end) = (1:nxyz/2)-1;
status = phreeqc_rm.RM_CreateMapping(grid2chem);
if (status < 0)
    phreeqc_rm.RM_DecodeError(status);
end
nchem = phreeqc_rm.RM_GetChemistryCellCount();

% --------------------------------------------------------------------------
% Set initial conditions
% --------------------------------------------------------------------------

% Set printing of chemistry file
status = phreeqc_rm.RM_SetPrintChemistryOn(false, true, false); % workers, initial_phreeqc, utility
% Load database
status = phreeqc_rm.RM_LoadDatabase('../../database/phreeqc.dat');

% I do not know this one:
% Demonstrate add to Basic: Set a function for Basic CALLBACK after LoadDatabase
% register_basic_callback(&some_data);

% Demonstration of error handling if ErrorHandlerMode is 0
if (status ~= 0)
    err_str ='                                                '; 
    [status, err_str] = phreeqc_rm.RM_GetErrorString(err_str, length(err_str));
    error(err_str); % retrieve error messages if needed
end
% Run file to define solutions and reactants for initial conditions, selected output
workers = true;             % Worker instances do the reaction calculations for transport
initial_phreeqc = true;     % InitialPhreeqc instance accumulates initial and boundary conditions
utility = true;             % Utility instance is available for processing
status = phreeqc_rm.RM_RunFile(workers, initial_phreeqc, utility, 'advect.pqi');
% Clear contents of workers and utility
initial_phreeqc = false;
string_input = 'DELETE; -all';
status = phreeqc_rm.RM_RunString(workers, initial_phreeqc, utility, string_input);
% Determine number of components to transport
ncomps = phreeqc_rm.RM_FindComponents();
% Print some of the reaction module information

% fprintf('Database:                                         %d \n', phreeqc_rm.RM_GetDatabaseFileName());
fprintf('Number of threads:                                %d \n', phreeqc_rm.RM_GetThreadCount());
% fprintf('Number of MPI processes:                          %d \n', phreeqc_rm.RM_GetMpiTasks());
% fprintf('MPI task number:                                  %d \n', phreeqc_rm.RM_GetMpiMyself());
% fprintf('File prefix:                                      %d \n', phreeqc_rm.RM_GetFilePrefix());
fprintf('Number of grid cells in the user''s model:        %d \n', phreeqc_rm.RM_GetGridCellCount());
fprintf('Number of chemistry cells in the reaction module: %d \n', phreeqc_rm.RM_GetChemistryCellCount());
fprintf('Number of components for transport:               %d \n', phreeqc_rm.RM_GetComponentCount());
% fprintf('Partioning of UZ solids:                          %d \n', phreeqc_rm.RM_GetPartitionUZSolids());
% fprintf('Error handler mode:                               %d \n', phreeqc_rm.RM_GetErrorHandlerMode());
phreeqc_rm.RM_OutputMessage('The message is written');


% const std::vector<int> &f_map = phreeqc_rm.RM_GetForwardMapping(); does not
% exist in the c interface
% Get component information
% const std::vector<std::string> &components = phreeqc_rm.RM_GetComponents();
gfw = zeros(ncomps, 1);
[status, gfw] = phreeqc_rm.RM_GetGfw(gfw);

components = cell(ncomps, 1);
s_name = '000000000000000000000000000';

for i=1:ncomps
    [status, components{i}] = phreeqc_rm.RM_GetComponent(i-1, s_name, length(s_name));
    
end

for i=1:ncomps
    fprintf([components{i} '    ' num2str(gfw(i)) '\n']);
%     phreeqc_rm.RM_OutputMessage(strm.str());
end

% status = phreeqc_rm.RM_CloseFiles();
% phreeqc_rm.RM_Destroy();

% phreeqc_rm.RM_OutputMessage('\n');
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
status = phreeqc_rm.RM_InitialPhreeqc2Module(ic1, ic2, f1);

% ==== I'm not sure how to convert this part or whether it's necessary
% No mixing is defined, so the following is equivalent
% status = phreeqc_rm.RM_InitialPhreeqc2Module(ic1.data());
% 
% % alternative for setting initial conditions
% % cell number in first argument (-1 indicates last solution, 40 in this case)
% % in advect.pqi and any reactants with the same number--
% % Equilibrium phases, exchange, surface, gas phase, solid solution, and (or) kinetics--
% % will be written to cells 18 and 19 (0 based)
% std::vector<int> module_cells;
% module_cells.push_back(18);
% module_cells.push_back(19);
% status = phreeqc_rm.RM_InitialPhreeqcCell2Module(-1, module_cells);


% Get temperatures
tempc = zeros(nxyz, 1);
% [status, tempc] = phreeqc_rm.RM_GetTemperature(tempc); not available in C
% interface
% get current saturation
current_sat = zeros(nxyz, 1);
[status, current_sat] = phreeqc_rm.RM_GetSaturation(current_sat);
% Initial equilibration of cells
t = 0.0;
time_step = 0.0;
c = zeros(nxyz * length(components), 1);
status = phreeqc_rm.RM_SetTime(t);
status = phreeqc_rm.RM_SetTimeStep(time_step);
status = phreeqc_rm.RM_RunCells();
[status, c] = phreeqc_rm.RM_GetConcentrations(c);

c_out2 = phreeqc_rm.GetConcentrations();



% % --------------------------------------------------------------------------
% % Set boundary condition
% % --------------------------------------------------------------------------
% 
% std::vector<double> bc_conc, bc_f1;
% std::vector<int> bc1, bc2;
nbound = 1;
bc1 = zeros(nbound, 1);                      % solution 0 from Initial IPhreeqc instance
bc2 = -1*ones(nbound, 1);                     % no bc2 solution for mixing
bc_f1 = ones(nbound, 1);                  % mixing fraction for bc1 = 1
bc_conc = zeros(ncomps*nbound, 1); 
[status, bc_conc] = phreeqc_rm.RM_InitialPhreeqc2Concentrations(bc_conc, nbound, bc1, bc2, bc_f1);
% 
% % --------------------------------------------------------------------------
% % Transient loop
% % --------------------------------------------------------------------------
% 
nsteps = 10;
% std::vector<double> initial_density, temperature, pressure;
initial_density = ones(nxyz, 1);
temperature = 20.0*ones(nxyz, 1);
pressure = 2.0*ones(nxyz, 1);
phreeqc_rm.RM_SetDensity(initial_density);
phreeqc_rm.RM_SetTemperature(temperature);
phreeqc_rm.RM_SetPressure(pressure);
time_step = 86400.0;
status = phreeqc_rm.RM_SetTimeStep(time_step);
for steps = 1:nsteps
    % Transport calculation here
    
    strm =['Beginning transport calculation             ' num2str(phreeqc_rm.RM_GetTime()*phreeqc_rm.RM_GetTimeConversion()) ' days \n'];
    strm =[strm '          Time step                         ' num2str(phreeqc_rm.RM_GetTimeStep() * phreeqc_rm.RM_GetTimeConversion()) ' days \n'];
    phreeqc_rm.RM_LogMessage(strm);
    phreeqc_rm.RM_SetScreenOn(true);
    phreeqc_rm.RM_ScreenMessage(strm);
    
    c = simple_advect(c, bc_conc, ncomps, nxyz); % boundary only at the injection side
    % Transfer data to PhreeqcRM for reactions
    if steps == nsteps   
        print_selected_output_on = true;
        print_chemistry_on = true;
    else
        print_selected_output_on = false;
        print_chemistry_on = false;
    end
    
    status = phreeqc_rm.RM_SetSelectedOutputOn(print_selected_output_on);
    status = phreeqc_rm.RM_SetPrintChemistryOn(print_chemistry_on, false, false); % workers, initial_phreeqc, utility
    status = phreeqc_rm.RM_SetPorosity(por);             % If pororosity changes due to compressibility
    status = phreeqc_rm.RM_SetSaturation(sat);           % If saturation changes
    status = phreeqc_rm.RM_SetTemperature(temperature);  % If temperature changes
    status = phreeqc_rm.RM_SetPressure(pressure);        % If pressure changes
    status = phreeqc_rm.RM_SetConcentrations(c);         % Transported concentrations
    status = phreeqc_rm.RM_SetTimeStep(time_step);		  % Time step for kinetic reactions
    t = t + time_step;
    status = phreeqc_rm.RM_SetTime(t);
    % Run cells with transported conditions

    strm = ['Beginning reaction calculation              ' num2str(t * phreeqc_rm.RM_GetTimeConversion()) ' days\n'];
    phreeqc_rm.RM_LogMessage(strm);
    phreeqc_rm.RM_ScreenMessage(strm);

    status = phreeqc_rm.RM_RunCells();
    % Transfer data from PhreeqcRM for transport
    [status, c] = phreeqc_rm.RM_GetConcentrations(c);
    density = zeros(nxyz, 1);
    [status, density] = phreeqc_rm.RM_GetDensity(density);
    volume = zeros(nxyz, 1);
    [status, volume] = phreeqc_rm.RM_GetSolutionVolume(volume);
    % Print results at last time step
    c = reshape(c, nxyz, ncomps);
    if (print_chemistry_on ~= 0)
        
        for isel = 0:phreeqc_rm.RM_GetSelectedOutputCount()-1
            % Loop through possible multiple selected output definitions
            n_user = phreeqc_rm.RM_GetNthSelectedOutputUserNumber(isel);
            status = phreeqc_rm.RM_SetCurrentSelectedOutputUserNumber(n_user);
            fprintf(['Selected output sequence number: ' num2str(isel) '\n']);
            fprintf(['Selected output user number:     ' num2str(n_user) '\n']);
            % Get double array of selected output values
            
            col = phreeqc_rm.RM_GetSelectedOutputColumnCount();
            so = zeros(col*nxyz, 1);
            so = reshape(so, nxyz, col);
            [status, so] = phreeqc_rm.RM_GetSelectedOutput(so);
            % Print results
            for i = 1:phreeqc_rm.RM_GetSelectedOutputRowCount()/2
                disp(['Cell number ' num2str(i)]);
                disp(['     Density: ' num2str(density(i+1))]);
                disp(['     Volume:  ' num2str(volume(i+1))]);
                disp('     Components: ');
                for j = 1:ncomps
                    disp(['          ' num2str(j) ' ' components{j} ': ' c(i, j)]);
                end
                headings = cell(col, 1);
                
                disp('     Selected output: ');
                for j = 1:col
                    headings{j} = '000000000000000';
                    [status, headings{j}] = phreeqc_rm.RM_GetSelectedOutputHeading(j-1, headings{j}, length(headings{j}));
                    disp(['          ' num2str(j) ' ' headings{j} ': ' num2str(so(i,j))]);
                end
            end
        end
    end
end

c = c(:);

status = phreeqc_rm.RM_CloseFiles();
status = phreeqc_rm.RM_Destroy();


% ============= The rest will not work until I wrap IPhreeqc library =====
% --------------------------------------------------------------------------
% Additional features and finalize
% --------------------------------------------------------------------------

% Use utility instance of PhreeqcRM to calculate pH of a mixture

% c_well = zeros(ncomps, 1);
% for i = 1:ncomps
%     c_well(i) = 0.5 * c(1 + nxyz*i) + 0.5 * c(10 + nxyz*i);
% end
% % std::vector<double> tc, p_atm;
% tc = 15.0*ones(1,1);
% p_atm = 3.0*ones(1,1);
% iphreeqc_id = phreeqc_rm.RM_Concentrations2Utility(c_well, tc, p_atm);
% input_str = 'SELECTED_OUTPUT 5; -pH;RUN_CELLS; -cells 1';
% int iphreeqc_result;
% util_ptr->SetOutputFileName('utility_cpp.txt');
% util_ptr->SetOutputFileOn(true);
% iphreeqc_result = util_ptr->RunString(input.c_str());
% % Alternatively, utility pointer is worker nthreads + 1
% IPhreeqc * util_ptr1 = phreeqc_rm.RM_GetIPhreeqcPointer(phreeqc_rm.RM_GetThreadCount() + 1);
% if (iphreeqc_result != 0)
% {
%     phreeqc_rm.RM_ErrorHandler(IRM_FAIL, 'IPhreeqc RunString failed');
% }
% int vtype;
% double pH;
% char svalue[100];
% util_ptr->SetCurrentSelectedOutputUserNumber(5);
% iphreeqc_result = util_ptr->GetSelectedOutputValue2(1, 0, &vtype, &pH, svalue, 100);
% % Dump results
% bool dump_on = true;
% bool append = false;
% status = phreeqc_rm.RM_SetDumpFileName('advection_cpp.dmp');
% status = phreeqc_rm.RM_DumpModule(dump_on, append);    % gz disabled unless compiled with #define USE_GZ
% % Get pointer to worker
% const std::vector<IPhreeqcPhast *> w = phreeqc_rm.RM_GetWorkers();
% w[0]->AccumulateLine('Delete; -all');
% iphreeqc_result = w[0]->RunAccumulated();
% % Clean up
% status = phreeqc_rm.RM_CloseFiles();
% status = phreeqc_rm.RM_MpiWorkerBreak();
