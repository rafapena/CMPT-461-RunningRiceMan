function overlap_patch = get_overlap(selected_patch, patch_size, overlap, adjacent_patch, direction)

if direction == "up"
    adjacent_patch = permute(adjacent_patch, [2 1 3]);
    selected_patch = permute(selected_patch, [2 1 3]);
end

bov1 = adjacent_patch(:, end-overlap+1:end, :);
bov2 = selected_patch(:, 1:overlap, :);
e = (rgb2gray(bov1) - rgb2gray(bov2)) .^ 2;
E = zeros(patch_size, overlap);
E(1, :) = e(1, :);

for i = 2:patch_size
    for j = 1:overlap
        if j == 1
            E(i, j) = e(i, j) + min([E(i-1,j), E(i-1,j+1)]);
        elseif j == overlap
            E(i, j) = e(i, j) + min([E(i-1,j-1), E(i-1,j)]);
        else
            E(i, j) = e(i, j) + min([E(i-1,j-1), E(i-1,j), E(i-1,j+1)]);
        end
    end
end

[~, slice] = min(E(patch_size, :));
overlap_patch = zeros(patch_size, overlap, 3);

for i = patch_size:-1:1
    overlap_patch(i, 1:slice, :) = bov1(i, 1:slice, :);
    overlap_patch(i, slice:overlap, :) = bov2(i, slice:end, :);
    overlap_patch(i, slice, :) = (bov1(i,slice,:) + bov2(i,slice,:)) ./ 2;
    if i > 1
        if slice == 1
            [~, min_index] = min([Inf, E(i,slice), E(i,slice+1)]);
        elseif slice == overlap
            [~, min_index] = min([E(i,slice-1), E(i,slice), Inf]);
        else
            [~, min_index] = min([E(i,slice-1), E(i,slice), E(i,slice+1)]);
        end
        slice = slice + min_index - 2;
    end
end

if direction == "up"
    overlap_patch = permute(overlap_patch, [2 1 3]);
end

end