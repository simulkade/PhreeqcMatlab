function phreeqc_rm = PhreeqcAdvection(phreeqc_input_file, ...
                                advection_input_file, data_base)
%PHREEQCTRANSPORT Reads a phreeqc input file (with the transport key) and
%creates a reactive transport simulation in FVTool and PhreeqcMatlab. This
%function works only on 1D domains. For the 2D and 3D domains, see the
%example folder.
%TODO: simple 2D cases based on modified phreeqc input files.
%   

% Create the phreeqc instance based on the advection file
[phreeqc_rm, shifts, dt] = ReadAdvectionFile(advection_input_file);

% Read the input file
C = ReadPhreeqcFile(advection_input_file); % read and clean the input file

% Find the shifts and time steps values
n_shifts = sscanf(C{contains(C, '-shifts')}, '-shifts %f');
if any(contains(C, '-time_step'))
    dt = sscanf(C{contains(C, '-time_step')}, '-time_step %f');
else
    dt = 1.0; % if no time step specified, dt = 1.0 s
    warning('No -time_step specified. A default value of 1.0 s is assigned');
end



% status = phreeqc_rm.RM_LoadDatabase(database_file(data_base)); % load the database
% status = phreeqc_rm.RM_RunFile(true, true, true, input_file); % run the input file
end

