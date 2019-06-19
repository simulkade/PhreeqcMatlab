function [phreeqc_rm, c_x_t] = PhreeqcAdvection(phreeqc_input_file, advection_input_file)
%PHREEQCTRANSPORT Reads a phreeqc input file (with the transport key) and
%creates a reactive transport simulation in FVTool and PhreeqcMatlab. This
%function works only on 1D domains. For the 2D and 3D domains, see the
%example folder.
% c_x_t: concentration history and profile
%TODO: simple 2D cases based on modified phreeqc input files.
%   

% Create the phreeqc instance based on the advection file, and get the
% shifts and time steps
[phreeqc_rm, shifts, dt] = ReadAdvectionFile(advection_input_file);
[phreeqc_rm, bc_conc, c_init] = InitializePhreeqcAdvection(phreeqc_rm, phreeqc_input_file);

[m,n] = size(c_init);
c_x_t = zeros(m, n, shifts+1);
c_x_t(:,:,1) = c_init;
for i = 1:shifts
    c_trans = SimpleAdvection1D(c_init, bc_conc);
    status = phreeqc_rm.RM_SetTimeStep(dt);		  % Time step for kinetic reactions
    t = shifts*dt; % time
    status = phreeqc_rm.RM_SetTime(t);
    status = phreeqc_rm.RM_SetConcentrations(c_trans);         % Transported concentrations
    status = phreeqc_rm.RM_RunCells();
    c_new = phreeqc_rm.GetConcentrations();
    c_x_t(:,:,i+1) = c_new;
    c_init = c_new; % got to the next time step
end
% status = phreeqc_rm.RM_LoadDatabase(database_file(data_base)); % load the database
% status = phreeqc_rm.RM_RunFile(true, true, true, input_file); % run the input file
end

