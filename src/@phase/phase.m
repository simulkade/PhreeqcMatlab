classdef phase
    %PHASE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        minerals
        amounts
    end
    
    methods
        function obj = phase(minerals, amounts)
            %PHASE Construct an instance of this class
            %   Detailed explanation goes here
            obj.minerals = minerals;
            obj.amounts = amounts;
        end
        
        function phase_string = phreeqc_phase(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            phase_string = obj.Property1 + inputArg;
        end
    end
end

