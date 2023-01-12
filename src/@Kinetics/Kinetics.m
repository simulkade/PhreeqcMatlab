classdef Kinetics
    %KINETICS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name(1,1) string
        number(1,1) double {mustBeNonnegative, mustBeInteger}
    end
    
    methods
        function obj = Kinetics()
            %KINETICS Construct an instance of this class
            %   Detailed explanation goes here
            obj.name = "kinetics 1";
            obj.number = 1;
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

