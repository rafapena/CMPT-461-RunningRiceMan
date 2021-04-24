function best_patch = best_transfer_patch(im_patch, tx, alpha, patch_size, overlap, upper_patch, left_patch)

trials = 1200;
selected_patches = zeros(patch_size, patch_size, 3, trials);
overlap_rms_errors = zeros(2, trials);
patch_rms_errors = zeros(1, trials);

for i = 1:trials
    
    selected_patch = get_random_patch(tx, patch_size);
    selected_patches(:, :, :, i) = selected_patch;
    patch_rms_errors(1, i) = sum((selected_patch-im_patch).^2, 'all');
    
    if ~isempty(upper_patch)
        bov1 = upper_patch(end-overlap+1:end, :, :);
        bov2 = selected_patch(1:overlap, :, :);
        overlap_rms_errors(1, i) = sum((bov1-bov2).^2, 'all');
    end
    if ~isempty(left_patch)
        bov1 = left_patch(:, end-overlap+1:end, :);
        bov2 = selected_patch(:, 1:overlap, :);
        overlap_rms_errors(2, i) = sum((bov1-bov2).^2, 'all');
    end
    
end

overlap_rms_errors = (overlap_rms_errors(1,:) + overlap_rms_errors(2,:)) ./ 2;
errors = (1-alpha) * patch_rms_errors + alpha * overlap_rms_errors;
[~, min_index] = min(errors);
best_patch = selected_patches(:, :, :, min_index);

end

