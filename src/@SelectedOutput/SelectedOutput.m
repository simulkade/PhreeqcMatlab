classdef SelectedOutput
    %SELECTEDOUTPUT 
    %the idea is to define functions to combine several different selected
    %output blocks defined as this simple class
    
    properties
        name(1,1) string
        number(1,1) double {mustBeNonnegative, mustBeInteger}
        content(1,:) string
        punch(1,:) string
    end
    
    methods
        function obj = SelectedOutput()
            %SELECTEDOUTPUT create an empty instance of selected output
            obj.name = "empty selected output";
            obj.number = 1;
        end
        
        function selected_output_string = phreeqc_string(obj)
            %selected_output_string = phreeqc_string(obj)
            % uses strjoin with \n and sprintf and char to create a
            % selected output string callable by phreeqc
            selected_output_string = sprintf(...
                char(...
                strjoin([strjoin(["\nSELECTED_OUTPUT" num2str(obj.number)]) ...
                obj.content ...
                strjoin(["USER_PUNCH" num2str(obj.number)])...
                obj.punch "END\n"], '\n')...
                )...
                );
        end

        function selected_output_string = phreeqc_string_without_end(obj)
            %selected_output_string = phreeqc_string(obj)
            % uses strjoin with \n and sprintf and char to create a
            % selected output string callable by phreeqc
            selected_output_string = sprintf(...
                char(...
                strjoin([strjoin(["\nSELECTED_OUTPUT" num2str(obj.number)]) ...
                obj.content ...
                strjoin(["USER_PUNCH" num2str(obj.number)])...
                obj.punch], '\n')...
                )...
                );
        end
    
        
    end
    methods(Static)
        

    end
end

