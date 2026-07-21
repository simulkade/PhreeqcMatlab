function tf = fvtool_available()
%FVTOOL_AVAILABLE true if the external FVTool package is on the MATLAB path.
%
% FVTool (https://github.com/simulkade/FVTool) is an optional dependency used
% only for multi-dimensional reactive transport (see PhreeqcFVToolTransport).
% It is not bundled with PhreeqcMatlab. Callers should guard on this and emit a
% helpful message when it is missing rather than failing with "Undefined
% function 'createMesh2D'".
%
% Detected by the presence of FVTool's mesh constructors.
tf = ~isempty(which('createMesh2D')) || ~isempty(which('createMesh1D')) || ...
     ~isempty(which('createMesh3D'));
end
