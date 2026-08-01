function [phreeqc_rm, shifts, dt] = ReadAdvectionFile(advection_input_file)
%READADVECTIONFILE create and configure a PhreeqcRM instance from a 1D
%PhreeqcMatlab advection control file (.pqm).
%
% The file is parsed with ParsePqmConfig and its PhreeqcRM settings applied
% with ApplyRmSettings; this function then returns the number of transport
% shifts and the time step for the 1D advection loop (see PhreeqcAdvection).

cfg = ParsePqmConfig(advection_input_file);

if isempty(cfg.transport.cells)
    error('PhreeqcMatlab:missingCells', ...
        'A 1D advection .pqm file must define "cells".');
end

% Create the PhreeqcRM object (the constructor already calls RM_Create).
phreeqc_rm = PhreeqcRM(cfg.transport.cells, cfg.rm.threads);

% Apply units / rebalance / porosity / saturation / database settings.
phreeqc_rm = ApplyRmSettings(phreeqc_rm, cfg);

dt = cfg.transport.time_step;
shifts = cfg.transport.shifts;
end
