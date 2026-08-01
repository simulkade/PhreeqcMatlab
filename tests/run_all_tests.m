function results = run_all_tests()
%RUN_ALL_TESTS runs the assertion-based PhreeqcMatlab test suite.
% Errors (nonzero exit under -batch) if any test fails, so it can gate CI.
%
% Launch MATLAB via ./run_matlab.sh so the 3.8.6 native libraries load, e.g.:
%   ./run_matlab.sh -batch "run_all_tests"
here = fileparts(mfilename('fullpath'));
results = runtests(here);
disp(table(results));
nfailed = nnz([results.Failed]);
if nfailed > 0
    error('PhreeqcMatlab:testsFailed', '%d of %d test(s) failed.', ...
        nfailed, numel(results));
end
fprintf('All %d tests passed.\n', numel(results));
end
