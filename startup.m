% function startup()

%{
startup

Startup the phreeqc 
%}
% global DATABASE_PATH
try
	p = mfilename('fullpath');
	file_name = mfilename;
	current_path = p(1:end-1-length(file_name));
	addpath([current_path '/libs']);
	addpath([current_path '/src']);
    addpath([current_path '/database']);
%     DATABASE_PATH = [current_path '/database'];
catch 
    error("Something went wrong with the PhreeqcMatlab start up."); 
end

% try to download the libraries and header files
time_out = 1000; % [s] time for downloading the libraries
if ispc
    % PhreeqcRM lib file download
    if ~isfile([current_path '/libs/libphreeqcrm.dll']) % lib files do not exist
        options = weboptions('Timeout', time_out);
        url = 'https://github.com/simulkade/PhreeqcRM/raw/master/lib/PhreeqcRMd.dll';
        lib_name = 'libs/libphreeqcrm.dll';
        disp('Downloading libphreeqcrm.dll from https://github.com/simulkade/PhreeqcRM. Please wait...');
        websave(lib_name, url, options);
        disp('libphreeqcrm.dll is successfully downloaded.');
    end
    % IPhreeqc lib file download
    if ~isfile([current_path '/libs/libiphreeqc.dll']) % lib files do not exist
        options = weboptions('Timeout', time_out);
        url = 'https://github.com/simulkade/PhreeqcRM/raw/master/IPhreeqc_lib/IPhreeqc.dll';
        lib_name = 'libs/libiphreeqc.dll';
        disp('Downloading libiphreeqc.dll from https://github.com/simulkade/PhreeqcRM. Please wait...');
        websave(lib_name, url, options);
        disp('libiphreeqc.dll is successfully downloaded.');
    end
end
    

if isunix
    % PhreeqcRM lib file download
    if ~isfile([current_path '/libs/libphreeqcrm.so']) % lib files do not exist
        options = weboptions('Timeout', time_out);
        url = 'https://github.com/simulkade/PhreeqcRM/raw/master/linux_lib/libphreeqcrm-3.5.0.so';
        lib_name = 'libs/libphreeqcrm.so';
        disp('Downloading libphreeqcrm.so from https://github.com/simulkade/PhreeqcRM. Please wait...');
        websave(lib_name, url, options);
        disp('libphreeqcrm.so is successfully downloaded.');
    end
    
    % IPhreeqc lib file download
    if ~isfile([current_path '/libs/libiphreeqc.so']) % lib files do not exist
        options = weboptions('Timeout', time_out);
        url = 'https://github.com/simulkade/PhreeqcRM/raw/master/IPhreeqc_lib/libiphreeqc-3.5.0.so';
        lib_name = 'libs/libiphreeqc.so';
        disp('Downloading libiphreeqc.so from https://github.com/simulkade/PhreeqcRM. Please wait...');
        websave(lib_name, url, options);
        disp('libiphreeqc.so is successfully downloaded.');
    end
end

