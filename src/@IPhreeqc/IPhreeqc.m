classdef IPhreeqc
    % A wrapper for IPhreeqc package
    
    properties
        id
    end
    
    methods
        function obj = IPhreeqc()
            %IPhreeqc Construct an instance of this class without creating
            %an IPhreeqc instance; Call CreateIPhreeqc to create an
            %instance and initialize the object id
            %
            if ~libisloaded('libiphreeqc')
                [notfound,warnings]= loadlibrary('libiphreeqc','IPhreeqc.h');
                disp(warnings);
            end
% 			id = calllib('libiphreeqc','CreateIPhreeqc');
%             obj.id = id;
        end
        
        function obj_out = CreateIPhreeqc(obj)
            obj_out = obj;
            if isempty(obj.id)
                id_new = calllib('libiphreeqc','CreateIPhreeqc');
                obj_out.id = id_new;
            else
                warning('The IPhreeqc object is already created. Please call this function with an empty IPhreeqc object');
            end
        end

        function obj = AssignIPhreeqc(id)
            % AssignIPhreeqc assigns the existing id to an IPhreeqc object
            % This function does not exist in the original IPhreeqc C wrapper
            % and written for the PhreeqcMatlab
            obj.id = id;            
        end
        
        function status = AccumulateLine(obj, line_str)
            % AccumulateLine Accumlulate line(s) for input to phreeqc. 
            status = calllib('libiphreeqc','AccumulateLine', obj.id, line_str);
        end
        
        function status = AddError(obj, error_msg)
            % AddError Appends the given error message and increments the error count. Internally used to create an error condition. 
            status = calllib('libiphreeqc','AddError', obj.id, error_msg);
        end
        
        function n_warn_count = AddWarning(obj, warn_msg)
            % AddWarning Appends the given warning message and increments the warning count. Internally used to create a warning condition. 
            % The current warning count if successful; otherwise a negative value indicates an error occured (see IPQ_RESULT).
            n_warn_count = calllib('libiphreeqc','AddWarning', obj.id, warn_msg);
        end
        
        function status = ClearAccumulatedLines(obj)
            % ClearAccumulatedLines Clears the accumulated input buffer. Input buffer is accumulated from calls to AccumulateLine. 
            status = calllib('libiphreeqc','ClearAccumulatedLines', obj.id);
        end
        
        function status =  DestroyIPhreeqc(obj)
            % Release an IPhreeqc instance from memory.
            status = calllib('libiphreeqc','DestroyIPhreeqc', obj.id);
        end
        
        function comp_name = GetComponent(obj, n)
            % Retrieves the given component.
            % id	The instance id returned from CreateIPhreeqc.
            % n	The zero-based index of the component to retrieve.
            % A null terminated string containing the given component. Returns an empty string if n is out of range.
            comp_name = calllib('libiphreeqc','GetComponent', obj.id, n);
        end
        
        function n_comp = GetComponentCount(obj)
            % Retrieves the number of components in the current component list.
            % Returns
            % The current count of components. A negative value indicates an error occured (see IPQ_RESULT).
            n_comp = calllib('libiphreeqc','GetComponentCount', obj.id);
        end
        
        function n_sel_out = GetCurrentSelectedOutputUserNumber(obj)
            % Retrieves the current SELECTED_OUTPUT user number for use in subsequent calls to 
            % (GetSelectedOutputColumnCount, GetSelectedOutputFileName, GetSelectedOutputRowCount,
            %  GetSelectedOutputString, GetSelectedOutputStringLine, GetSelectedOutputStringLineCount,
            %  GetSelectedOutputValue, GetSelectedOutputValue2) routines. The initial setting after calling CreateIPhreeqc is 1.
            % Returns
            % The current SELECTED_OUTPUT user number.
            n_sel_out = calllib('libiphreeqc','GetCurrentSelectedOutputUserNumber', obj.id);
        end
        
        function file_name = GetDumpFileName(obj)
            % Retrieves the name of the dump file. This file name is 
            % used if not specified within DUMP input. The default value is dump.id.out.
            % Returns
            % filename The name of the file to write DUMP output to.
            file_name = calllib('libiphreeqc','GetDumpFileName', obj.id);
        end
        
        function status_dump = GetDumpFileOn(obj)
            % Retrieves the current value of the dump file switch.
            % Returns
            % Non-zero if output is written to the DUMP (dump.id.out if unspecified) file, 0 (zero) otherwise.
            status_dump = calllib('libiphreeqc','GetDumpFileOn', obj.id);
        end
        
        function dump_output = GetDumpString(obj)
            % Retrieves the string buffer containing DUMP output.
            % Returns
            % A null terminated string containing DUMP output.
            dump_output = calllib('libiphreeqc','GetDumpString', obj.id);
        end

        function dump_line = GetDumpStringLine(obj, n)
            % Retrieves the given dump line.
            % Parameters
            %     id	The instance id returned from CreateIPhreeqc.
            %     n	The zero-based index of the line to retrieve.
            % Returns
            %     A null terminated string containing the given line. Returns an empty string if n is out of range.
            % Precondition
            %     SetDumpStringOn must have been set to true (non-zero).
            dump_line = calllib('libiphreeqc','GetDumpStringLine', obj.id, n);
        end
        
        function line_count = GetDumpStringLineCount(obj)
            % Retrieves the number of lines in the current dump string buffer.
            % Parameters
            % id	The instance id returned from CreateIPhreeqc.
            % Returns
            % The number of lines.
            % Precondition
            % SetDumpStringOn must have been set to true (non-zero).
            line_count = calllib('libiphreeqc','GetDumpStringLineCount', obj.id);
        end
        
        function status = GetDumpStringOn(obj)
            % Retrieves the current value of the dump string switch.
            % Parameters
            % id	The instance id returned from CreateIPhreeqc.
            % Returns
            % Non-zero if output defined by the DUMP keyword is stored, 0 (zero) otherwise.
            % See also
            % GetDumpFileOn, GetDumpString, GetDumpStringLine, GetDumpStringLineCount, SetDumpFileOn, SetDumpStringOn
            status = calllib('libiphreeqc','GetDumpStringOn', obj.id);
        end
    %         
        function file_name = GetErrorFileName(obj)
            % Retrieves the name of the error file. The default name is phreeqc.id.err.
            % Parameters
            %     id	The instance id returned from CreateIPhreeqc.
            % Returns
            %     filename The name of the error file.
            % See also
            %     GetErrorFileOn, GetErrorString, GetErrorStringOn, GetErrorStringLine, GetErrorStringLineCount, SetErrorFileName, SetErrorFileOn, SetErrorStringOn
            file_name = calllib('libiphreeqc','GetErrorFileName', obj.id);
        end
        function status = GetErrorFileOn(obj)
            % Retrieves the current value of the error file switch.
            % Parameters
            %   id	The instance id returned from CreateIPhreeqc.
            % Returns
            %   Non-zero if errors are written to the phreeqc.id.err file, 0 (zero) otherwise.
            % See also
            %   SetErrorFileOn
            status = calllib('libiphreeqc','GetErrorFileOn', obj.id);
        end
        
        function error_string = GetErrorString(obj)
            % Retrieves the error messages from the last call to RunAccumulated, RunFile, RunString, LoadDatabase, or LoadDatabaseString.
            % Parameters
            % id	The instance id returned from CreateIPhreeqc.
            % Returns
            % A null terminated string containing error messages.
            % See also
            % GetErrorFileOn, GetErrorStringLine, GetErrorStringLineCount, OutputErrorString, SetErrorFileOn
            error_string = calllib('libiphreeqc','GetErrorString', obj.id);
        end
                
        function error_line = GetErrorStringLine(obj, n)
            % Retrieves the given error line.
            % Parameters
            % id	The instance id returned from CreateIPhreeqc.
            % n	The zero-based index of the line to retrieve.
            % Returns
            % A null terminated string containing the given line of the error string buffer.
            % See also
            % GetErrorFileOn, GetErrorString, GetErrorStringLineCount, OutputErrorString, SetErrorFileOn
            error_line = calllib('libiphreeqc','GetErrorStringLine', obj.id, n);
        end
        
        function n_line = GetErrorStringLineCount(obj)
            % Retrieves the number of lines in the current error string buffer.
            % Parameters
            % id	The instance id returned from CreateIPhreeqc.
            % Returns
            % The number of lines.
            % See also
            % GetErrorFileOn, GetErrorString, GetErrorStringLine, OutputErrorString, SetErrorFileOn
            n_line = calllib('libiphreeqc','GetErrorStringLineCount', obj.id);
        end

        function status = GetErrorStringOn(obj)
            % Retrieves the current value of the error string switch.

            % Parameters
            % id	The instance id returned from CreateIPhreeqc.
            % Returns
            % Non-zero if output is stored, 0 (zero) otherwise.
            % See also
            % GetErrorFileOn, GetErrorString, GetErrorStringLine, GetErrorStringLineCount, SetErrorFileOn, SetErrorStringOn
            status = calllib('libiphreeqc','GetErrorStringOn', obj.id);
        end
        
        function file_name = GetLogFileName(obj)
            % Retrieves the name of the log file. The default name is phreeqc.id.log.
            % Parameters
            % id	The instance id returned from CreateIPhreeqc.
            % Returns
            % filename The name of the log file.
            % See also
            % GetLogFileOn, GetLogString, GetLogStringOn, GetLogStringLine, GetLogStringLineCount, SetLogFileName, SetLogFileOn, SetLogStringOn
            file_name = calllib('libiphreeqc','GetLogFileName', obj.id);
        end
        
        function status = GetLogFileOn(obj)
            % Retrieves the current value of the log file switch.
            % Parameters
            % id	The instance id returned from CreateIPhreeqc.
            % Returns
            % Non-zero if log messages are written to the phreeqc.id.log file, 0 (zero) otherwise.
            % Remarks
            % Logging must be enabled through the use of the KNOBS -logfile option in order to receive any log messages.
            % See also
            % SetLogFileOn
            status = calllib('libiphreeqc','GetLogFileOn', obj.id);
        end
        
        function log_output = GetLogString(obj)
            % Retrieves the string buffer containing log output.
            % Parameters
            % id	The instance id returned from CreateIPhreeqc.
            % Returns
            % A null terminated string containing log output.
            % Remarks
            % Logging must be enabled through the use of the KNOBS -logfile option in order to receive any log messages.
            % Precondition
            % SetLogStringOn must have been set to true (non-zero) in order to receive log output.
            % See also
            % GetLogFileOn, GetLogStringLine, GetLogStringLineCount, SetLogFileOn, GetLogStringOn, SetLogStringOn
            log_output = calllib('libiphreeqc','GetLogString', obj.id);
        end

        function log_line = GetLogStringLine(obj, n)
            % Retrieves the given log line.
            % Parameters
            % id	The instance id returned from CreateIPhreeqc.
            % n	The zero-based index of the line to retrieve.
            % Returns
            % A null terminated string containing the given line. Returns an empty string if n is out of range.
            % Precondition
            % SetLogStringOn must have been set to true (non-zero).
            % See also
            % GetLogFileOn, GetLogString, GetLogStringLineCount, GetLogStringOn, SetLogFileOn, SetLogStringOn
            log_line = calllib('libiphreeqc','GetLogStringLine', obj.id, n);
        end
                
        function n_line = GetLogStringLineCount(obj)
            % Retrieves the number of lines in the current log string buffer.
            % Parameters
            % id	The instance id returned from CreateIPhreeqc.
            % Returns
            % The number of lines.
            % Precondition
            % SetLogStringOn must have been set to true (non-zero).
            % See also
            % GetLogFileOn, GetLogString, GetLogStringLine, GetLogStringOn, SetLogFileOn, SetLogStringOn
            n_line = calllib('libiphreeqc','GetLogStringLineCount', obj.id);
        end
        
        function status = GetLogStringOn(obj)
            % Retrieves the current value of the log string switch.
            % Parameters
            % id	The instance id returned from CreateIPhreeqc.
            % Returns
            % Non-zero if output is stored, 0 (zero) otherwise.
            % See also
            % GetLogFileOn, GetLogString, GetLogStringLine, GetLogStringLineCount, SetLogFileOn, SetLogStringOn
            status = calllib('libiphreeqc','GetLogStringOn', obj.id);
        end
        
        function n_user_number = GetNthSelectedOutputUserNumber(obj, n)
            % Retrieves the nth user number of the currently defined SELECTED_OUTPUT keyword blocks.

            % Parameters
            % id	The instance id returned from CreateIPhreeqc.
            % n	The zero-based index of the SELECTED_OUTPUT user number to retrieve.
            % Returns
            % The nth defined user number; a negative value indicates an error occured.
            % See also
            % GetCurrentSelectedOutputUserNumber, GetSelectedOutputCount, SetCurrentSelectedOutputUserNumber
            % Precondition
            % RunAccumulated, RunFile, RunString must have been called and returned 0 (zero) errors.
            n_user_number = calllib('libiphreeqc','GetNthSelectedOutputUserNumber', obj.id, n);
        end

        function file_name = GetOutputFileName(obj)
                % Retrieves the name of the output file. The default name is phreeqc.id.out.
                % Parameters
                % id	The instance id returned from CreateIPhreeqc.
                % Returns
                % filename The name of the output file.
                % See also
                % GetOutputFileOn, GetOutputString, GetOutputStringOn, GetOutputStringLine, GetOutputStringLineCount, SetOutputFileName, SetOutputFileOn, SetOutputStringOn
                file_name = calllib('libiphreeqc','GetOutputFileName', obj.id);
        end
        
        function status = GetOutputFileOn(obj)
            % Retrieves the current value of the output file switch.

            % Parameters
            % id	The instance id returned from CreateIPhreeqc.
            % Returns
            % Non-zero if output is written to the phreeqc.id.out file, 0 (zero) otherwise.
            % See also
            % SetOutputFileOn
            status = calllib('libiphreeqc','GetOutputFileOn', obj.id);
        end
        
        function phreeqc_output = GetOutputString(obj)
            % Retrieves the string buffer containing phreeqc output.
            % Parameters
            % id	The instance id returned from CreateIPhreeqc.
            % Returns
            % A null terminated string containing phreeqc output.
            % Precondition
            % SetOutputStringOn must have been set to true (non-zero) in order to receive phreeqc output.
            % See also
            % GetOutputFileOn, GetOutputStringLine, GetOutputStringLineCount, SetOutputFileOn, GetOutputStringOn, SetOutputStringOn
            phreeqc_output = calllib('libiphreeqc','GetOutputString', obj.id);
        end
        
        function output_line = GetOutputStringLine(obj, n)
            % Retrieves the given output line.
            % Parameters
            % id	The instance id returned from CreateIPhreeqc.
            % n	The zero-based index of the line to retrieve.
            % Returns
            % A null terminated string containing the given line. Returns an empty string if n is out of range.
            % Precondition
            % SetOutputStringOn must have been set to true (non-zero).
            % See also
            % GetOutputFileOn, GetOutputString, GetOutputStringLineCount, GetOutputStringOn, SetOutputFileOn, SetOutputStringOn
            output_line = calllib('libiphreeqc','GetOutputStringLine', obj.id, n);
        end
        
        function n_line = GetOutputStringLineCount(obj)
            % Retrieves the number of lines in the current output string buffer.
            % Parameters
            % id	The instance id returned from CreateIPhreeqc.
            % Returns
            % The number of lines.
            % Precondition
            % SetOutputStringOn must have been set to true (non-zero).
            % See also
            % GetOutputFileOn, GetOutputString, GetOutputStringLine, GetOutputStringOn, SetOutputFileOn, SetOutputStringOn
            n_line = calllib('libiphreeqc','GetOutputStringLineCount', obj.id);
        end
        
        function status = GetOutputStringOn(obj)
            % Retrieves the current value of the output string switch.
            % Parameters
            % id	The instance id returned from CreateIPhreeqc.
            % Returns
            % Non-zero if output is stored, 0 (zero) otherwise.
            % See also
            % GetOutputFileOn, GetOutputString, GetOutputStringLine, GetOutputStringLineCount, SetOutputFileOn, SetOutputStringOn
            status = calllib('libiphreeqc','GetOutputStringOn', obj.id);
        end
        
        function n_column = GetSelectedOutputColumnCount(obj)
            % Retrieves the number of columns in the selected-output buffer.
            % Parameters
            % id	The instance id returned from CreateIPhreeqc.
            % Returns
            % The number of columns.
            % See also
            % GetSelectedOutputFileOn, GetSelectedOutputRowCount, GetSelectedOutputValue, SetSelectedOutputFileOn
            n_column = calllib('libiphreeqc','GetSelectedOutputColumnCount', obj.id);
        end

        function n_selected_out = GetSelectedOutputCount(obj)
            % Retrieves the count of SELECTED_OUTPUT blocks that are currently defined.
            % Parameters
            % id	The instance id returned from CreateIPhreeqc.
            % Returns
            % The number of SELECTED_OUTPUT blocks.
            % See also
            % GetCurrentSelectedOutputUserNumber, GetNthSelectedOutputUserNumber, SetCurrentSelectedOutputUserNumber
            % Precondition
            % (RunAccumulated, RunFile, RunString) must have been called and returned 0 (zero) errors.
            n_selected_out = calllib('libiphreeqc','GetSelectedOutputCount', obj.id);
        end
        
        function file_name = GetSelectedOutputFileName(obj)
            % Retrieves the name of the current selected output file (see SetCurrentSelectedOutputUserNumber). This file name is used if not specified within SELECTED_OUTPUT input. The default value is selected_n.id.out.

            % Parameters
            % id	The instance id returned from CreateIPhreeqc.
            % Returns
            % filename The name of the file to write SELECTED_OUTPUT output to.
            % See also
            % GetSelectedOutputFileOn, GetSelectedOutputString, GetSelectedOutputStringOn, GetSelectedOutputStringLine, GetSelectedOutputStringLineCount, SetCurrentSelectedOutputUserNumber, SetSelectedOutputFileName, SetSelectedOutputFileOn, SetSelectedOutputStringOn
            file_name = calllib('libiphreeqc','GetSelectedOutputFileName', obj.id);
        end
        
        function status = GetSelectedOutputFileOn(obj)
            % Retrieves the current selected-output file switch (see SetCurrentSelectedOutputUserNumber).
            % Parameters
            % id	The instance id returned from CreateIPhreeqc.
            % Returns
            % Non-zero if output is written to the selected-output (selected_n.id.out if unspecified) file, 0 (zero) otherwise.
            % See also
            % GetSelectedOutputColumnCount, GetSelectedOutputRowCount, GetSelectedOutputValue, SetCurrentSelectedOutputUserNumber, SetSelectedOutputFileOn
            status = calllib('libiphreeqc','GetSelectedOutputFileOn', obj.id);
        end
        
        function n_rows = GetSelectedOutputRowCount(obj)
            % Retrieves the number of rows in the current selected-output buffer (see SetCurrentSelectedOutputUserNumber).

            % Parameters
            % id	The instance id returned from CreateIPhreeqc.
            % Returns
            % The number of rows.
            % See also
            % GetSelectedOutputFileOn, GetSelectedOutputColumnCount, GetSelectedOutputValue, SetCurrentSelectedOutputUserNumber, SetSelectedOutputFileOn
            n_rows = calllib('libiphreeqc','GetSelectedOutputRowCount', obj.id);
        end
        
        function sel_out_string = GetSelectedOutputString(obj)
            % Retrieves the string buffer containing the current SELECTED_OUTPUT (see SetCurrentSelectedOutputUserNumber).
            % Parameters
            % id	The instance id returned from CreateIPhreeqc.
            % Returns
            % A null terminated string containing SELECTED_OUTPUT.
            % Precondition
            % SetSelectedOutputStringOn must have been set to true (non-zero) in order to receive SELECTED_OUTPUT.
            % See also
            % GetSelectedOutputFileOn, GetSelectedOutputStringLine, GetSelectedOutputStringLineCount, GetSelectedOutputStringOn, SetSelectedOutputFileOn, SetCurrentSelectedOutputUserNumber SetSelectedOutputStringOn
            sel_out_string = calllib('libiphreeqc','GetSelectedOutputString', obj.id);
        end
        
        function output_line = GetSelectedOutputStringLine(obj, n)
            % Retrieves the given line of the current selected output string (see SetCurrentSelectedOutputUserNumber).
            % Parameters
            % id	The instance id returned from CreateIPhreeqc.
            % n	The zero-based index of the line to retrieve.
            % Returns
            % A null terminated string containing the given line. Returns an empty string if n is out of range.
            % Precondition
            % SetSelectedOutputStringOn must have been set to true (non-zero).
            % See also
            % GetSelectedOutputFileOn, GetSelectedOutputString, GetSelectedOutputStringLineCount, GetSelectedOutputStringOn, SetCurrentSelectedOutputUserNumber, SetSelectedOutputFileOn, SetSelectedOutputStringOn
            output_line = calllib('libiphreeqc','GetSelectedOutputStringLine', obj.id, n);
        end
        
        function n_lines = GetSelectedOutputStringLineCount(obj)
            % Retrieves the number of lines in the current selected output string buffer (see SetCurrentSelectedOutputUserNumber).
            % Parameters
            % id	The instance id returned from CreateIPhreeqc.
            % Returns
            % The number of lines.
            % Precondition
            % SetSelectedOutputStringOn must have been set to true (non-zero).
            % See also
            % GetSelectedOutputFileOn, GetSelectedOutputString, GetSelectedOutputStringLine, GetSelectedOutputStringOn, SetCurrentSelectedOutputUserNumber, SetSelectedOutputFileOn, SetSelectedOutputStringOn
            n_lines = calllib('libiphreeqc','GetSelectedOutputStringLineCount', obj.id);
        end


        function status = GetSelectedOutputStringOn(obj)  
            % Retrieves the value of the current selected output string switch (see SetCurrentSelectedOutputUserNumber).

            % Parameters
            % id	The instance id returned from CreateIPhreeqc.
            % Returns
            % Non-zero if output defined by the SELECTED_OUTPUT keyword is stored, 0 (zero) otherwise.
            % See also
            % GetSelectedOutputFileOn, GetSelectedOutputString, GetSelectedOutputStringLine, GetSelectedOutputStringLineCount, SetCurrentSelectedOutputUserNumber, SetSelectedOutputFileOn, SetSelectedOutputStringOn
            status = calllib('libiphreeqc','GetSelectedOutputStringOn', obj.id);
        end
        
        function [status, output_value] = GetSelectedOutputValue(obj, row, col, pvar)
            % Returns the VAR associated with the specified row and column. The current SELECTED_OUTPUT block is set using the SetCurrentSelectedOutputUserNumber method.
            % Parameters
            % id	The instance id returned from CreateIPhreeqc.
            % row	The row index.
            % col	The column index.
            % pVAR	Pointer to the VAR to receive the requested data.
            % Return values
            % IPQ_OK	Success.
            % IPQ_INVALIDROW	The given row is out of range.
            % IPQ_INVALIDCOL	The given column is out of range.
            % IPQ_OUTOFMEMORY	Memory could not be allocated.
            % IPQ_BADINSTANCE	The given id is invalid.
            % See also
            % GetCurrentSelectedOutputUserNumber, GetSelectedOutputFileOn, GetSelectedOutputColumnCount, GetSelectedOutputRowCount, GetSelectedOutputValue2, SetCurrentSelectedOutputUserNumber, SetSelectedOutputFileOn
            % Remarks
            % Row 0 contains the column headings to the selected_ouput.

            % needs to be tested???
            [status, output_value] = calllib('libiphreeqc','GetSelectedOutputValue', obj.id, row, col, pvar);
        end
        
        function [status, output_type, dval, sval, s_length] = GetSelectedOutputValue2(obj, row, col, vtype, dvalue, svalue, svalue_length)
            % Returns the associated data with the specified row and column. The current SELECTED_OUTPUT block is set using the SetCurrentSelectedOutputUserNumber method.

            % Parameters
            % id	The instance id returned from CreateIPhreeqc.
            % row	The row index.
            % col	The column index.
            % vtype	Receives the variable type. See VAR_TYPE.
            % dvalue	Receives the numeric value when (VTYPE=TT_DOUBLE) or (VTYPE=TT_LONG).
            % svalue	Receives the string variable when (VTYPE=TT_STRING). When (VTYPE=TT_DOUBLE) or (VTYPE=TT_LONG) this variable is filled with a string equivalent of DVALUE.
            % svalue_length	The length of the svalue buffer.
            % Return values
            % IPQ_OK	Success.
            % IPQ_INVALIDROW	The given row is out of range.
            % IPQ_INVALIDCOL	The given column is out of range.
            % IPQ_OUTOFMEMORY	Memory could not be allocated.
            % IPQ_BADINSTANCE	The given id is invalid.
            % See also
            % GetCurrentSelectedOutputUserNumber, GetSelectedOutputFileOn, GetSelectedOutputColumnCount, GetSelectedOutputRowCount, GetSelectedOutputValue, SetCurrentSelectedOutputUserNumber, SetSelectedOutputFileOn
            % Remarks
            % Row 0 contains the column headings to the selected_ouput.

            % Needs further tests
            [status, output_type, dval, sval, s_length] = calllib('libiphreeqc','GetSelectedOutputValue2', obj.id, row, col, vtype, dvalue, svalue, svalue_length);
        end
        
        function version_string = GetVersionString(obj)
            % Retrieves the string buffer containing the version in the form of X.X.X-XXXX.

            % Returns
            % A null terminated string containing the IPhreeqc version number.
            version_string = calllib('libiphreeqc','GetVersionString');
        end
        
        % function status = (obj, )
        %     % 
        %     status = calllib('libiphreeqc','', obj.id, );
        % end
        
        % function status = (obj, )
        %     % 
        %     status = calllib('libiphreeqc','', obj.id, );
        % end
        
        % function status = (obj, )
        %     % 
        %     status = calllib('libiphreeqc','', obj.id, );
        % end

        % function status = (obj, )
        %     % 
        %     status = calllib('libiphreeqc','', obj.id, );
        % end
        
        %         function status = (obj, )
        %             % 
        %             status = calllib('libiphreeqc','', obj.id, );
        %         end
        %         
        %         function status = (obj, )
        %             % 
        %             status = calllib('libiphreeqc','', obj.id, );
        %         end
        %         
        %         function status = (obj, )
        %             % 
        %             status = calllib('libiphreeqc','', obj.id, );
        %         end
                %         function status = (obj, )
        %             % 
        %             status = calllib('libiphreeqc','', obj.id, );
        %         end
        %         
        %         function status = (obj, )
        %             % 
        %             status = calllib('libiphreeqc','', obj.id, );
        %         end
        %         
        %         function status = (obj, )
        %             % 
        %             status = calllib('libiphreeqc','', obj.id, );
        %         end
                %         function status = (obj, )
        %             % 
        %             status = calllib('libiphreeqc','', obj.id, );
        %         end
        %         
        %         function status = (obj, )
        %             % 
        %             status = calllib('libiphreeqc','', obj.id, );
        %         end
        %         
        %         function status = (obj, )
        %             % 
        %             status = calllib('libiphreeqc','', obj.id, );
        %         end
                %         function status = (obj, )
        %             % 
        %             status = calllib('libiphreeqc','', obj.id, );
        %         end
        %         
        %         function status = (obj, )
        %             % 
        %             status = calllib('libiphreeqc','', obj.id, );
        %         end
        %         
        %         function status = (obj, )
        %             % 
        %             status = calllib('libiphreeqc','', obj.id, );
        %         end
                %         function status = (obj, )
        %             % 
        %             status = calllib('libiphreeqc','', obj.id, );
        %         end
        %         
        %         function status = (obj, )
        %             % 
        %             status = calllib('libiphreeqc','', obj.id, );
        %         end
        %         
        %         function status = (obj, )
        %             % 
        %             status = calllib('libiphreeqc','', obj.id, );
        %         end
                %         function status = (obj, )
        %             % 
        %             status = calllib('libiphreeqc','', obj.id, );
        %         end
        %         
        %         function status = (obj, )
        %             % 
        %             status = calllib('libiphreeqc','', obj.id, );
        %         end
        %         
        %         function status = (obj, )
        %             % 
        %             status = calllib('libiphreeqc','', obj.id, );
        %         end
    end
end

