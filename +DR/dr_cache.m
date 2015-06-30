classdef dr_cache < handle
    properties
        image_cache
    end

    methods(Access = private)
        function key_list = add_cfg_list(this,cfg_list)
            if ~isempty(cfg_list)
                for k = 1:numel(cfg_list)
                    for k1 = 1:numel(cfg_list{k})
                        parents = '';
                        for i = 1:k1-1
                            parents = [parents class(cfg_list{k}{i}) ':'];
                        end
                        name = [parents class(cfg_list{k}{k1})];
                        parents = parents(1:end-1);
                        if isempty(parents)
                            this.image_cache.add_dependency(name, ...
                                                            cfg_list{k}{k1});
                        else
                            this.image_cache.add_dependency(name, ...
                                                            cfg_list{k}{k1}, ...
                                                            'parents',parents);
                        end
                    end
                    key_list{k} = name;
                end
            end
        end

        function [res,is_found] = get(this,cfg_list)
            is_found = false(1,numel(cfg_list));
            res = cell(1,numel(cfg_list));
            
            for k = 1:numel(cfg_list)
                [res{k},is_found(k)] = ...
                    this.image_cache.get('dr',cfg_list(k).name);
            end
        end
            
        function [res,is_found] = put(this,cfg_list,res)
            for k = 1:numel(cfg_list)
                this.image_cache.put('dr',cfg_list(k).name,res{k});
            end
        end
    end
        
    methods 
        function this = dr_cache(image_cache)
            this.image_cache = image_cache;
        end

        function [feat,upg,desc,key_list] = extract(this,cfg_list,img)
            key_list = this.add_cfg_list(cfg_list);
            
            [feat,is_found] = this.get(cfg_list);
            putit = ~is_found;
            if any(putit)
                feat(putit) = DR.extract(cfg_list(putit),img);
                this.put(cfg_list(putit),feat(putit));
            end
        end

        function [upg,key_list] = upgrade(this,upg_cfg_list,feat,img)
            key_list = this.add_cfg_list(upg_cfg_list);
            [upg,is_found] = this.get(upg_cfg_list);
            putit = ~is_found;
            doit = putit & cellfun(@(x) ~isempty(x),feat);
            if any(doit)
                upg(doit) = ...
                    DR.upgrade(upg_cfg_list(doit), ...
                               img,feat(doit));
                this.put(upg_cfg_list(putit), ...
                         upg(putit));
            end
        end

        function [desc,key_list] = describe(this,desc_cfg_list,upg,img)
            key_list = this.add_cfg_list(desc_cfg_list);
            [desc,is_found] = this.get(desc_cfg_list);
            putit = ~is_found;
            doit = putit & cellfun(@(x) ~isempty(x),upg);
            if any(doit)
                desc(doit) = ...
                    DR.describe(desc_cfg_list(doit), ...
                                img, upg(doit));
                this.put(desc_cfg_list(putit),desc(putit));
            end
        end
    end
end