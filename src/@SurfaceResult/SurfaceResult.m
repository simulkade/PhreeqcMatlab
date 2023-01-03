classdef SurfaceResult
    % SurfaceResult is a class that contains the result of equilibration of
    % a solution with a surface in PhreeqcMatlab. The class also facilitates
    % exporting the results to well-known and usable formats such as JSON
    % and Excel. The solution properties are reported in SolutionResult class.
    % TODO: add more IO functions
    
    properties
        name(1,1) string
        number(1,1) double {mustBeNonnegative, mustBeInteger}
        mass(1,1) double
        surface_species(1,:) string
        surface_species_mole_fraction(1,:) double
        surface_species_molalities(1,:) double
        surface_species_activity_coef(:,1) double
        charge_density_plane_0(1,1) double
        charge_density_plane_1(1,1) double
        charge_density_plane_2(1,1) double
        charge_density_dl(1,1) double
        potential_plane_0(1,1) double
        potential_plane_1(1,1) double
        potential_plane_2(1,1) double
        water_mass(1,1) double
        water_mass_dl(1,1) double
        elements_edl(1,:) string
        species_edl(1,:) string
        element_moles_edl(1,:) double
        species_moles_edl(1,:) double
        % diffusivity(1,:) matlab restarts when it is called
    end
    
    methods
        function obj = SurfaceResult(s)
            % creates an empty instance of SurfaceResult based on an
            % input Surface object
            obj.name = s.name;
            obj.number = s.number;
            obj.mass = s.mass;
        end
        
    end
end

