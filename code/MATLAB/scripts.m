clear;clc;

%%
[ img , hdr ] = read_2dseq('W:\MRI project\Data\Testing_Images\Prediction_RAW\20191124_124956_183261_3__1_1\7\pdata\1');
img=double(permute(img,[1 2 5 3 4]));
%figure;montage(permute(img(40:end-40,40:end-40,:),[1 2 4 3]),'displayrange',[0 30000]);colormap jet;
% figure;montage(permute(img(:,:,:),[1 2 4 3]),'displayrange',[0 30000]);colormap jet;
%%
img_fil=zeros(size(img));
for i=1:size(img,3)
    img_fil(:,:,i)=imnlmfilt(img(:,:,i),'DegreeOfSmoothing',600);
end

% for i=1:size(img,3)
%     sigma = mean(img(1:10,1:10,i),'all') / sqrt(pi/2);
%     img_fil2(:,:,i)=NLmeansfilter(img(:,:,i),5,2,sigma);
% end

for i=1:4
     niftiwrite(img(:,:,i),append(append('W:\MRI project\Data\Testing_Images\raw_nifti\183261_slice_',string(i)),'.nii'));
end

% figure;montage(permute(img(40:end-40,40:end-40,:),[1 2 4 3]),'displayrange',[0 30000]);colormap jet;
%  figure;montage(permute(img_fil(40:end-40,40:end-40,:),[1 2 4 3]),'displayrange',[0 30000]);colormap jet;
%  figure;montage(permute(img_fil2(40:end-40,40:end-40,:),[1 2 4 3]),'displayrange',[0 30000]);colormap jet;
% figure;montage(permute(img(40:end-40,40:end-40,:)-img_fil(40:end-40,40:end-40,:),[1 2 4 3]),'displayrange',[-100 100]);colormap jet;

% 
% img_gray = arrayfun(@(i)mat2gray(img(:,:,i)), 1:size(img,3), 'UniformOutput', false);
% img_filt = arrayfun(@(i) imnlmfilt(cell2mat(img_gray(i)),'DegreeOfSmoothing', 0.025), 1:14, 'UniformOutput', false);
% img_mat = cell2mat(arrayfun(@(x)permute(x{:},[1 3 2]),img_filt,'UniformOutput',false));
% img_mat = permute(img_mat, [1 3 2]);
%figure;montage(img_mat(40:end-40,40:end-40,:));colormap jet;

%%
% niftiwrite(img_trc,'MRItest4.nii');
% gzip('MRItest4.nii');

list = ls('W:\MRI project\Data\Testing_Images\Prediction600\*.nii');
for i=1:size(list,1)
    img2 = niftiread(append('W:\MRI project\Data\Testing_Images\Prediction600\',list(i,:)));
    img_crop=zeros(256,256);
    img_crop(:,31:226) = img2(:,:);
    niftiwrite(img_crop, append('W:\MRI project\Data\Testing_Images\Prediction600_crop\',list(i,:)));
end

% for i=1:len(list)
%     gzip(list[i]);
% end
%%
outputList = ls('W:\MRI project\Data\Output\WS600out.200-32.1-23\*.nii');
refList = ls('W:\MRI project\Data\Testing_Masks\*.nii');
images = ls('W:\MRI project\Data\Testing_Images\raw_nifti\*.nii');

output = zeros(25,6);

for j=1:size(outputList,1)
    img_ref = niftiread(append('W:\MRI project\Data\Testing_Images\raw_nifti\', images(j,:)));
    ref_mask = niftiread(append('W:\MRI project\Data\Output\WS600out.200-32.1-23\', outputList(j,:)));
    %ref_mask = niftiread(append('W:\MRI project\Data\Testing_Masks\', refList(j,:)));

    mask = zeros(256,256);
    %mask(8:247,8:247) = ref_mask(:,:);
    mask(:,:) = ref_mask(:,:);
    img = zeros(256,256);
    img(:,31:226) = img_ref(:,:);

    total = 0;
    visceral = 0;
    
    for i = 1:numel(img)
        if(img(i)>10135) && (img(i)<32767)
            total=total+1;
            if(mask(i) > 0.5)
                visceral = visceral + 1;
            end
        end
    end
    
    subQ = total - visceral;
    
    output(j,1) = j;
    output(j,2) = total;
    output(j,3) = visceral;
    output(j,4) = subQ;
    output(j,5) = visceral/total;
    output(j,6) = subQ/total;
end


writematrix(output, "W:\MRI project\Analsysis\ws_numbers3.csv")

%%
%Caculate the DICE score

outputList = ls('W:\MRI project\Data\Output\WS600out.200-32.1-23\*.nii');
refList = ls('W:\MRI project\Data\Testing_Masks\*.nii');
diceScores = zeros(25,1);

for j=1:size(outputList,1)
    ref_mask = zeros(256,256);
    
    ref_hold = niftiread(append('W:\MRI project\Data\Testing_Masks\',refList(j,:)));
    new_mask = niftiread(append('W:\MRI project\Data\Output\WS600out.200-32.1-23\',outputList(j,:)));
    
    ref_mask(:,31:226) = ref_hold(:,:);
    
    overlap = 0;
    area_ref = 0;
    area_new = 0;
    
    for i = 1:numel(ref_mask)
        if (ref_mask(i) > 0), area_ref = area_ref + 1; end
        if (new_mask(i) > 0), area_new = area_new + 1; end
        if (ref_mask(i) > 0) && (new_mask(i) > 0), overlap = overlap + 1; end
    end
    
    diceScores(j,1) = (overlap * 2) / (area_ref + area_new);
end

%%
closest = img2(1);
for i = 1:numel(img2)
    if(abs(7938 - img2(i)) < abs(7938 - closest))
        closest = img2(i);
    end
end

%%
%Calculate image threshold

%[n xout] = hist(img2, 256);
target = img2;

for i = 1:numel(target)
    if (target(i) < 150)
        target(i) = 0;
    end
end

T = mean(target, 'all');

while true
    index1 = (target(:)>T);
    avg1 = mean(target(index1),'all');
    index2 = (target(:)<=T);
    avg2 = mean(target(index2),'all');
    T_new = (avg1 + avg2)/2;
    if(abs(T-T_new) < 2) break; end
    T = T_new;
end

%%

minV = min(img2(:));
maxV = max(img2(:));
step = (maxV - minV)/256;
start = minV + step/2;

bins = zeros(256,1);
for i = 1:256
    bins(i) = start + (i - 1) * step;
end

[n,xout] = hist(img2, bins);

counts = zeros(256,1);
for i = 1:256
    counts(i) = sum(n(i,:));
end

movingIndex = 1;
while true
    sum1 = 0;
    sum2 = 0;
    for i = 1:movingIndex
        sum1 = sum1 + counts(i) * i;
        sum2 = sum2 + counts(i);
    end
    sum3 = 0;
    sum4 = 0;
    for i = (movingIndex+1):256
        sum3 = sum3 + counts(i) * i;
        sum4 = sum4 + counts(i);
    end
    newIndex = (sum1/sum2 + sum3/sum4)/2;
    if ((newIndex - round(newIndex) > 0.48) && (newIndex - round(newIndex) < 0.5))
        newIndex = newIndex + 0.02;
    end

    if((movingIndex+1) > round(newIndex)) || (movingIndex >= 256)
        break;
    end
    movingIndex = movingIndex + 1;
end

T = round(xout(movingIndex) + 5*step/6);

