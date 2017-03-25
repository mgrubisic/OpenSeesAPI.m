classdef cyclic3 < OpenSees
   
    properties
        
        format = ' %0.9f';
        
        ctrlNode    % control node
        ctrldof     % control dof
        targetDisp  % array of displacement targets
        targetIncr  % target displacement increment (absolute)
        tol         % convergence tolerance
        maxIter     % maximum number of iterations for convergence
                
    end
    
    methods
        
        function obj = cyclic3(ctrlNode,ctrldof,targetDisp,targetIncr,tol,maxIter)
           
            % store variables
            obj.ctrlNode = ctrlNode;
            obj.ctrldof = ctrldof;
            obj.targetDisp = targetDisp;
            obj.targetIncr = targetIncr;
            obj.tol = tol;
            obj.maxIter = maxIter;
                    
            % setup system
%             constraints = OpenSees.analysis.constraints.Plain;
            numberer = OpenSees.analysis.numberer.RCM;
%             system = OpenSees.analysis.system.BandGeneral;
            test = OpenSees.analysis.test.NormDispIncr(obj.tol,obj.maxIter);
%             algorithm = OpenSees.analysis.algorithm.KyrlovNewton;
%             analysis = OpenSees.analysis.analysisType.Static;
            obj.cmdLine = ['constraints Plain;\n' ...
                           numberer.cmdLine ';\n' ...
                           'system Mumps;\n' ...
                           test.cmdLine ';\n'];
                       
            % find displacements relative to targets
%             relDisp = obj.targetDisp(1);
%             for ii = 2:length(obj.targetDisp)
%                 relDisp(ii) = obj.targetDisp(ii) - obj.targetDisp(ii-1);
%             end
                       
            % analysis convergence loop
            obj.cmdLine = [obj.cmdLine '\n' ...
                           'set ctrlNode ' num2str(obj.ctrlNode.tag) ';\n' ...
                           'set ctrlDOF ' num2str(obj.ctrldof) ';\n' ...
                           'set targIncr ' num2str(obj.targetIncr) ';\n' ...
                           'foreach targDisp {' num2str(obj.targetDisp) '} {\n' ...
                           '\t'     'set ctrlDisp [nodeDisp $ctrlNode $ctrlDOF];\n' ...
                           '\t'     'set travel 0.0;\n' ...
                           '\t'     'set relDisp [expr $targDisp - $ctrlDisp];\n' ...
                           '\t'     'if {$relDisp > 0} {\n' ...
                           '\t\t'       'set sgn 1.0;\n' ...
                           '\t'     '} else {\n' ...
                           '\t\t'       'set sgn -1.0;\n' ...
                           '\t'     '};\n' ...
                           '\t'     'set incr [expr $sgn*$targIncr];\n' ...
                           '\t'     'puts "\n> excursion: $targDisp | increment: $incr\n";\n' ...
                           '\t'     'while {[expr abs($travel)] < [expr abs($relDisp)]} {\n' ...
                           '\t\t'       'algorithm KrylovNewton;\n' ...
                           '\t\t'       'integrator DisplacementControl $ctrlNode $ctrlDOF $incr;\n' ...
                           '\t\t'       'analysis Static;\n' ...
                           '\t\t'       'set ok [analyze 1];\n' ...
                           '\t\t'       'if {$ok == 0} {\n' ...
                           '\t\t\t'         'set travel [expr $travel + $incr];\n' ...
                           '\t\t'       '} elseif {$ok != 0} {\n' ...
                           '\t\t\t'         'set prntDisp [expr int([nodeDisp $ctrlNode $ctrlDOF]*100.0)/100.0];\n' ...
                           '\t\t\t'         'puts "\t> at $prntDisp";\n' ...
                           '\t\t\t'         'set tempIncr $incr;\n' ...
                           '\t\t\t'         'set denom 2.0;\n' ...
                           '\t\t\t'         'set counter 0;\n' ...
                           '\t\t\t'         'while {$ok != 0} {\n' ...
                           '\t\t\t\t'           'set counter [expr $counter + 1];\n' ...
                           '\t\t\t\t'           'if {$counter > 4} {\n' ...
                           '\t\t\t\t\t'             'integrator ArcLength 0.01 0.1;\n'...
                           '\t\t\t\t'           '};\n' ...
                           '\t\t\t\t'           'set tempIncr [expr $tempIncr/$denom];\n' ...
                           '\t\t\t\t'           'puts "\t\t> trying increment: $tempIncr";\n' ...
                           '\t\t\t\t'           'integrator DisplacementControl $ctrlNode $ctrlDOF $tempIncr;\n' ...
                           '\t\t\t\t'           'set ok [analyze 1];\n' ...
                           '\t\t\t'         '};\n' ...
                           '\t\t\t'         'set travel [expr $travel + $tempIncr];\n' ...
                           '\t\t'       '};\n' ...
                           '\t'     '};\n' ...
                           '}'];
                       
        end
        
    end
    
end