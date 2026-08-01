function phreeqc_rm = ApplyRmSettings(phreeqc_rm, cfg)
%APPLYRMSETTINGS push a parsed .pqm configuration onto a PhreeqcRM instance.
%   phreeqc_rm : an existing PhreeqcRM object (already RM_Create-d)
%   cfg        : struct from ParsePqmConfig (uses cfg.rm and cfg.transport)
%
% Applies the error-handler/units/rebalance/database settings from cfg.rm and
% the per-cell porosity/saturation/representative-volume from cfg.transport,
% then loads the database. Centralizes the RM_Set* block that ReadAdvectionFile
% and InitializePhreeqcFVTool would otherwise duplicate.
%
% See also ParsePqmConfig, ReadAdvectionFile, InitializePhreeqcFVTool.

r = cfg.rm;
phreeqc_rm.RM_SetErrorHandlerMode(r.error_handler_mode);
phreeqc_rm.RM_SetComponentH2O(r.component_water);
phreeqc_rm.RM_SetRebalanceFraction(r.rebalance_fraction);
phreeqc_rm.RM_SetRebalanceByCell(r.rebalance_by_cell);
phreeqc_rm.RM_UseSolutionDensityVolume(r.use_solution_density_volume);
phreeqc_rm.RM_SetPartitionUZSolids(r.partition_uz_solids);
phreeqc_rm.RM_SetScreenOn(r.screen_messages);

phreeqc_rm.RM_SetUnitsSolution(r.units_solution);        % 1 mg/L; 2 mol/L; 3 kg/kgs
phreeqc_rm.RM_SetUnitsPPassemblage(r.units_pp_assemblage);
phreeqc_rm.RM_SetUnitsExchange(r.units_exchange);
phreeqc_rm.RM_SetUnitsSurface(r.units_surface);
phreeqc_rm.RM_SetUnitsGasPhase(r.units_gas_phase);
phreeqc_rm.RM_SetUnitsSSassemblage(r.units_ss_assemblage);
phreeqc_rm.RM_SetUnitsKinetics(r.units_kinetics);
phreeqc_rm.RM_SetTimeConversion(r.time_conversion);

nxyz = phreeqc_rm.ncells;
phreeqc_rm.RM_SetRepresentativeVolume(cfg.transport.representative_volume * ones(nxyz, 1));
phreeqc_rm.RM_SetPorosity(cfg.transport.initial_porosity * ones(nxyz, 1));
phreeqc_rm.RM_SetSaturation(cfg.transport.initial_saturation * ones(nxyz, 1));

phreeqc_rm.RM_LoadDatabase(database_file(r.data_base));
end
