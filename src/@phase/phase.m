classdef Phase
    %{
    PHASE 
    define a new phase (e.g. a mineral) that is in equilibrium with a
    solution defined by @solution class
    for gas phases, use gas class
        name(1,1) string
        number(1,1) double {mustBeNonnegative, mustBeInteger}
        phase_names(1,:) string
        alternative_formula(1,:) string
        moles(1,:) double
        saturation_indices(1,:) double
        force_equality(1,:) logical
        dissolve_only(1,:) logical
        precipitate_only(1,:) logical
    %}
    properties
        name(1,1) string
        number(1,1) double {mustBeNonnegative, mustBeInteger}
        phase_names(1,:) string
        alternative_formula(1,:) string
        moles(1,:) double
        saturation_indices(1,:) double
        force_equality(1,:) logical
        dissolve_only(1,:) logical
        precipitate_only(1,:) logical
    end
    
    methods
        function obj = Phase()
            %PHASE Construct an instance of this class
            %   Detailed explanation goes here
            obj.name="empty phase";
            obj.number=1;
            obj.phase_names = [];
            obj.alternative_formula = [];
            obj.moles = [];
            obj.saturation_indices = [];
            obj.force_equality = [];
            obj.dissolve_only = [];
            obj.precipitate_only = [];
        end
        
        function phase_string = phreeqc_phase(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            n_phase = length(obj.phase_names);
            if n_phase==0
                phase string = "\n";
            else
                phase_string = strjoin(["EQUILIBRIUM_PHASE " num2str(obj.number) " " obj.name "\n"]);
                for i = 1:n_phase
                    phase_string = strjoin([phase_string obj.phase_names(i)]); % phase name
                    phase_string = strjoin([phase_string "  " num2str(obj.saturation_indices(i))]); % saturation index
                    if ~isempty(obj.alternative_formula)
                        if  obj.alternative_formula(i)~=""
                            phase_string = strjoin([phase_string "  " obj.alternative_formula(i)]);
                        end
                    end
                    phase_string = strjoin([phase_string "  " num2str(obj.moles(i))]);
                    if ~isempty(obj.precipitate_only)
                        if obj.precipitate_only(i)
                            phase_string = strjoin([phase_string "  precipitate_only"]);
                        elseif ~isempty(obj.dissolve_only)
                            if obj.dissolve_only(i)
                                phase_string = strjoin([phase_string "  dissolve_only"]);
                            end
                        end
                    end
                    phase_string = strjoin([phase_string "\n"]);
                    if ~isempty(obj.force_equality) && obj.force_equality(i)
                        phase_string = strjoin([phase_string "-force_equality \n"]);
                    end
                end
            end
            phase_string = sprintf(char(phase_string));
        end
        
        
    end
    
     methods(Static)
         function ch = chalk()
             % ch = Phase.chalk();
             % defines a chalk phase composed of pure calcite
             ch = Phase();
             ch.name = "Chalk";
             ch.number = 1;
             ch.phase_names = "Calcite";
             ch.moles = 0.0;
             ch.saturation_indices = 0.0;
         end
         
     end
end

