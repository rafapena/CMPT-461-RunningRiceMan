function output = applytexture(src_img, tx_img, patch_size, fnum, fnum_total)

overlap = round(patch_size / 5);
alpha = 0.5;
[h_im, w_im, ~] = size(src_img);
[~, ~, c_tx] = size(tx_img);

bar = waitbar(0, 'Transferring texture...');
iter = 0;
max_iter = (h_im/(patch_size-overlap)) * (w_im/(patch_size-overlap));
output(1:patch_size, 1:patch_size, :) = first_transfer_patch(src_img, tx_img, alpha, patch_size, overlap);

for i = 1:patch_size-overlap:h_im-patch_size+1
    for j = 1:patch_size-overlap:w_im-patch_size+1
        
        upper_patch = [];
        left_patch = [];
        
        if i > 1
            upper_patch = output(i-patch_size+overlap:i+overlap-1, j:j+patch_size-1, :);
        end
        if j > 1
            left_patch = output(i:i+patch_size-1, j-patch_size+overlap:j-1+overlap, :);
        end
        
        image_patch = src_img(i:i+patch_size-1, j:j+patch_size-1, :);
        best_patch = best_transfer_patch(image_patch, tx_img, alpha, patch_size, overlap, upper_patch, left_patch);
        output(i:i+patch_size-1, j:j+patch_size-1, :) = best_patch;
        
        if i > 1
            overlap_patch = get_overlap(best_patch, patch_size, overlap, upper_patch, "up");
            output(i:i+overlap-1, j:j+patch_size-1, :) = overlap_patch;
            best_patch(1:overlap, :, :) =  overlap_patch;
        end
        if j > 1
            output(i:i+patch_size-1, j:j+overlap-1, :) = get_overlap(best_patch, patch_size, overlap, left_patch, "left");
        end
        
        iter = iter + 1;
        waitbar(iter/max_iter, bar, "Transferring texture for frame " + fnum + " out of " + fnum_total);
        
    end
end

output = imresize(output, [h_im, w_im]);
close(bar);