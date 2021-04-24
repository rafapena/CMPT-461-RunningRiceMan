function [r_range, c_range] = get_patch_range(r, c, output_vid_h, output_vid_w, patch_size)

r_range = r:r+patch_size-1;
c_range = c:c+patch_size-1;
if r+patch_size-1 > output_vid_h
    r_range = r:output_vid_h;
end
if c+patch_size-1 > output_vid_w
    c_range = c:output_vid_w;
end

