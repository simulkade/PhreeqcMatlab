classdef Gas
    % GAS defines a constant volume or constant pressure gas phase
    
    properties
        name(1,1) string
        number(1,1) double {mustBeNonnegative, mustBeInteger}
    end
    
    methods
        function obj = Gas(inputArg1,inputArg2)
            %GAS Construct an instance of this class
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

