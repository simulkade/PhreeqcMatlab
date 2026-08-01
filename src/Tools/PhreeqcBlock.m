classdef PhreeqcBlock
    %PHREEQCBLOCK fluent builder for a Phreeqc keyword block.
    %
    % Replaces the fragile strjoin([acc newpiece "\n"]) / sprintf(char(...))
    % pattern used across the @Solution/@Surface/@Phase/@Gas phreeqc_string
    % methods. It guarantees:
    %   * deterministic spacing (identifiers and values separated by a fixed
    %     gap, never by accidental strjoin whitespace),
    %   * empty/unspecified fields are suppressed (no more "pe  " or malformed
    %     lines from num2str([])),
    %   * consistent numeric formatting (scalars and row vectors alike).
    %
    % It is a value class, matching the PhreeqcMatlab reassign-or-lose idiom:
    %   b = PhreeqcBlock("SOLUTION", 1, "seawater");
    %   b = b.kv("pH", 8.1, "charge");
    %   b = b.kv("temp", 25);
    %   b = b.flag("END");
    %   str = b.char();      % ready for IPhreeqc/PhreeqcRM
    %
    % See also Solution/phreeqc_string, Surface/phreeqc_string.

    properties (Access = private)
        lines(1,:) string = strings(1,0)
        sep(1,1) string = "    "   % gap between tokens on a line
    end

    methods
        function obj = PhreeqcBlock(keyword, number, name)
            %PHREEQCBLOCK start a block with an optional "KEYWORD number name" header.
            if nargin >= 1 && strlength(string(keyword)) > 0
                header = string(keyword);
                if nargin >= 2 && ~isempty(number)
                    header = header + " " + PhreeqcBlock.fmt(number);
                end
                if nargin >= 3 && strlength(string(name)) > 0
                    header = header + " " + string(name);
                end
                obj.lines(end+1) = header;
            end
        end

        function obj = kv(obj, key, value, varargin)
            %KV append "key value extra..." — suppressed entirely if value is empty.
            % Numeric values (scalar or vector) are formatted consistently;
            % trailing extras (e.g. "charge", "as HCO3-") are appended verbatim.
            if nargin >= 3 && PhreeqcBlock.isEmptyValue(value)
                return;
            end
            parts = string(key);
            if nargin >= 3
                parts(end+1) = PhreeqcBlock.fmt(value);
            end
            for i = 1:numel(varargin)
                extra = varargin{i};
                if PhreeqcBlock.isEmptyValue(extra); continue; end
                parts(end+1) = PhreeqcBlock.fmt(extra); %#ok<AGROW>
            end
            obj.lines(end+1) = strjoin(parts, obj.sep);
        end

        function obj = kvopt(obj, key, value)
            %KVOPT append "key value", or just "key" when value is empty.
            % Use for identifiers whose value is optional (e.g. "-diffuse_layer").
            if PhreeqcBlock.isEmptyValue(value)
                obj.lines(end+1) = string(key);
            else
                obj.lines(end+1) = strjoin([string(key) PhreeqcBlock.fmt(value)], obj.sep);
            end
        end

        function obj = flag(obj, identifier)
            %FLAG append a value-less identifier line (e.g. "-fixed_pressure", "END").
            if strlength(string(identifier)) > 0
                obj.lines(end+1) = string(identifier);
            end
        end

        function obj = line(obj, text)
            %LINE append a pre-formatted raw line verbatim.
            obj.lines(end+1) = string(text);
        end

        function obj = lineIf(obj, cond, text)
            %LINEIF append a raw line only when cond is true.
            if cond
                obj.lines(end+1) = string(text);
            end
        end

        function s = string(obj)
            %STRING return the block as a newline-joined string.
            s = strjoin(obj.lines, newline);
        end

        function s = char(obj)
            %CHAR return the block as a char row vector.
            s = char(obj.string());
        end
    end

    methods (Static)
        function s = fmt(v)
            %FMT format a scalar/vector value into a space-joined token string.
            if ischar(v)
                s = string(v);                       % a char row vector is one token
            elseif isstring(v)
                s = strjoin(v(:)', " ");             % string array -> space-joined
            elseif isnumeric(v) || islogical(v)
                s = strjoin(string(v(:))', " ");     % numeric scalar/vector
            else
                s = string(v);
            end
        end

        function tf = isEmptyValue(v)
            %ISEMPTYVALUE true for [] and for "" / '' (fields to suppress).
            tf = isempty(v) || ((isstring(v) || ischar(v)) && strlength(string(v)) == 0);
        end
    end
end
