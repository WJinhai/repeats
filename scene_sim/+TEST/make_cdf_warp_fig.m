function [] = make_cdf_warp_fig(src_path,target_path,colormap,color_list)
repeats_init();
axis_options = {'enlargelimits=false'};  
sensitivity = load(src_path);
data = innerjoin(sensitivity.res,sensitivity.gt, ...
                 'LeftKeys','ex_num','RightKeys','ex_num');
q_gt = unique(data.q_gt)*sum(2*sum(sensitivity.cam.cc))^2;

assert(numel(q_gt)>0,'Cannot have different distortion parameters');
qres = array2table([data.q*sum(2*sum(sensitivity.cam.cc))^2 ...
                    data.ransac_q*sum(2*sum(sensitivity.cam.cc))^2 ...
                    1-data.q./data.q_gt ...
                    1-data.ransac_q./data.q_gt ...
                    data.rewarp ...
                    data.ransac_rewarp ], ...
                   'VariableNames', ...
                   {'q','ransac_q', 'q_relerr', ...
                    'ransac_q_relerr', 'rewarp','ransac_rewarp'}); 

res = [data(:,{'ex_num','scene_num','solver','sigma'}) qres];
solver_list = unique(res.solver,'stable');

Lia = res.sigma == 1;
Lid = ismember(res.solver,setdiff(solver_list,{'$\mH22\lambda$'}));

solver_ind = find(Lid(1:numel(solver_list)));

is_valid = Lia & Lid;

ind = find(is_valid);
for k = 1:numel(solver_ind)
    ind2 = find(ismember(res.solver(ind),solver_list(solver_ind(k))));
    hold on;
    h = cdfplot(res.rewarp(ind(ind2)));
    solver_name = cellstr(solver_list(solver_ind(k)));
    set(h,'color',color_list(colormap(solver_name{:}),:));
    hold off;
end

xlim([0 15]);
xlabel('$\Delta^{\mathrm{warp}}_{\mathrm{RMS}}$ [pixels] at $\sigma=1$ pixel', ...
       'Interpreter','Latex','Color','k'); 
ylabel('$p(x < \Delta^{\mathrm{warp}}_{\mathrm{RMS}})$', ...
       'Interpreter','Latex');
grid off;
title('');
%title('Empirical CDF of RMS warp error');
%legend('a','b','c','d','e','f','Location','northwest');
legend('off');
drawnow;

cleanfigure('targetResolution',100);
matlab2tikz([target_path 'ecdf_warp_1px_ct.tikz'], ...
            'width', '\fwidth', 'extraAxisOptions',axis_options);