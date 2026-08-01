function string_out = combine_phreeqc_strings(string1, string2)
%COMBINE_PHREEQC_STRINGS join two Phreeqc keyword blocks with a newline.
% Robust to blocks that do or do not carry a trailing newline (PhreeqcBlock
% output has none), so consecutive keywords never run together on one line.
string_out = char(strip(string(string1)) + newline + strip(string(string2)));
end

