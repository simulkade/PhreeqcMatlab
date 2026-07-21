classdef Exchange < Reactant
    %EXCHANGE defines an ion exchanger that can be equilibrated with an
    % aqueous solution.
    %
    % A minimal exchanger just names the exchange sites and their amounts,
    % e.g. the default "X" exchanger from phreeqc.dat:
    %   ex = Exchange();
    %   ex.exchange_species = "X";
    %   ex.moles = 1.0;
    %   SR = ex.equilibrate_with(Solution.seawater());
    %
    % A custom exchanger additionally supplies its own EXCHANGE_MASTER_SPECIES
    % and EXCHANGE_SPECIES definitions (mirroring @Surface); input_string()
    % then emits all three blocks in the order PHREEQC requires.
    %
    % See also Reactant, Surface, Solution.

    properties
        % name, number inherited from Reactant
        exchange_species(1,:) string             % exchange site names, e.g. "X"
        moles(1,:) double                        % moles of each exchange site
        equilibrate_solution {mustBeScalarOrEmpty} = []   % optional: solution number to pre-equilibrate with
        exchange_master_species(:, 1) string     % optional custom EXCHANGE_MASTER_SPECIES lines
        exchange_species_reactions(:, 1) string  % optional custom EXCHANGE_SPECIES reactions
        log_k(:,1) double                        % log_k for each custom reaction
        dh(:,1) double                           % delta_h for each custom reaction
    end

    methods
        function obj = Exchange()
            % Exchange constructs an empty ion-exchanger definition.
            obj.name = "exchange";
            obj.number = 1;
        end

        function slot = ic_slot(~)
            %IC_SLOT an Exchange occupies the EXCHANGE slot.
            slot = InitialConditions.EXCHANGE;
        end

        function str = input_string(obj)
            %INPUT_STRING assemble the (optional) custom definition blocks and
            % the EXCHANGE block into one string, in PHREEQC order:
            % EXCHANGE_MASTER_SPECIES, EXCHANGE_SPECIES, then EXCHANGE.
            blocks = [ string(obj.master_species_block()) ...
                       string(obj.species_block()) ...
                       string(obj.phreeqc_string()) ];
            blocks = blocks(strlength(strip(blocks)) > 0);
            str = char(strjoin(blocks, newline));
        end

        function s = phreeqc_string(obj)
            %PHREEQC_STRING the EXCHANGE keyword block for this exchanger.
            % Empty (no sites defined) returns '' so it can be skipped when
            % assembling a SingleCell.
            if isempty(obj.exchange_species)
                s = '';
                return;
            end
            b = PhreeqcBlock("EXCHANGE", obj.number, obj.name);
            for i = 1:numel(obj.exchange_species)
                b = b.kv(obj.exchange_species(i), obj.moles(i));
            end
            if ~isempty(obj.equilibrate_solution)
                b = b.kv("-equilibrate", obj.equilibrate_solution);
            end
            s = b.char();
        end
    end

    methods (Access = private)
        function s = master_species_block(obj)
            %MASTER_SPECIES_BLOCK optional EXCHANGE_MASTER_SPECIES block ('' if none).
            if isempty(obj.exchange_master_species)
                s = '';
                return;
            end
            b = PhreeqcBlock("EXCHANGE_MASTER_SPECIES");
            for i = 1:numel(obj.exchange_master_species)
                b = b.line(obj.exchange_master_species(i));
            end
            s = b.char();
        end

        function s = species_block(obj)
            %SPECIES_BLOCK optional EXCHANGE_SPECIES block ('' if none).
            if isempty(obj.exchange_species_reactions)
                s = '';
                return;
            end
            b = PhreeqcBlock("EXCHANGE_SPECIES");
            for i = 1:numel(obj.exchange_species_reactions)
                b = b.line(obj.exchange_species_reactions(i));
                if ~isempty(obj.log_k) && numel(obj.log_k) >= i
                    b = b.kv("log_k", obj.log_k(i));
                end
                if ~isempty(obj.dh) && numel(obj.dh) >= i
                    b = b.kv("delta_h", obj.dh(i));
                end
            end
            s = b.char();
        end
    end

    methods (Static)
        function ex = sodium_exchanger(varargin)
            % ex = Exchange.sodium_exchanger([moles])
            % the default phreeqc.dat "X" exchanger, 1 mol of sites by default.
            ex = Exchange();
            ex.name = "Sodium exchanger";
            ex.number = 1;
            ex.exchange_species = "X";
            if nargin > 0; ex.moles = varargin{1}; else; ex.moles = 1.0; end
        end

        function obj = read_json(entry)
            % read_json builds an Exchange from a decoded JSON entry.
            % Composition -> exchange_species/moles; optional MasterSpecies /
            % Reactions / LogK / DeltaH define a custom exchanger.
            obj = Exchange();
            obj = assign_json_fields(obj, entry, [ ...
                "Name",   "name"; ...
                "Number", "number" ]);
            if isfield(entry, 'Composition')
                comp = fieldnames(entry.Composition);
                obj.exchange_species = string(comp(:))';
                obj.moles = cellfun(@(x)getfield(entry.Composition, {1}, x), comp)';
            end
            if isfield(entry, 'MasterSpecies')
                obj.exchange_master_species = string(entry.MasterSpecies);
            end
            if isfield(entry, 'Reactions')
                obj.exchange_species_reactions = string(entry.Reactions);
            end
            if isfield(entry, 'LogK')
                obj.log_k = double(entry.LogK);
            end
            if isfield(entry, 'DeltaH')
                obj.dh = double(entry.DeltaH);
            end
        end

        function obj = from_json(name, varargin)
            % from_json builds an Exchange from a named entry in a JSON file.
            %   Exchange.from_json("SodiumExchanger")               % exchange.json
            %   Exchange.from_json("SodiumExchanger", "exchange.json")
            if nargin < 2; file = 'exchange.json'; else; file = varargin{1}; end
            data = jsondecode(fileread(database_file(file)));
            key = char(name);
            if ~isfield(data, key)
                error('PhreeqcMatlab:jsonEntryNotFound', ...
                    'No entry "%s" in %s.', key, file);
            end
            obj = Exchange.read_json(data.(key));
        end
    end
end
