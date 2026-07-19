classdef Kinetics
    %KINETICS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name(1,1) string
        number(1,1) double {mustBeNonnegative, mustBeInteger}
    end
    
    methods
        function obj = Kinetics()
            % Kinetics constructs an empty kinetic-reaction definition.
            % Reaction/rate fields plus phreeqc_string()/read_json() are
            % implemented in the Milestone 3 object-model work (see ROADMAP.md).
            obj.name = "kinetics 1";
            obj.number = 1;
        end
    end
end

