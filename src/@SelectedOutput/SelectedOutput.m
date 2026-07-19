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
            % SELECTED_OUTPUT (+ USER_PUNCH) block, terminated with END.
            b = obj.build_block();
            b = b.flag("END");
            selected_output_string = b.char();
        end

        function selected_output_string = phreeqc_string_without_end(obj)
            % SELECTED_OUTPUT (+ USER_PUNCH) block without a trailing END,
            % for concatenation with following keyword blocks.
            selected_output_string = obj.build_block().char();
        end
    end

    methods (Access = private)
        function b = build_block(obj)
            % Shared builder for the SELECTED_OUTPUT / USER_PUNCH block.
            b = PhreeqcBlock("SELECTED_OUTPUT", obj.number);
            for i = 1:numel(obj.content)
                b = b.line(obj.content(i));
            end
            if ~isempty(obj.punch) && any(strlength(string(obj.punch)) > 0)
                b = b.line("USER_PUNCH " + PhreeqcBlock.fmt(obj.number));
                for i = 1:numel(obj.punch)
                    b = b.line(obj.punch(i));
                end
            end
        end
    end
    methods(Static)
        

    end
end

