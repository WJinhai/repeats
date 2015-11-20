classdef CidCache < handle
    properties(Access=private)
        G;
        cid;
        imagedb;
        vlist;
        map;
        last_add;
        cfg;
    end

    methods(Access=public)
        function this = CidCache(cid,varargin)
            this.imagedb = CASS.CassDb.getObj();
            this.cid = cid;
            this.map = containers.Map;
            this.vlist = cell(1,1000);
            this.G = [];
            last_add = {};
            
            this.cfg.read_cache = true;
            this.cfg.write_cache = true;

            [this.cfg,~] = cmp_argparse(this.cfg,varargin);
            
            if isempty(cid) || isempty(this.imagedb)
                this.cfg.read_cache = false;
                this.cfg.write_cache = false;
            end
        end 
        
        function imagedb = get_imagedb(this)
            imagedb = this.imagedb;
        end

        function xor_key = add_dependency(this,name,key,varargin)
            cfg.parents = {}; 
            
            key = KEY.make(key);

            % key = KEY.make(key,name);
            
            cfg = cmp_argparse(cfg,varargin);
	        
    	    if ~isempty(cfg.parents) && ~iscell(cfg.parents)
                cfg.parents = {cfg.parents};
            end
    	    
            if strcmpi([cfg.parents{:}],'__LAST_ADD__')
                cfg.parents = last_add;
            end

            v = this.add_vertex(name,key,cfg.parents{:});
            xor_key = this.get_xor_key(v);
            last_add = name;
        end

        function key_list = add_chains(this,chains,init_parents)
            if nargin < 3
                init_parents = '';
            end
            key_list = cell(1,numel(chains));
            for k = 1:numel(chains)
                key_list{k} = cell(1,numel(chains{k}));
                parents = init_parents;
                for k1 = 1:numel(chains{k})
                    name = chains{k}{k1}.get_uname();
                    % chains{k}{k1}.metadata = name;
                    if isempty(parents)
                        this.add_dependency(name, ...
                                                 chains{k}{k1});
                    else
                        this.add_dependency(name, ...
                                                 chains{k}{k1}, ...
                                                 'parents',parents);
                    end
                    parents = [name];
                    key_list{k}{k1} = name;
                end
            end
        end
        
        function [res,is_found] = get_chains(this,chains,init_parents,fmake,varargin)
            if nargin < 3
                init_parents = '';
            elseif ~isempty(init_parents)
                init_parents = [init_parents ':'];
            end
            is_found = cell(1,numel(chains));
            res = cell(numel(chains),1);
            
            for k = 1:numel(chains)
                name = init_parents;
                res{k} = cell(1,numel(chains{k}));
                is_found{k} = false(1,numel(chains{k}));
                for k1 = 1:numel(chains{k})
                    name = [name chains{k}{k1}.get_uname() ':'];
                    [res{k}{k1},is_found{k}(k1)] = ...
                        this.get('dr',name(1:end-1));
                end
            end
            
            if any(~[is_found{:}]) && nargin > 3
                res = feval(fmake,chains,varargin{:},res);
                this.put_chains(chains,res,init_parents);
            end
        end
        
        function [res,is_found] = put_chains(this,chains,res,init_parents)
            for k = 1:numel(chains)
                name = init_parents;
                for k1 = 1:numel(chains{k})
                    name = [name chains{k}{k1}.get_uname() ':'];
                    this.put('dr',name(1:end-1),res{k}{k1});
                end
            end
        end
        
        function img = get_img(this)
            img = this.imagedb.get_img(this.cid);
        end

        function [is_put,xor_key] = put(this,table,name,value,varargin)
            cfg.overwrite = false;
            cfg = cmp_argparse(cfg,varargin);

            is_put = false;

            if ~CompressLib.isCompressed(value) && ...
                     CompressLib.byteSize(value)/1024^2 > 30
                value = CompressLib.compress(value);
            end
            
            if this.map.isKey(name)
                item = this.map(name);
                v = item.v;
                xor_key = this.get_xor_key(v);
                
                if this.cfg.write_cache 
                    if ((~this.imagedb.check(table,this.cid,xor_key) | ...
                         cfg.overwrite))
                        this.imagedb.put(table,this.cid, ...
                                         [name ':' xor_key],value);
                        is_put = true;
                    else
                        error('Cannot put');
                    end
                end
            end

        end

        function [val,is_found,xor_key] = get(this,table,name,fmake,varargin)
            val = [];
            xor_key = [];
            is_found = false;
            if this.map.isKey(name)
                item = this.map(name);
                v = item.v;
                xor_key = this.get_xor_key(v);
                if this.cfg.read_cache
                    [val,is_found] = this.imagedb.get(table, ...
                                                      this.cid,[name ':' xor_key]);        
                    if is_found && CompressLib.isCompressed(val)
                        val = CompressLib.decompress(val);
                    end
                end    
            end
            if ~is_found && nargin > 3
                val = feval(fmake,varargin{:});
                this.put(table,name,val);
                is_found = true;
            end
        end
    end

    methods(Access=private) 
        function res = get_key(this,name)
            item = this.map(name);
            res = item.key;
        end

        function res = get_xor_key(this,v)
            [key_list, name_list] = this.get_parent_tree(v);
            if numel(key_list) > 1
                res = KEY.xor(key_list{:});
            else
                res = key_list{1};
            end
            if numel(name_list) > 1
                uid = strjoin(name_list,':');
                res = KEY.xor(res,KEY.hash(uid,'MD5'));
            end
        end
        
        function v = add_vertex(this,name,key,varargin)
            [ii,jj] = find(this.G);
            this.G = sparse(ii,jj,ones(1,numel(jj)), ...
                           num_vertices(this.G)+1, ...
                           num_vertices(this.G)+1); 
            if num_vertices(this.G) > 1            
                for pa = varargin
                    item = this.map(pa{:});
                    this.G(num_vertices(this.G),item.v) = 1;
                end
            end
            v = num_vertices(this.G);
            item = struct('v',v, ...
                          'key',key, ...
                          'name',name);
            uid = name;
            this.map(uid) = item;
            this.vlist{v} = uid;

            [~,name_list] = this.get_parent_tree(v);
            if numel(name_list) > 1
                uid = strjoin(name_list,':');
                
                item.key = KEY.xor(item.key,KEY.hash(uid,'MD5'));
                this.map(uid) = item;
                this.vlist{v} = uid;
            end
        end

        function [key_list, name_list] = get_parent_tree(this,v)
            [~,dt] = bfs(this.G,v);
            tmp = v;
            ia = v;
            [val,order] = sort(dt);
            order = order(val > 0);
            key_list = cellfun(@(x) x.key, ...
                               values(this.map,this.vlist(order)), ...
                               'UniformOutput',false);
            name_list = cellfun(@(x) x.name, ...
                   values(this.map,this.vlist(order(end:-1:1))), ...
                   'UniformOutput',false);
        end

        function [] = remove_vertex(this,v)
            p = dfs(this.G);
            this.G(:,p) = [];
            this.G(p,:) = [];
            remove(this.map,vlist(p));
        end
    end
end