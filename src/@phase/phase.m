classdef Phase
    %PHASE 
    % define a new phase (e.g. a mineral) that is in equilibrium with a
    % solution defined by @solution class
    % for gas phases, use gas class
    
    properties
        name
        number
        mineral_names
        moles
        
    end
    
    methods
        function obj = Phase()
            %PHASE Construct an instance of this class
            %   Detailed explanation goes here
            obj.name="empty phase";
            obj.number=1;
            obj.mineral_names = [];
            obj.moles = [];
        end
        
        function phase_string = phreeqc_phase(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            phase_string = strjoin(["EQUILIBRIUM_PHASE " num2str(obj.number) " " obj.name]);
        end
    end
end

