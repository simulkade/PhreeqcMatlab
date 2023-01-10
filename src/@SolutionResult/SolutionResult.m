classdef SolutionResult
    %SOLUTIONRESULT is a class that contains the result of running a
    % fluid simulation in PhreeqcMatlab. The class also facilitates
    % exporting the results to well-known and usable formats such as JSON
    % and Excel.
    % TODO: add more solution properties including viscosity, conductance,
    % species equilibrium constants, osmotic coefficient, etc
    
    properties
        name(1,1) string
        number(1,1) double {mustBeNonnegative, mustBeInteger}
        components(1,:) string
        concentrations(1,:) double
        species(1,:) string
        species_concentrations(1,:) double
        species_molalities(1,:) double
        species_activity_coef(1,:) double
        species_charge(1,:) double
        alkalinity(1,1) double
        pH(1,1) double
        pe(1,1) double
        temperature(1,1) double
        pressure(1,1) double
        ionic_strength(1,1) double
        water_mass(1,1) double
        charge_balance(1,1) double
        percent_error(1,1) double
        density(1,1) double
        water_density(1,1) double
        specific_conductance(1,1) double
        relative_dielectric_constant(1,1) double
        osmotic_coefficient(1,1) double
        viscosity(1,1) double
        % diffusivity(1,:) matlab restarts when it is called
    end
    
    methods
        function obj = SolutionResult(sol)
            % creates an empty instance of SolutionResults based on an
            % input Solution object
            obj.name = sol.name;
            obj.number = sol.number;
            obj.pressure = sol.pressure;
        end
        
    end
end

