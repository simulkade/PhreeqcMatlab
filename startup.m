function startup()

%{
startup

Startup the phreeqc 
%}
global DATABASE_PATH
try
	p = mfilename('fullpath');
	file_name = mfilename;
	current_path = p(1:end-1-length(file_name));
	addpath([current_path '/libs']);
	addpath([current_path '/src']);
    addpath([current_path '/database']);
    DATABASE_PATH = [current_path '/database'];
catch 
    error("Something went wrong with the PhreeqcMatlab start up."); 
end
