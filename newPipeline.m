function S = newPipeline(cfg)
%NEWPIPELINE Empty pipeline state for a configuration.
S = struct('cfg', cfg, 'done', struct(), 'log', {{}});
end
