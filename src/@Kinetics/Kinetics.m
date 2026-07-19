classdef Kinetics < Reactant
    %KINETICS Summary of this class goes here
    %   Detailed explanation goes here

    properties
        % name, number inherited from Reactant
    end
    
    methods
        function obj = Kinetics()
            % Kinetics constructs an empty kinetic-reaction definition.
            % Reaction/rate fields plus phreeqc_string()/read_json() are
            % implemented in the Milestone 3 object-model work (see ROADMAP.md).
            obj.name = "kinetics 1";
            obj.number = 1;
        end

        function s = phreeqc_string(~)
            %PHREEQC_STRING not yet implemented (Milestone 3).
            s = ''; %#ok<NASGU>
            error('PhreeqcMatlab:notImplemented', ...
                ['Kinetics.phreeqc_string is implemented in Milestone 3. ' ...
                 'For now, define the KINETICS block manually.']);
        end
    end
end

