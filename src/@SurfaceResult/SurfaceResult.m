classdef SurfaceResult
    % SurfaceResult is a class that contains the result of equilibration of
    % a solution with a surface in PhreeqcMatlab. The class also facilitates
    % exporting the results to well-known and usable formats such as JSON
    % and Excel. The solution properties are reported in SolutionResult class.
    % TODO: add more IO functions
    
    properties
        name(1,1) string
        number(1,1) double {mustBeNonnegative, mustBeInteger}
        species(1,:) string
        species_concentrations(1,:) double
        species_molalities(1,:) double
        species_activity_coef(1,:) double
        species_charge(1,:) double
        water_mass(1,1) double
        charge_balance(1,1) double
        percent_error(1,1) double
        density(1,1) double
        % diffusivity(1,:) matlab restarts when it is called
    end
    
    methods
        function obj = SurfaceResult(sol)
            % creates an empty instance of SurfaceResult based on an
            % input Solution object
            obj.name = sol.name;
            obj.number = sol.number;
        end
        
    end
end

