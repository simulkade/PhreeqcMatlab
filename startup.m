function startup()
%{
startup

Start up the PhreeqcMatlab package. If you have an internet connection, the
package automatically downloads the PhreeqcRM and IPhreeqc libraries for
your operating system (Mac is not supported yet).
%}
% global DATABASE_PATH
try
	p = mfilename('fullpath');
	file_name = mfilename;
	current_path = p(1:end-1-length(file_name));
	addpath([current_path '/libs']);
	addpath([current_path '/src']);
    addpath([current_path '/src/Advection1D']);
    addpath([current_path '/src/Transport1D']);
    addpath([current_path '/src/Bulk']);
    addpath([current_path '/src/Tools']);
    addpath([current_path '/database']);
    addpath([current_path '/src/FVTool']);
    disp('PhreeqcMatlab is starting. Checking for the PhreeqcRM library ...');
catch 
    error('Something went wrong with the PhreeqcMatlab start up. Please download the package again, extract it, and run the startup.m file.'); 
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
        try
            websave(lib_name, url, options);
            disp('libphreeqcrm.dll is successfully downloaded.');
        catch
            disp('Could not download the libphreeqcrm.dll file.')
            disp('Please download it from https://github.com/simulkade/PhreeqcRM/raw/master/lib/PhreeqcRMd.dll')
            disp('rename it to libphreeqcrm.dll, and copy it to the libs folder')
        end
    else
        disp('libphreeqcrm.dll library exists.');
        disp('PhreeqcMatlab started successfully');
    end
    % IPhreeqc lib file download
    if ~isfile([current_path '/libs/libiphreeqc.dll']) % lib files do not exist
        options = weboptions('Timeout', time_out);
        url = 'https://github.com/simulkade/PhreeqcRM/raw/master/IPhreeqc_lib/IPhreeqcd.dll';
        lib_name = 'libs/libiphreeqc.dll';
        disp('Downloading libiphreeqc.dll from https://github.com/simulkade/PhreeqcRM. Please wait...');
        try
            websave(lib_name, url, options);
            disp('libiphreeqc.dll is successfully downloaded.');
        catch
            disp('Could not download the libiphreeqc.dll file (OPTIONAL).')
            disp('Please download it from https://github.com/simulkade/PhreeqcRM/raw/master/IPhreeqc_lib/IPhreeqcd.dll')
            disp('rename it to libiphreeqc.dll, and copy it to the libs folder')
        end
    else
        disp('libiphreeqc.dll library exists.');
        disp('IPhreeqc functions are available');
    end
end
    

if isunix
    % PhreeqcRM lib file download
    if ~isfile([current_path '/libs/libphreeqcrm.so']) % lib files do not exist
        options = weboptions('Timeout', time_out);
        url = 'https://github.com/simulkade/PhreeqcRM/raw/master/linux_lib/libphreeqcrm-3.5.0.so';
        lib_name = 'libs/libphreeqcrm.so';
        disp('Downloading libphreeqcrm.so from https://github.com/simulkade/PhreeqcRM. Please wait...');
        try
            websave(lib_name, url, options);
            disp('libphreeqcrm.so is successfully downloaded.');
        catch
            disp('Could not download the libphreeqcrm.so file.')
            disp('Please download it from https://github.com/simulkade/PhreeqcRM/raw/master/linux_lib/libphreeqcrm-3.5.0.so')
            disp('rename it to libphreeqcrm.so, and copy it to the libs folder')
        end
    else
        disp('libphreeqcrm.so library exists.');
        disp('PhreeqcMatlab started successfully');
    end
    
    % IPhreeqc lib file download
    if ~isfile([current_path '/libs/libiphreeqc.so']) % lib files do not exist
        options = weboptions('Timeout', time_out);
        url = 'https://github.com/simulkade/PhreeqcRM/raw/master/IPhreeqc_lib/libiphreeqc-3.5.0.so';
        lib_name = 'libs/libiphreeqc.so';
        disp('Downloading libiphreeqc.so from https://github.com/simulkade/PhreeqcRM. Please wait...');
        try    
            websave(lib_name, url, options);
            disp('libiphreeqc.so is successfully downloaded.');
        catch
            disp('Could not download the libiphreeqc.so file.')
            disp('Please download it from https://github.com/simulkade/PhreeqcRM/raw/master/IPhreeqc_lib/libiphreeqc-3.5.0.so')
            disp('rename it to libiphreeqc.so, and copy it to the libs folder')
        end
    else
        disp('libiphreeqc.so library exists.');
        disp('IPhreeqc functions are available');
    end
end

