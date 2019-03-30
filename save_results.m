function [] = save_results(img_path,dt,model_list, ...
                           res_list,stats_list,meas,img) 
    results_path = fullfile('results', dt);
    if ~exist(results_path, 'dir')
        mkdir(results_path);
    end
    [~,img_name] = fileparts(img_path);
    mat_file_path = fullfile(results_path,[img_name '.mat']);
    save(mat_file_path, ...
         'model_list', 'res_list','stats_list','meas','img');

    [uimg,rimg] = render_images(img.data,meas,model_list(1),res_list(1));
    ud_file_path = fullfile(results_path,[img_name '_ud.jpg']);
    imwrite(uimg,ud_file_path);
    rect_file_path = fullfile(results_path,[img_name '_rect.jpg']);
    imwrite(rimg,rect_file_path);
