function tf = stageDone(S, stage)
%STAGEDONE True if the pipeline stage has been run on state S.
tf = ~isempty(S) && isfield(S, 'done') && isfield(S.done, stage);
end
