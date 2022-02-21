classdef Surface
    %SURFACE defines a surface species that can be equilibrated with a
    %solution object
    
    properties
        name(1,1) string
        number(1,1) double {mustBeNonnegative, mustBeInteger}
        binding_site(1,1) double {mustBeNonnegative, mustBeInteger}
        surface_master_species(1,:) string
        surface_species_reactions(1,:) string
        log_k(1,:) double
        dh(1,:) double
        specific_surface_area
        sites_units   % absolute or density
        edl_layer
    end
    
    methods
        function obj = Surface(binding_site,surface_master_species)
            %SURFACE Construct an instance of this class
            %   Detailed explanation goes here
            obj.binding_site = binding_site;
            obj.surface_master_species = surface_master_species;
        end
        
        function surface_string = phreeqc_string(obj)
           surface_string = ["SURFACE" num2str(obj.number) obj.name "\n"];
        end
    end
    
    methods (Static)
        function obj = calcite_surface()
            obj = Surface();
        end
        
        function obj = clay_surface()
            obj = Surface();
        end
    end
end

