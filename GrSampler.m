classdef GrSampler < handle
    properties
        min_trial_count = 1
        max_trial_count = 1e4
        max_num_retries = 100;
        
        confidence = 0.99
        
        N,p
        labeling0

        freq = []
        Z = []
    end
    
    methods
        function this = GrSampler(dr,corresp,k,varargin)
            [this,~] = cmp_argparse(this,varargin{:});

            this.labeling0 = [dr(:).Gapp];
            
            this.freq = hist(this.labeling0,1:max(this.labeling0));
            this.Z = arrayfun(@(x) nchoosek(x,2),this.freq);
            this.p = this.Z/sum(this.Z);
            this.N = sum(this.Z);
            
            assert(this.N == size(corresp,2), ...
                   'Number of total correspondences is incorrect');
        end

        function ind = sample(this,dr,k,varargin)
            while true
                ind = reshape(randsample(this.N,2),1,[]);
                if numel(unique(ind)) == 2
                    break
                end
            end
%            while true
%                t = mnrnd(2,this.p,1);
%                indt = find(t);
%                c = repelem(indt,t(indt));
%                idx1 = find(this.labeling == c(1));
%                idx2 = find(this.labeling == c(2));
%                idx = [idx1(randperm(numel(idx1),k)) ...
%                       idx2(randperm(numel(idx2),k)) ];
%                
%                if numel(unique(idx)) == 4
%                    break
%                end
%            end
        end
        
        function trial_count = update_trial_count(this,corresp,cs)
            trial_count = inf;
            cslabeling = this.labeling0.*cs;
            cslabeling(find(cslabeling==0)) = nan;
            cs_freq = hist(cslabeling,1:max(this.labeling0));
            ind = cs_freq > 0;
            p2 = hygepdf(2,this.freq(ind),cs_freq(ind),2);
            p3 = dot(this.p(ind),p2);
            
            N = ceil(log(1-this.confidence)/log(1-p3*p3));
            ub = min([N this.max_trial_count]);
            trial_count = max([ub this.min_trial_count]);
        end

    end
end
