function cfg = ParsePqmConfig(pqm_file)
%PARSEPQMCONFIG parse a PhreeqcMatlab (.pqm) control file into a struct.
%
% A .pqm file has two keyword sections, each terminated by END:
%   ADVECTION      transport grid + time-stepping parameters
%   PhreeqcMatlab  PhreeqcRM instance settings (threads, units, database, ...)
%
% Two transport geometries are supported:
%   * 1D column   — `cells` and `shifts` (see Advection1D),
%   * multi-D grid — `Coordinate`, `Dimension`, `Nx`/`Ny`/`Nz`, `Lx`/`Ly`/`Lz`
%                    (see FVTool).
%
% Returns a struct with two sub-structs:
%   cfg.transport : coordinate, dimension, nx/ny/nz, lx/ly/lz, cells, shifts,
%                   time_step, initial_saturation, initial_porosity,
%                   initial_permeability, representative_volume, ncells
%   cfg.rm        : threads, component_water, error_handler_mode,
%                   screen_messages, partition_uz_solids, rebalance_fraction,
%                   rebalance_by_cell, use_solution_density_volume, units_*,
%                   time_conversion, data_base
%
% Missing keys fall back to the same defaults the 1D driver used. Use
% ApplyRmSettings to push cfg.rm onto a PhreeqcRM instance.
%
% See also ApplyRmSettings, ReadAdvectionFile, InitializePhreeqcFVTool.

C = ReadPhreeqcFile(pqm_file);

% ---- transport / grid ---------------------------------------------------
t.coordinate           = pqm_str(C, 'Coordinate', 'Cartesian');
t.dimension            = pqm_num(C, 'Dimension', '%d', 1);
t.nx                   = pqm_num(C, 'Nx', '%d', []);
t.ny                   = pqm_num(C, 'Ny', '%d', []);
t.nz                   = pqm_num(C, 'Nz', '%d', []);
t.lx                   = pqm_num(C, 'Lx', '%f', []);
t.ly                   = pqm_num(C, 'Ly', '%f', []);
t.lz                   = pqm_num(C, 'Lz', '%f', []);
t.cells                = pqm_num(C, 'cells', '%d', []);
t.shifts               = pqm_num(C, 'shifts', '%f', []);
t.time_step            = pqm_num(C, 'time_step', '%f', 1.0);
t.initial_saturation   = pqm_num(C, 'initial_saturation', '%f', 1.0);
t.initial_porosity     = pqm_num(C, 'initial_porosity', '%f', 1.0);
t.initial_permeability = pqm_num(C, 'initial_permeability', '%f', []);
t.representative_volume = pqm_num(C, 'representative_volume', '%f', 1.0);

% Total number of reaction cells implied by the geometry: an explicit 1D
% `cells`, else the product of the grid dimensions that are present.
if ~isempty(t.cells)
    t.ncells = t.cells;
else
    dims = [t.nx t.ny t.nz];
    dims = dims(~cellfun(@isempty, {t.nx, t.ny, t.nz}));
    if isempty(dims)
        t.ncells = [];
    else
        t.ncells = prod(dims);
    end
end

% ---- PhreeqcRM settings -------------------------------------------------
r.threads                     = pqm_num(C, 'threads', '%d', 1);
r.component_water             = pqm_num(C, 'component_water', '%d', 0);
r.error_handler_mode          = pqm_num(C, 'error_handler_mode', '%d', 1);
r.screen_messages             = pqm_num(C, 'screen_messages', '%d', 1);
r.partition_uz_solids         = pqm_num(C, 'partition_uz_solids', '%d', 0);
r.rebalance_fraction          = pqm_num(C, 'rebalance_fraction', '%f', 0.5);
r.rebalance_by_cell           = pqm_num(C, 'rebalance_by_cell', '%d', 1);
r.use_solution_density_volume = pqm_num(C, 'use_solution_density_volume', '%d', 0);
r.units_solution              = pqm_num(C, 'units_solution', '%d', 2);
r.units_pp_assemblage         = pqm_num(C, 'units_pp_assemblage', '%d', 1);
r.units_exchange              = pqm_num(C, 'units_exchange', '%d', 1);
r.units_surface               = pqm_num(C, 'units_surface', '%d', 1);
r.units_gas_phase             = pqm_num(C, 'units_gas_phase', '%d', 1);
r.units_ss_assemblage         = pqm_num(C, 'units_ss_assemblage', '%d', 1);
r.units_kinetics              = pqm_num(C, 'units_kinetics', '%d', 1);
r.time_conversion             = pqm_num(C, 'time_conversion', '%f', 1.0);
r.data_base                   = pqm_str(C, 'data_base', 'phreeqc.dat');

cfg.transport = t;
cfg.rm = r;
end

% -------------------------------------------------------------------------
function v = pqm_num(C, key, fmt, default)
%PQM_NUM read a numeric value for `key` from cleaned lines C, or default.
% Matches the first line that begins with the key token (word-boundary), so
% e.g. 'Nx' does not accidentally match another key.
idx = find_key(C, key);
if isempty(idx)
    v = default;
    return;
end
v = sscanf(C{idx}, [key ' ' fmt]);
if isempty(v); v = default; end
end

% -------------------------------------------------------------------------
function s = pqm_str(C, key, default)
%PQM_STR read a string value for `key`, or default.
idx = find_key(C, key);
if isempty(idx)
    s = default;
    return;
end
s = strtrim(erase(C{idx}, key));
if isempty(s); s = default; end
end

% -------------------------------------------------------------------------
function idx = find_key(C, key)
%FIND_KEY index of the first cleaned line whose first token equals key.
idx = [];
for i = 1:numel(C)
    tok = strtok(C{i});
    if strcmp(tok, key)
        idx = i;
        return;
    end
end
end
