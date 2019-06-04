function phreeqc_rm = PhreeqcTransport(input_file, data_base)
%PHREEQCTRANSPORT Reads a phreeqc input file (with the transport key) and
%creates a reactive transport simulation in FVTool and PhreeqcMatlab. This
%function works only on 1D domains. For the 2D and 3D domains, see the
%example folder.
%TODO: simple 2D cases based on modified phreeqc input files.
%   

% Read the input file
C = ReadPhreeqcFile(input_file); % read and clean the input file

% Find the transport keys and create the tranport model

% contains(C, 'Transport')

status = phreeqc_rm.RM_LoadDatabase(database_file(data_base)); % load the database
status = phreeqc_rm.RM_RunFile(true, true, true, input_file); % run the input file
end

