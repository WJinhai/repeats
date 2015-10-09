function [img,ind] = find_img_name(img_set,name)
ind = 0;

for img = img_set
    [~,name2,ext] = fileparts(img.url);
    is_found = strcmp(name,[name2 ext]);
    ind = ind+1;
    if is_found 
        return;
    end
end

assert(false,['File ' name ' is not found when loading img set.']);