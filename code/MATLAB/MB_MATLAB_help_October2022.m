clear;clc;

%%
[ img , hdr ] = read_2dseq('D:\Tim MRI data\C15\12_mos_timept_July_2021\20210712_111914_190700_1_1\7\pdata\1');

%%
img=permute(img,[1 2 5 3 4]);
figure;montage(permute(img(40:end-40,40:end-40,:),[1 2 4 3]),'displayrange',[0 30000]);colormap jet;
% figure;montage(permute(img(:,:,:),[1 2 4 3]),'displayrange',[0 30000]);colormap jet;

%%
img_fil = smooth3(img,'gaussian',[5 5 1],0.65);
figure;montage(permute(img_fil(40:end-40,40:end-40,:),[1 2 4 3]),'displayrange',[0 30000]);colormap jet;

%%
ind=[1:5]; %[ 1 6 8]
img_trc=img_fil(:,:,ind);

%%
niftiwrite(img_trc,'MRItest.nii');
gzip('MRItest.nii');






