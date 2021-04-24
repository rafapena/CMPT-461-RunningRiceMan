clear;
close all;
clc;

% --------------------------------------------------------------------------------------------------------------------------
% Edit parameters - Begin
% --------------------------------------------------------------------------------------------------------------------------


% Duplicate the video output's frames e times
e = 5;

% For every entry in inputs (from left to right):
% 1) Name of texture file (JPG) for data/textures
% 2) Name of running avatar video file (AVI) for data/avatars
% 3) Name of background video file (AVI) for data/backgrounds
% 4) [y, x] position (middle of image), in a normlized [0, 1] range, the avatar will be placed into the background
% 5) Patch size for the avatar video, during texture synthesis
% 6) Threshold for connected component labelling (should be lower than the patch size)
inputs = [
    {'rice', 'avatar0', 'SideRoadBackground', [0.5 0.5], 25, 15}
    {'rice', 'avatar1', 'FrontRoadBackground', [0.5 0.5], 12, 7}
    ];

% Select which input to use from the list above
selected_input = 1;


% --------------------------------------------------------------------------------------------------------------------------
% Edit parameters - End
% --------------------------------------------------------------------------------------------------------------------------

% Loaded from the inputs
in = inputs(selected_input, :);
tx = im2double(imread('../data/textures/' + string(in(1)) + '.jpg'));
src_vid = load_video('../data/avatars/' + string(in(2)) + '.avi');
dest_vid = load_video('../data/backgrounds/' + string(in(3)) + '.avi');
spos = cell2mat(in(4));
patch_size = cell2mat(in(5));
m_threshold = cell2mat(in(6));

% Convert spos from normalized [0, 1] to the respective image dimensions
% and anchor the avatar's focal point to the center of the image
spos(1) = spos(1) * size(dest_vid(1).cdata,1) - size(src_vid(1).cdata,1)/2;
spos(2) = spos(2) * size(dest_vid(1).cdata,2) - size(src_vid(1).cdata,2)/2;

% Thresholds for what is considered an edge
low_edge_threshold = 0.1;
high_edge_threshold = 0.2;

% Read frame counts from the loaded videos
src_frame_count = size(src_vid, 2);
dest_frame_count = size(dest_vid, 2);

% Setup mask video
mask_vid_h = size(src_vid(1).cdata, 1);
mask_vid_w = size(src_vid(1).cdata, 2);
mask_vid(1:src_frame_count) = struct('cdata', zeros(mask_vid_h, mask_vid_w, 3, 'uint8'), 'colormap', []);

% Get the mask color of the file: Assume that the top left end of the pixel is a color from the masked green screen
mask_converted_color = src_vid(1).cdata(1, 1, :);
mc_r = mask_converted_color(:, :, 1);
mc_g = mask_converted_color(:, :, 2);
mc_b = mask_converted_color(:, :, 3);
mask_vid(1).cdata = get_silhouette(src_vid(1).cdata, mc_r, mc_g, mc_b);


