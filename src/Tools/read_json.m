function json_struct = read_json(file_name)
%READ_JSON reads and decode a json input file to an structure

% TODO: check for the quality of the input file

json_struct = decode(fileread(file_name));

end

