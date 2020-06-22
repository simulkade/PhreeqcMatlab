classdef solution
    %SOLUTION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name
        number
        unit
        components
        concentrations
        charge_balance_component
        charge_balance
        density
        pH
    end
    
    methods
        function obj = solution(primary_species, concentration)
            %SOLUTION Construct an instance of this class
            %   Detailed explanation goes here
            obj.components = primary_species;
            obj.concentrations = concentration;
        end
        
        function obj = seawater(obj)
            obj.components = ["Na", "Cl", "Ca", "Mg", "pH", "C"];
            
        end
        
        function solution_string = phreeqc_solution(obj)
            %phreeqc_solution returns a string of phreeqc format for the
            %string object
            outputArg = obj.Property1 + inputArg;
        end
    end
end

