%% 2D reactive transport (cation exchange) — PhreeqcMatlab + FVTool
%
% A 2D extension of PHREEQC example 11: CaCl2 solution flushes a column
% initially in Na/K exchange equilibrium. FVTool advects the components across
% a 5 x 4 grid while PhreeqcRM re-equilibrates the exchanger each step.
%
% This example uses the external FVTool package. startup.m provisions it
% automatically into external/FVTool (cloning it from GitHub on first run) when
% git and network are available; if not, clone it yourself from
%     https://github.com/FiniteVolumeTransportPhenomena/FVTool
% and run FVToolStartUp before this example.
%
% Run after startup:  run('examples/transport/reactive_transport_2d.m')

startup;

if ~fvtool_available()
    fprintf(['\nFVTool is not on the MATLAB path (auto-provisioning may have ' ...
        'failed).\nClone https://github.com/FiniteVolumeTransportPhenomena/FVTool\n' ...
        'into external/FVTool (or anywhere on the path) and re-run.\n\n']);
    return;
end

here = fileparts(mfilename('fullpath'));
pqc = fullfile(here, 'reactive_transport_2d_input.pqc');
pqm = fullfile(here, 'reactive_transport_2d.pqm');

[phreeqc_rm, c_hist, m] = PhreeqcFVToolTransport(pqc, pqm); %#ok<ASGLU>

comps = string(phreeqc_rm.GetComponents());
fprintf('Transported components: %s\n', strjoin(comps, ', '));

% Plot the final Na field on the grid.
na = find(comps == "Na", 1);
if ~isempty(na)
    cfg = ParsePqmConfig(pqm);
    final_na = reshape(c_hist(:, na, end), cfg.transport.nx, cfg.transport.ny);
    figure('Name', '2D reactive transport: final Na (mol/L)');
    imagesc(final_na.');
    axis image; colorbar;
    xlabel('x cell'); ylabel('y cell');
    title('Na concentration after flushing (mol/L)');
end

phreeqc_rm.RM_Destroy();
