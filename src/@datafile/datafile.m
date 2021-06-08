classdef datafile
    %DATAFILE
    % datafile is a class that works with phreeqc data files
    % Currently, it is only used to extract the relevant data for the user
    % interface
    
    properties
        filename % name of the phreeqc datafile
        datafilepath
    end
    
    methods
        function obj = datafile(filename, datafilepath)
            %DATAFILE accepts two arguments filename, that is the name of
            %the database and filepath that is the absolute path to the
            %datafile
            obj.filename = filename;
            obj.datafilepath = datafilepath;
        end
        
        function primary_species = extract_primary_species(obj)
            % extract_primary_species extracts all the primary species from
            % a phreeqc datafile
            % 
        end
    end
end

