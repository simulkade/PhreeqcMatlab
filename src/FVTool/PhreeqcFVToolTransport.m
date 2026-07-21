function [phreeqc_rm, c_hist, m] = PhreeqcFVToolTransport(phreeqc_input_file, pqm_file, varargin)
%PHREEQCFVTOOLTRANSPORT multi-dimensional reactive transport by coupling the
%external FVTool finite-volume package to PhreeqcRM (operator splitting).
%
%   [rm, c_hist, m] = PhreeqcFVToolTransport(phreeqc_input_file, pqm_file, ...)
%
% Each time step: FVTool advects+diffuses every transported component on the
% grid, the transported concentrations are pushed into PhreeqcRM, the cells
% react (RM_RunCells), and the reacted concentrations are read back for the
% next step.
%
% Name-value options:
%   'n_steps'  number of transport steps (default: `shifts` from the .pqm)
%   'velocity' [ux uy] Darcy velocity (default: one cell per step in +x, i.e.
%              Courant number 1, mirroring the 1D advection shift)
%   'D'        diffusion coefficient (default 0 — pure advection)
%
% Grid, time step and PhreeqcRM settings come from the .pqm file (see
% ParsePqmConfig). Boundary condition: the inflow (SOLUTION 0) concentration is
% imposed as a Dirichlet condition on the x = 0 face; other faces are no-flux.
%
% Requires FVTool (https://github.com/simulkade/FVTool) on the path. This is an
% optional dependency and is NOT bundled with PhreeqcMatlab.
%
% See also InitializePhreeqcFVTool, ParsePqmConfig, PhreeqcAdvection.

if ~fvtool_available()
    error('PhreeqcMatlab:fvtoolMissing', ...
        ['FVTool is required for multi-dimensional transport but was not ' ...
         'found on the path. Install it from ' ...
         'https://github.com/simulkade/FVTool and add it with addpath.']);
end

p = inputParser;
addParameter(p, 'n_steps', []);
addParameter(p, 'velocity', []);
addParameter(p, 'D', 0.0);
parse(p, varargin{:});

cfg = ParsePqmConfig(pqm_file);
t = cfg.transport;
if isempty(t.nx) || isempty(t.ny)
    error('PhreeqcMatlab:not2D', ...
        'PhreeqcFVToolTransport needs Nx and Ny in the .pqm ADVECTION block.');
end
nxyz = t.nx * t.ny;

n_steps = p.Results.n_steps;
if isempty(n_steps); n_steps = t.shifts; end
if isempty(n_steps)
    error('PhreeqcMatlab:missingSteps', ...
        'Specify the number of steps via ''n_steps'' or `shifts` in the .pqm.');
end

% ---- PhreeqcRM instance + initial/boundary conditions -------------------
phreeqc_rm = PhreeqcRM(nxyz, cfg.rm.threads);
phreeqc_rm = ApplyRmSettings(phreeqc_rm, cfg);
[phreeqc_rm, bc_conc, c_init] = InitializePhreeqcFVTool(phreeqc_rm, phreeqc_input_file);
ncomps = size(c_init, 2);

% ---- FVTool mesh, velocity, diffusion -----------------------------------
m = createMesh2D(t.nx, t.ny, t.lx, t.ly);
dx = t.lx / t.nx;
vel = p.Results.velocity;
if isempty(vel); vel = [dx / t.time_step, 0.0]; end   % Courant 1 in +x
u = createFaceVariable(m, vel);
D = createFaceVariable(m, p.Results.D);
Mconv = convectionUpwindTerm(u);
Mdiff = diffusionTerm(D);

% ---- history buffer -----------------------------------------------------
c_hist = zeros(nxyz, ncomps, n_steps + 1);
c_hist(:, :, 1) = c_init;
c = c_init;

for step = 1:n_steps
    % Transport each component independently on the grid.
    for j = 1:ncomps
        BC = createBC(m);                 % default: no-flux on all faces
        BC.left.a(:) = 0; BC.left.b(:) = 1; BC.left.c(:) = bc_conc(j);  % Dirichlet inflow
        phi_old = createCellVariable(m, reshape(c(:, j), t.nx, t.ny), BC);
        Mt = transientTerm(phi_old, t.time_step, 1);
        [Mbc, RHSbc] = boundaryCondition(BC);
        [~, RHSt] = transientTerm(phi_old, t.time_step, 1);
        phi = solvePDE(m, Mt + Mconv - Mdiff + Mbc, RHSt + RHSbc);
        internal = phi.value(2:end-1, 2:end-1);
        c(:, j) = internal(:);
    end

    % React the transported concentrations.
    phreeqc_rm.RM_SetTime(step * t.time_step);
    phreeqc_rm.RM_SetTimeStep(t.time_step);
    phreeqc_rm.RM_SetConcentrations(c);
    phreeqc_rm.RM_RunCells();
    c = phreeqc_rm.GetConcentrations();
    c_hist(:, :, step + 1) = c;
end
end
