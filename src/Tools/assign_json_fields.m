function obj = assign_json_fields(obj, s, mapping)
%ASSIGN_JSON_FIELDS copy present fields from a decoded-JSON struct into obj.
%   obj     : the target object (returned updated; value-class semantics).
%   s       : struct produced by jsondecode of a JSON entry.
%   mapping : N-by-2 string array; column 1 = JSON field name,
%             column 2 = destination object property.
%
% Fields absent from s are skipped, so partial JSON entries are fine. This
% replaces the repeated `if isfield(s,'X'); obj.y = s.X; end` ladders in the
% per-class read_json methods.
for i = 1:size(mapping, 1)
    jf = char(mapping(i, 1));
    if isfield(s, jf)
        obj.(char(mapping(i, 2))) = s.(jf);
    end
end
end
