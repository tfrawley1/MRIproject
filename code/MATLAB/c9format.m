folders = ls('W:\MRI project\C9\*Mo');

for i = 5:length(folders)
    folder = append('W:\MRI project\C9\',erase(folders(i,:),' '));
    nifti_location = append(folder,'_nifti\');
    crop_location = append(folder,'_crop\');
    mice = ls(append(folder, '\1*'));

    for j = 1:length(mice)
        mouse = append(folder,'\', erase(mice(j,:),'  '));
        file_location = append(mouse, '\11\pdata\1');

        [ img , hdr ] = read_2dseq(file_location);
        img=double(permute(img,[1 2 5 3 4]));

        for k = 1:8
            img_temp = img(:,:,k);
            fileName = append(erase(mice(j,:),'  '),'_slice_',string(k));
            niftiwrite(img_temp,append(append(nifti_location,fileName),'.nii'));

            img_fil =imnlmfilt(img_temp,'DegreeOfSmoothing',600);
            img_crop = zeros(256,256);
            img_crop(:,31:226) = img_fil(:,:);
            niftiwrite(img_crop,append(append(crop_location,fileName),'.nii'));
        end

    end
end

%%
folders = ls('W:\MRI project\C9\*old');

for i = 1:1

    output_location = append('W:\MRI project\C9\',erase(folders(i,:),' '),'_output\*.nii');
    image_location = append('W:\MRI project\C9\',erase(folders(i,:),' '),'_nifti\*.nii');
    outputList = ls(output_location);
    %refList = ls('W:\MRI project\Data\Testing_Masks\*.nii');
    images = ls(image_location);
    
    num = length(outputList(:,1));
    output = zeros(num,8);
    
    threshold = 0;
    imgName = ' ';
    lastName = '123456';
    for j=1:num
        imgName = erase(images(j,:),' ');
        imgLoc = append(erase(image_location,'*.nii'), imgName);
        img_ref = niftiread(imgLoc);
        maskLoc = append(erase(output_location,'*.nii'), erase(outputList(j,:),' '));
        mask = niftiread(maskLoc);
    
        img = zeros(256,256);
        img(:,31:226) = img_ref(:,:);

        if (not(strcmp(imgName(1:6),lastName(1:6))))
            threshold = isoThreshold(img_ref);
        end
        lastName = imgName(1:6);
    
        total = 0;
        visceral = 0;
        
        for k = 1:numel(img)
            if(img(k)>=threshold) && (img(k)<32767)
                total=total+1;
                if(mask(k) > 0.5)
                    visceral = visceral + 1;
                end
            end
        end
        
        subQ = total - visceral;
        
        output(j,1) = str2double(images(j,1:6));
        output(j,2) = str2double(imgName(length(imgName)-4));
        output(j,3) = total;
        output(j,4) = visceral;
        output(j,5) = subQ;
        output(j,6) = visceral/total;
        output(j,7) = subQ/total;
        output(j,8) = threshold;
    end
    
    xlName = append('W:\MRI project\Longitudinal Analysis\C9_analysis_',erase(folders(i,:),' '),'.xlsx');
    writematrix(output, xlName);
end