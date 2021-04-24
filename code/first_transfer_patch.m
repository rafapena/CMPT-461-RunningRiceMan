function patch = first_transfer_patch(im, tx, alpha, patch_size, overlap)

trials = 600;
selected_patches = zeros(patch_size, patch_size, 3, trials);
overlap_rms_errors = zeros(1, trials);

first_im_patch = im(1:patch_size, 1:patch_size, :);
bov1 = first_im_patch(:, end-overlap+1:end, :);
patch_rms_errors = zeros(1, trials);

for i = 1:trials
    
    selected_patch = get_random_patch(tx, patch_size);
    selected_patches(:, :, :, i) = selected_patch;
    
    bov2 = selected_patch(:, 1:overlap, :);
    overlap_rms_errors(1, i) = sum((bov1-bov2).^2, 'all');
    patch_rms_errors(1, i) = sum((selected_patch-first_im_patch).^2, 'all');
    
end

errors = (1-alpha) * patch_rms_errors + alpha * overlap_rms_errors;
[~, min_index] = min(errors);
patch = selected_patches(:, :, :, min_index);

end

