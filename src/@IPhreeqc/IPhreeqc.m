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
        
        function status = AddWarning(obj, warn_msg)
            % AddWarning Appends the given warning message and increments the warning count. Internally used to create a warning condition. 
            status = calllib('libiphreeqc','AddWarning', obj.id, warn_msg);
        end
        
        function status = ClearAccumulatedLines(obj)
            % ClearAccumulatedLines Clears the accumulated input buffer. Input buffer is accumulated from calls to AccumulateLine. 
            status = calllib('libiphreeqc','ClearAccumulatedLines', obj.id);
        end
        
%         function status =  (obj, )
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

