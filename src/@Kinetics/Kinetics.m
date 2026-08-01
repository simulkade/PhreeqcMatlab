classdef Kinetics < Reactant
    %KINETICS defines one or more kinetic (rate-controlled) reactions that act
    % on an aqueous solution over a period of time.
    %
    % Each named reaction carries its initial/current moles (-m0/-m), rate
    % parameters (-parms) and optional integration tolerance (-tol); the block
    % as a whole carries the integration schedule (-steps ... in N steps). The
    % rate laws themselves are BASIC programs supplied in a RATES block
    % (rates_definition); input_string() emits RATES before KINETICS as PHREEQC
    % requires.
    %
    % Because kinetics are time-dependent, the natural run path is IPhreeqc,
    % which integrates -steps directly:
    %   k  = Kinetics.calcite();
    %   out = k.equilibrate_in_phreeqc(Solution.seawater());   % raw PHREEQC output
    % (The inherited PhreeqcRM equilibrate_with places the KINETICS block in a
    % cell but does not advance time on its own; time-stepped transport is a
    % Layer-2 concern — see Advection1D/Transport1D.)
    %
    % See also Reactant, Phase, Solution.

    properties
        % name, number inherited from Reactant
        reaction_names(1,:) string   % kinetic reaction / RATES names, e.g. "Calcite"
        formula(1,:) string          % optional -formula per reaction
        m0(1,:) double               % initial moles of reactant per reaction
        m(1,:) double                % current moles of reactant per reaction
        parameters cell = {}         % per-reaction -parms vectors (cell of doubles)
        tol(1,:) double              % optional per-reaction -tol
        steps(1,:) double            % -steps time values (seconds)
        step_count {mustBeScalarOrEmpty} = []   % "-steps ... in N steps"
        rates_definition(1,1) string % full RATES block text (BASIC), '' if using database rates
    end

    methods
        function obj = Kinetics()
            % Kinetics constructs an empty kinetic-reaction definition.
            obj.name = "kinetics";
            obj.number = 1;
        end

        function slot = ic_slot(~)
            %IC_SLOT a Kinetics block occupies the KINETICS slot.
            slot = InitialConditions.KINETICS;
        end

        function str = input_string(obj)
            %INPUT_STRING RATES block (if any) followed by the KINETICS block.
            blocks = [ string(obj.rates_definition) ...
                       string(obj.phreeqc_string()) ];
            blocks = blocks(strlength(strip(blocks)) > 0);
            str = char(strjoin(blocks, newline));
        end

        function s = phreeqc_string(obj)
            %PHREEQC_STRING the KINETICS keyword block for this object.
            % Empty (no reactions) returns '' so it can be skipped in a SingleCell.
            if isempty(obj.reaction_names)
                s = '';
                return;
            end
            b = PhreeqcBlock("KINETICS", obj.number, obj.name);
            for i = 1:numel(obj.reaction_names)
                b = b.line(obj.reaction_names(i));
                if numel(obj.formula) >= i && strlength(obj.formula(i)) > 0
                    b = b.kv("-formula", obj.formula(i));
                end
                if numel(obj.m0) >= i
                    b = b.kv("-m0", obj.m0(i));
                end
                if numel(obj.m) >= i
                    b = b.kv("-m", obj.m(i));
                end
                if numel(obj.parameters) >= i && ~isempty(obj.parameters{i})
                    b = b.kv("-parms", obj.parameters{i});
                end
                if numel(obj.tol) >= i
                    b = b.kv("-tol", obj.tol(i));
                end
            end
            if ~isempty(obj.steps)
                if ~isempty(obj.step_count)
                    b = b.kv("-steps", obj.steps, "in", obj.step_count, "steps");
                else
                    b = b.kv("-steps", obj.steps);
                end
            end
            s = b.char();
        end

        function out_string = equilibrate_in_phreeqc(obj, solution, varargin)
            %EQUILIBRATE_IN_PHREEQC integrate the kinetic reactions acting on a
            % solution in IPhreeqc and return the raw PHREEQC output string.
            % The last optional argument is a database file name.
            if nargin > 2
                data_file = varargin{end};
            else
                data_file = 'phreeqc.dat';
            end
            iph_string = obj.combine_kinetics_solution_string(solution);
            iph = IPhreeqc();
            iph = iph.CreateIPhreeqc();
            try
                out_string = iph.RunPhreeqcString(iph_string, database_file(data_file));
                iph.DestroyIPhreeqc();
            catch ME
                out_string = 0;
                warning('PhreeqcMatlab:runFailed', ...
                    'Error running Phreeqc (check the solution and kinetics definition): %s', ME.message);
                iph.DestroyIPhreeqc();
            end
        end

        function out_string = combine_kinetics_solution_string(obj, solution)
            %COMBINE_KINETICS_SOLUTION_STRING RATES + KINETICS + SOLUTION in a
            % single simulation (the solution's trailing END terminates it).
            out_string = combine_phreeqc_strings(obj.input_string(), solution.phreeqc_string());
        end
    end

    methods (Static)
        function k = calcite(varargin)
            % k = Kinetics.calcite([seconds], [n_steps])
            % the classic PHREEQC-manual calcite dissolution rate.
            if nargin < 3
                k = Kinetics.from_json("CalciteKinetics");
            else
                k = Kinetics.from_json("CalciteKinetics", varargin{3});
            end
            if nargin >= 1 && ~isempty(varargin{1}); k.steps = varargin{1}; end
            if nargin >= 2 && ~isempty(varargin{2}); k.step_count = varargin{2}; end
        end

        function obj = read_json(entry)
            % read_json builds a Kinetics object from a decoded JSON entry.
            % Reactions.<Name>.{m0,m,parms,tol,formula}; block-level Steps,
            % StepCount; Rates is an array of BASIC lines (or a single string).
            obj = Kinetics();
            obj = assign_json_fields(obj, entry, [ ...
                "Name",   "name"; ...
                "Number", "number" ]);
            if isfield(entry, 'Reactions')
                names = fieldnames(entry.Reactions);
                n = numel(names);
                obj.reaction_names = string(names(:))';
                obj.m0 = nan(1, n); obj.m = nan(1, n); obj.tol = nan(1, n);
                obj.formula = strings(1, n);
                obj.parameters = cell(1, n);
                for i = 1:n
                    r = entry.Reactions.(names{i});
                    if isfield(r, 'm0');      obj.m0(i)  = r.m0;  end
                    if isfield(r, 'm');       obj.m(i)   = r.m;   end
                    if isfield(r, 'tol');     obj.tol(i) = r.tol; end
                    if isfield(r, 'parms');   obj.parameters{i} = double(r.parms(:))'; end
                    if isfield(r, 'formula'); obj.formula(i) = string(r.formula); end
                end
            end
            if isfield(entry, 'Steps');     obj.steps = double(entry.Steps(:))'; end
            if isfield(entry, 'StepCount'); obj.step_count = entry.StepCount;    end
            if isfield(entry, 'Rates')
                obj.rates_definition = strjoin(string(entry.Rates), newline);
            end
        end

        function obj = from_json(name, varargin)
            % from_json builds a Kinetics object from a named JSON entry.
            %   Kinetics.from_json("CalciteKinetics")                 % kinetics.json
            %   Kinetics.from_json("CalciteKinetics", "kinetics.json")
            if nargin < 2; file = 'kinetics.json'; else; file = varargin{1}; end
            data = jsondecode(fileread(database_file(file)));
            key = char(name);
            if ~isfield(data, key)
                error('PhreeqcMatlab:jsonEntryNotFound', ...
                    'No entry "%s" in %s.', key, file);
            end
            obj = Kinetics.read_json(data.(key));
        end
    end
end
