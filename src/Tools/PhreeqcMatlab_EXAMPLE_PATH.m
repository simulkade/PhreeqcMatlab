function example_path = PhreeqcMatlab_EXAMPLE_PATH()
%PhreeqcMatlab_EXAMPLE_PATH returns path to the example folder
p = mfilename('fullpath');
file_name = mfilename;
current_path = p(1:end-1-length(file_name));
example_path = fullfile(current_path, '..', '..', 'examples');
end

