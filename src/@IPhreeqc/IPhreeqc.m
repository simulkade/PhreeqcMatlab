classdef IPhreeqc
    % A wrapper for IPhreeqc package
    
    properties
        id
    end
    
    methods
        function obj = IPhreeqc()
            %UNTITLED Construct an instance of this class
            %
            if ~libisloaded('libiphreeqc')
                loadlibrary('libiphreeqc','IPhreeqc.h');
            end
			id = calllib('libiphreeqc','CreateIPhreeqc');
            obj.id = id;
        end
        
        function AccumulateLine(obj, line_str)
            % AccumulateLine Accumlulate line(s) for input to phreeqc. 
            status = calllib('libiphreeqc','AccumulateLine', obj.id, line_str);
        end
        
        function AddError(obj, error_msg)
            % AddError Appends the given error message and increments the error count. Internally used to create an error condition. 
            status = calllib('libiphreeqc','AddError', obj.id, error_msg);
        end
        
        function AddWarning(obj, warn_msg)
            % AddWarning Appends the given warning message and increments the warning count. Internally used to create a warning condition. 
            status = calllib('libiphreeqc','AddWarning', obj.id, warn_msg);
        end
        
        function ClearAccumulatedLines(obj)
            % ClearAccumulatedLines Clears the accumulated input buffer. Input buffer is accumulated from calls to AccumulateLine. 
            status = calllib('libiphreeqc','ClearAccumulatedLines', obj.id);
        end
        
%         function (obj, )
%             % 
%             status = calllib('libiphreeqc','', obj.id, );
%         end
%         
%         function (obj, )
%             % 
%             status = calllib('libiphreeqc','', obj.id, );
%         end
%         
%         function (obj, )
%             % 
%             status = calllib('libiphreeqc','', obj.id, );
%         end
%         
%         function (obj, )
%             % 
%             status = calllib('libiphreeqc','', obj.id, );
%         end
%         
%         function (obj, )
%             % 
%             status = calllib('libiphreeqc','', obj.id, );
%         end
%         
%         function (obj, )
%             % 
%             status = calllib('libiphreeqc','', obj.id, );
%         end
%         
%         function (obj, )
%             % 
%             status = calllib('libiphreeqc','', obj.id, );
%         end
    end
end