% Add texture to the source image while setting white regions for the mask
src_vid_nontextured = src_vid;
src_vid(1).cdata = applytexture(im2double(src_vid(1).cdata), tx, patch_size, 1, src_frame_count);
for i = 2:src_frame_count
    
    % Get image patches and the difference image
    last0_e = canny_edge_detection(src_vid_nontextured(i - 1).cdata, low_edge_threshold, high_edge_threshold);
    curr0_e = canny_edge_detection(src_vid_nontextured(i).cdata, low_edge_threshold, high_edge_threshold);
    D = abs(double(curr0_e) - double(last0_e));

    % Get image non-zero pixel count per patch
    S = zeros(ceil(mask_vid_h/patch_size), ceil(mask_vid_w/patch_size));
    s_iter_r = 1;
    for r = 1:patch_size:mask_vid_h
        s_iter_c = 1;
        for c = 1:patch_size:mask_vid_w
            [r_range, c_range] = get_patch_range(r, c, mask_vid_h, mask_vid_w, patch_size);
            dk_patch = D(r_range, c_range, :);
            S(s_iter_r, s_iter_c) = sum(sum(dk_patch > 0, 2));
            s_iter_c = s_iter_c + 1;
        end
        s_iter_r = s_iter_r + 1;
    end
    
    % Get matix M from S then do connected component labelling
    M = S > m_threshold;
    M0 = conn_component_labelling(M);
    
    % Get frame mask
    mask_vid(i).cdata = get_silhouette(src_vid(i).cdata, mc_r, mc_g, mc_b);
    
    % Update the output
    last = src_vid(i - 1).cdata;
    curr = applytexture(im2double(src_vid(i).cdata), tx, patch_size, i, src_frame_count);
    src_vid(i).cdata = last;
    
    % Replace with texture
    [h, w] = size(M0);
    for r = 1:h
        for c = 1:w
            if M0(r, c) == 1
                [r_range, c_range] = get_patch_range((r-1)*patch_size+1, (c-1)*patch_size+1, mask_vid_h, mask_vid_w, patch_size);
                src_vid(i).cdata(r_range, c_range, :) = curr(r_range, c_range, :);
            end
        end
    end
end


% Add duplicated frames to the video (source/mask or target) with less frames
iter = 0;
for i = src_frame_count+1:dest_frame_count
    s = mod(iter, src_frame_count) + 1;
    src_vid(i).cdata = src_vid(s).cdata;
    mask_vid(i).cdata = mask_vid(s).cdata;
    iter = iter + 1;
end
for i = dest_frame_count+1:src_frame_count
    s = mod(iter, dest_frame_count) + 1;
    dest_vid(i).cdata = dest_vid(s).cdata;
    iter = iter + 1;
end

% Re-read frame counts after duplicating the entries
src_frame_count = size(src_vid, 2);
dest_frame_count = size(dest_vid, 2);


% Setup output file
output_vid_h = size(dest_vid(1).cdata, 1);
output_vid_w = size(dest_vid(1).cdata, 2);
output_vid(1:dest_frame_count) = struct('cdata', zeros(output_vid_h, output_vid_w, 3, 'uint8'), 'colormap', []);

% Setup for blending: Enlarge mask and source image with black padding to the target image dimensions
sx = spos(1):spos(1)+size(src_vid(1).cdata,1)-1;
sy = spos(2):spos(2)+size(src_vid(1).cdata,2)-1;
for i = 1:src_frame_count
    bg_src = zeros([output_vid_h, output_vid_w, 3]);
    bg_src(sx, sy, :) = src_vid(i).cdata;
    src_vid(i).cdata = bg_src;
    bg_mask = zeros([output_vid_h, output_vid_w, 3]);
    bg_mask(sx, sy, :) = mask_vid(i).cdata;
    mask_vid(i).cdata = bg_mask;
end

% Blend source image into the target image
bar = waitbar(0, 'Blend source into target...');
for i = 1:dest_frame_count
    source = im2double(src_vid(i).cdata);
    mask = round(im2double(mask_vid(i).cdata));
    target = im2double(dest_vid(i).cdata);
    output_vid(i).cdata = imblend(source, mask, target);
    waitbar(i/dest_frame_count, bar, "Blending source into frame " + i + " out of " + dest_frame_count);
end
close(bar);


% Duplicate the video frames e times: Just used to increase the length of the video
len = dest_frame_count;
for i = 1:e
    for j = 1:dest_frame_count
        len = len + 1;
        output_vid(len).cdata = output_vid(j).cdata;
    end
end

% Save the video
for i = 1:len
    output_vid(i).cdata = uint8(output_vid(i).cdata .* 255);
end
v = VideoWriter('../output/result_' + string(selected_input) + '.avi');
v.FrameRate = 4;
open(v);
writeVideo(v, output_vid);
close(v);

% Play the video
implay(output_vid, 5);