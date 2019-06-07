function [phreeqc_rm, shifts, dt] = ReadAdvectionFile(advection_input_file)
%READADVECTIONFILE Reads a PhreeqcMatlab advection input file (with the
%special PhreeqcMatlab keywords and creates and initializes a PhreeqcRM
%instance. See the documents and examples for the PhreeqcMatlab keywords.

% reads the input file and gets rid of the comments
C = ReadPhreeqcFile(advection_input_file);

% go through the input file and extract the relevant data for each keyword
nxyz = sscanf(C{contains(C, 'cells')}, 'cells %d');
nthreads = sscanf(C{contains(C, 'threads')}, 'threads %d');

% Create the phreeqcrm object
phreeqc_rm = PhreeqcRM(nxyz, nthreads);
phreeqc_rm = phreeqc_rm.RM_Create();

% read the parameters from the input file and set the default values
error_handler_mode = sscanf(C{contains(C, 'error_handler_mode')}, 'error_handler_mode %d');
if isempty(error_handler_mode)
    error_handler_mode = 1;
end
component_water = sscanf(C{contains(C, 'component_water')}, 'component_water %d');
if isempty(component_water)
    component_water = 0;
end
partition_uz_solids = sscanf(C{contains(C, 'partition_uz_solids')}, 'partition_uz_solids %d');
if isempty(partition_uz_solids)
    partition_uz_solids = 0;
end
rebalance_fraction = sscanf(C{contains(C, 'rebalance_fraction')}, 'rebalance_fraction %f');
if isempty(rebalance_fraction)
    rebalance_fraction = 0.5;
end
rebalance_by_cell = sscanf(C{contains(C, 'rebalance_by_cell')}, 'rebalance_by_cell %d');
if isempty(rebalance_by_cell)
    rebalance_by_cell = 1;
end
use_solution_density_volume = sscanf(C{contains(C, 'use_solution_density_volume')}, 'use_solution_density_volume %d');
if isempty(use_solution_density_volume)
    use_solution_density_volume = 0;
end
units_solution = sscanf(C{contains(C, 'units_solution')}, 'units_solution %d');
if isempty(units_solution)
    units_solution = 2;
end
units_pp_assemblage = sscanf(C{contains(C, 'units_pp_assemblage')}, 'units_pp_assemblage %d');
if isempty(units_pp_assemblage)
    units_pp_assemblage = 1;
end
units_exchange = sscanf(C{contains(C, 'units_exchange')}, 'units_exchange %d');
if isempty(units_exchange)
    units_exchange = 1;
end
units_surface = sscanf(C{contains(C, 'units_surface')}, 'units_surface %d');
if isempty(units_surface)
    units_surface = 1;
end
units_gas_phase = sscanf(C{contains(C, 'units_gas_phase')}, 'units_gas_phase %d');
if isempty(units_gas_phase)
    units_gas_phase = 1;
end
units_ss_assemblage = sscanf(C{contains(C, 'units_ss_assemblage')}, 'units_ss_assemblage %d');
if isempty(units_ss_assemblage)
    units_ss_assemblage = 1;
end
units_kinetics = sscanf(C{contains(C, 'units_kinetics')}, 'units_kinetics %d');
if isempty(units_kinetics)
    units_kinetics = 1;
end
time_conversion = sscanf(C{contains(C, 'time_conversion')}, 'time_conversion %f');
if isempty(time_conversion)
    time_conversion = 1.0;
end

status = phreeqc_rm.RM_SetErrorHandlerMode(error_handler_mode);
status = phreeqc_rm.RM_SetComponentH2O(component_water);
status = phreeqc_rm.RM_SetRebalanceFraction(rebalance_fraction);
status = phreeqc_rm.RM_SetRebalanceByCell(rebalance_by_cell);
phreeqc_rm.RM_UseSolutionDensityVolume(use_solution_density_volume);
phreeqc_rm.RM_SetPartitionUZSolids(partition_uz_solids);
% status = phreeqc_rm.RM_SetFilePrefix('Advect');
% phreeqc_rm.RM_OpenFiles();

status = phreeqc_rm.RM_SetUnitsSolution(units_solution);           % 1, mg/L; 2, mol/L; 3, kg/kgs
status = phreeqc_rm.RM_SetUnitsPPassemblage(units_pp_assemblage);       % 0, mol/L cell; 1, mol/L water; 2 mol/L rock
status = phreeqc_rm.RM_SetUnitsExchange(units_exchange);           % 0, mol/L cell; 1, mol/L water; 2 mol/L rock
status = phreeqc_rm.RM_SetUnitsSurface(units_surface);            % 0, mol/L cell; 1, mol/L water; 2 mol/L rock
status = phreeqc_rm.RM_SetUnitsGasPhase(units_gas_phase);           % 0, mol/L cell; 1, mol/L water; 2 mol/L rock
status = phreeqc_rm.RM_SetUnitsSSassemblage(units_ss_assemblage);       % 0, mol/L cell; 1, mol/L water; 2 mol/L rock
status = phreeqc_rm.RM_SetUnitsKinetics(units_kinetics);           % 0, mol/L cell; 1, mol/L water; 2 mol/L rock
status = phreeqc_rm.RM_SetTimeConversion(time_conversion);


initial_saturation = sscanf(C{contains(C, 'initial_saturation')}, 'initial_saturation %f');
initial_porosity = sscanf(C{contains(C, 'initial_porosity')}, 'initial_porosity %f');
representative_volume = sscanf(C{contains(C, 'representative_volume')}, 'representative_volume %f');

% Set representative volume
rv = representative_volume*ones(nxyz, 1);
status = phreeqc_rm.RM_SetRepresentativeVolume(rv);
% Set initial porosity
por = initial_porosity*ones(nxyz, 1);
status = phreeqc_rm.RM_SetPorosity(por);
% Set initial saturation
sat = initial_saturation*ones(nxyz, 1);
status = phreeqc_rm.RM_SetSaturation(sat);


dt = sscanf(C{contains(C, 'time_step')}, 'time_step %f');
shifts = sscanf(C{contains(C, 'shifts')}, 'shifts %f');
end

