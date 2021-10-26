classdef SolutionResult
    %SOLUTIONRESULT is a class that contains the result of running a
    % fluid simulation in PhreeqcMatlab. The class also facilitates
    % exporting the results to well-known and usable formats such as JSON
    % and Excel.
    
    properties
        Property1
    end
    
    methods
        function obj = SolutionResult(inputArg1,inputArg2)
            %SOLUTIONRESULT Construct an instance of this class
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

