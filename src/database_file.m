function db_file_path = database_file(data_file_name)
%DATABASE_FILE returns the full path to the database file name specified by
%data_file_name
%Example:
%   phreeqc_rm = PhreeqcRM(1, 1); % one cell, one thread
%   phreeqc_rm = phreeqc_rm.RM_Create();
%   phreeqc_rm.RM_UseSolutionDensityVolume(true);
%   status = phreeqc_rm.RM_LoadDatabase(database_file('phreeqc.dat'));
%   SEE ALSo DATABASE_PATH
db_file_path = fullfile(DATABASE_PATH, data_file_name);
end

