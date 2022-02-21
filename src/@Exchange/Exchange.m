classdef Exchange
    % Exchange defines an ion exchanger that can be equilibrated with an
    % aqueous solution

    properties
        name(1,1) string
        number(1,1) double {mustBeNonnegative, mustBeInteger}
        
    end

    methods
        function obj = Exchange(inputArg1,inputArg2)
            %UNTITLED Construct an instance of this class
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