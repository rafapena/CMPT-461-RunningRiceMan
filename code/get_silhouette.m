function output = get_silhouette(img, red, green, blue)

% Color similarity threshold
s = 20;

ch1 = double(red);
ch2 = double(green);
ch3 = double(blue);

[h, w, ~] = size(img);
output = zeros(h, w, 3);
for r = 1:h
    for c = 1:w
        R = double(img(r, c, 1));
        G = double(img(r, c, 2));
        B = double(img(r, c, 3));
        cond = abs(R-ch1) < s && abs(G-ch2) < s && abs(B-ch3) < s;
        output(r, c, :) = ~cond * 255;
    end
end

% Resize a bit so that white area in the mask is a little bit larger
pad = 20;
output_aux = imresize(output, [h+pad, w+pad]);
p2 = pad / 2;
output = output_aux(p2:h+p2-1, p2:w+p2-1, :);