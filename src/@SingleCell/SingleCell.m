classdef SingleCell
    %SINGLECELL is a class that contains a mixture of different components.
    % it contains at least an aqueous solution. It can contain solid and
    % gas phases too, which are defined as PhreeqcMatlab objects.
    
    properties
        aqueous_solution
        equilibrium_phase
        surface_specie
        exchanger
        reation_rate
        gas_phase
    end
    
    methods
        function obj = SingleCell(aq_solution, eq_phase, )
            %SINGLECELL Construct an instance of this class
            %   Detailed explanation goes here
            obj.Property1 = inputArg1 + inputArg2;
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

