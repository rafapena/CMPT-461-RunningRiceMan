function patch = get_random_patch(im, patch_size)

r = randi(size(im,1)-patch_size);
c = randi(size(im,2)-patch_size);
patch = im(r:r+patch_size-1, c:c+patch_size-1, :);

end

