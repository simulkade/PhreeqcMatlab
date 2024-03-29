function phreeqc_rm = PhreeqcTransport1D(input_file, data_base)
%PHREEQCTRANSPORT Reads a phreeqc input file (with the transport key) and
%creates a reactive transport simulation in FVTool and PhreeqcMatlab. This
%function works only on 1D domains. For the 2D and 3D domains, see the
%example folder.
%TODO: simple 2D cases based on modified phreeqc input files.
%   

% Read the input file
C = ReadPhreeqcFile(input_file); % read and clean the input file

% Find the transport or advection keys and create the tranport model
if any(contains(C, 'ADVECTION'))
    ind_cells = contains(C, '-cells');
    nxyz = sscanf(C{ind_cells}, '-cells %f');
elseif any(contains(C, 'TRANSPORT'))
    ind_cells = contains(C, 'cells');
    nxyz = sscanf(K, 'cells %f');
end


% status = phreeqc_rm.RM_LoadDatabase(database_file(data_base)); % load the database
% status = phreeqc_rm.RM_RunFile(true, true, true, input_file); % run the input file
end

