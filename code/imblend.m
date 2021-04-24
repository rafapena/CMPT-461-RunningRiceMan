function  output = imblend( source, mask, target, transparent)

output = source .* mask + target .* ~mask;

s = padarray(source, [1,1], 0, 'both');
t = padarray(target, [1,1], 0, 'both');
m = padarray(mask, [1,1], 0, 'both');
[r, c, ~] = size(t);

szA = r * c;
rowsA = zeros(szA, 1);
columnsA = zeros(szA, 1);
values = zeros(szA, 1);

s = reshape(s, szA, []);
t = reshape(t, szA, []);
m = reshape(m, szA, []);
b = zeros(szA, 3);

idx = 1;
vals = [4, -1, -1, -1, -1];

for i = 1:szA
    if m(i)
        b(i,:) = 4*s(i,:) - s(i-1,:) - s(i+1,:) - s(i+r,:) - s(i-r,:);
        colVals = [i, i-1, i+1, i+r, i-r];
        for j = 1:5
            idx0 = idx + j - 1;
            rowsA(idx0) = i;
            columnsA(idx0) = colVals(j);
            values(idx0) = vals(j);
        end
        idx = idx + 5;
    else
        b(i,:) = t(i,:);
        rowsA(idx) = i;
        columnsA(idx) = i;
        values(idx) = 1;
        idx = idx + 1;
    end
end

A = sparse(rowsA, columnsA, values, szA, szA);
x = A \ b;
x = reshape(x, [r, c, 3]);
x = x(2:r-1, 2:c-1, :);

[r, c, ~] = size(output);
for i = 1:r
    for j = 1:c
        if (mask(i, j, :))
            output(i, j, :) = x(i, j, :);
        end
    end
end