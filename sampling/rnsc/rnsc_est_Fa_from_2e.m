function varargout = rnsc_est_Fa_from_2e(u,s,threshold,lo_threshold,confidence)
cfg.k = 2;
cfg.tsq = 3.84*threshold^2;
cfg.confidence = confidence;
cfg.max_trials = 1e5;
cfg.v = [u(4:6,:);u(13:15,:)];

%cfg.sample_degen_fn = @eg_sample_degen;
%cfg.sample_degen_args = { cfg.tsq, cfg.k };

% model functions
cfg.est_fn = @eg_est_Fa_from_2e;
cfg.error_fn = @(u,s,sample,F,cfg) sum(eg_sampson_err(cfg.v,s,sample,F,cfg).^2);

cfg = rnsc_standardize_cfg(cfg);

cfg.lo = make_lo_rnsc_cfg(cfg);
cfg.lo.tsq = 3.84*lo_threshold^2;

res = rnsc_estimate(u,s,cfg);

varargout = { res };

if nargout == 2
    varargout = cat(2,varargout,cfg);
end

function cfg = make_lo_rnsc_cfg(cfg) 
cfg.fn = @rnsc_lo_est_F_bmvc12;

function res = rnsc_lo_est_F_bmvc12(u,s,sample,weights,F0,cfg)
ind = int32(find(weights));
res = [];
if numel(ind) > 7
    [opt_Ft,opt_weights] = innerloF(cfg.v,cfg.tsq,ind);
    opt_F = opt_Ft';

    res.model0 = F0;
    res.model = opt_F;
    res.weights = logical(opt_weights);
    res.score = sum(res.weights);
    res.from_lo = true;
end