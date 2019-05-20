function startup()

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
if ispc
    if ~isfile([current_path '/libs/libphreeqcrm.dll']) % lib files do not exist
        options = weboptions('Timeout',120);
        url = 'https://github.com/simulkade/PhreeqcRM/raw/master/lib/PhreeqcRMd.dll';
        lib_name = 'libs/libphreeqcrm.dll';
        websave(lib_name, url, options);
    end
end
    

if isunix
    if ~isfile([current_path '/libs/libphreeqcrm.so']) % lib files do not exist
        options = weboptions('Timeout',120);
        url = 'https://github.com/simulkade/PhreeqcRM/raw/master/linux_lib/libphreeqcrm-3.5.0.so';
        lib_name = 'libs/libphreeqcrm.so';
        websave(lib_name, url, options);
    end
end

