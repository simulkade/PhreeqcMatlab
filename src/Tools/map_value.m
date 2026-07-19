function v = map_value(m, key, default)
%MAP_VALUE safe lookup of key in a containers.Map, with a fallback.
%   v = map_value(m, key)          returns NaN if key is absent
%   v = map_value(m, key, default) returns default if key is absent
%
% Used when reading PhreeqcRM/IPhreeqc SELECTED_OUTPUT tables (which are keyed
% by the exact PHREEQC column-header strings) so that a renamed/absent column
% degrades to a fallback value instead of throwing a hard key error that would
% discard the whole result.
if nargin < 3
    default = NaN;
end
if isa(m, 'containers.Map') && isKey(m, key)
    v = m(key);
else
    v = default;
end
end
