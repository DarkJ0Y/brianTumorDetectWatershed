clc
clear;
close all;

%1) Taking MRI image of brain as input.
% Select the input MRI and ground truth images
[files, path] = uigetfile({'*.tif', 'TIFF Files'}, 'Select input and ground truth images', 'MultiSelect', 'on');

% Check if files is a cell array (multiple files selected) or a string (single file selected)
if iscell(files)
    num_files = length(files);
else
    num_files = 1;
    files = {files}; % Convert to cell array for consistency
end

% Check if both input and ground truth images are selected
if num_files ~= 2
    error('Please select exactly two images.');
end

% Get the file paths for the input MRI and ground truth images
str = fullfile(path, files{1});
strTr = fullfile(path, files{2});

% Read the input MRI and ground truth images
I = imread(str);
IGndTr = imread(strTr);
Im=I;
I=imread(str);
figure;
imshow(I);
title('Input image');



%2) Converting it to gray scale image.
I=rgb2gray(I);
figure;
imshow(I);
title('gray image');

gsAdj=I;
%skull stripping
imbw=gsAdj>20;

imf=imfill(imbw,'holes');
r = 20;
se = strel("disk",r);
erode_bw = imerode(imf,se);
gsAdj=immultiply(gsAdj,erode_bw);
imshow(gsAdj);

I=gsAdj;
figure;
imshow(I);
title('skull image');
%3) Applying high pass filter for noise removal.
H = padarray(2,[2 2]) - fspecial('gaussian' ,[5 5],2);
sharpened = imfilter(I,H);
figure;
imshow([sharpened]);
title('Sharpened image');

%4) Apply median filter to enhance the quality of image.
Median = medfilt2(sharpened); %3x3 mean of pixels
figure;
imshow([Median]);
title(['Madian filtered image']);



%5)Threshold segmentation.
level = multithresh(Median, 3); % Calculate multiple thresholds for the image
seg_I = imquantize(Median, level); % Quantize the intensity values of the image
RGB = label2rgb(seg_I); % Convert segmented image into a color image
Threshold = rgb2gray(RGB); % Convert color image to grayscale
figure; imshow(Threshold); title('after thresholding'); % Display thresholded image

im = Threshold; % Copy thresholded image
%t = 179; % Set threshold value
im(im > 26 & im <76 ) = 255; % Thresholding: set pixels equal to threshold to 255
im(im > 76) = 0; % Thresholding: set pixels not equal to threshold to 0
im(im <26)=0;
im(im==76)=225;
BW=im;
figure; imshow(BW); title('after thresholding 2'); % Display binary image



%6) Watershed segmentation. 
C = ~BW;
D = -bwdist(C);
L = watershed(D);
Wi=label2rgb(C,'gray','w');
figure;
imshow(Wi);title('grayscale with white boundaries')
lvl2 = graythresh(Wi);
BW2 = im2bw(Wi,lvl2);
figure;
imshow(BW2);
title('watershed');

BW2=BW;




%morphological
sout=BW2;
label=bwlabel(sout);
stats=regionprops(logical(sout),'Solidity','Area','BoundingBox');
density=[stats.Solidity];
area=[stats.Area];
high_dense_area=density>0.2;
max_area=max(area(high_dense_area));
tumor_label=find(area==max_area);
disp(max_area)
tumor=ismember(label,tumor_label);
no_tumor = 0;
if max_area>200
   figure;
   imshow(tumor)
   title('tumor alone','FontSize',20);
else
    h = msgbox('No Tumor!!','status');
    %disp('no tumor');
    no_tumor =1;
    tumor(tumor>0)=0;
end
BW3=tumor;

r = 100;
se = strel("disk", r);
tumor=imclose(BW3,se);
figure
imshow(tumor);
title('closed image');

% 9) Overlaying
OLtumor=tumor;
[M, N] = size(OLtumor);
A = zeros(M, N);
for i = 1:M
    for j = 1:N
        if(OLtumor(i, j) == 0)
            A(i, j) = 1;
        end
    end
end

OLmask=IGndTr;
[M, N] = size(OLtumor);
A2 = zeros(M, N);
for i = 1:M
    for j = 1:N
        if(OLmask(i, j) == 0)
            A2(i, j) = 1;
        end
    end
end


figure;
subplot(121)
h = imshow(Im),title('Detected tumor');
hold on;
set(h, 'AlphaData', A);
hold off;
subplot(122)
h1 = imshow(Im),title('Orginal mask');
hold on;
set(h1, 'AlphaData', A2);
hold off
%result evaluation

%determine the dice coefficient
%take the input of the predicted image and the ground truth image
predictedImage = tumor;
groundTruthImage = IGndTr;

% Ensure the input images are binary
    predicted = logical(predictedImage);
    groundTruth = logical(groundTruthImage);

    % Calculate the Dice coefficient
    if no_tumor == 1
       intersection = nnz(predicted == groundTruth);
       diceCoefficient = 2 * intersection / 131072;
    else
         intersection = nnz(predicted & groundTruth);
         diceCoefficient = 2 * intersection / (nnz(predicted) + nnz(groundTruth));
    end

disp(['Dice Coefficient: ' num2str(diceCoefficient)]);

% Detemine the IoU coefficient
% Calculate the IoU
if no_tumor == 1
    union = 131072-intersection;
    iouScore = intersection / union;
else
    union = nnz(predicted | groundTruth);
    iouScore = intersection / union;
end

disp(['IoU Score: ' num2str(iouScore)]);

% Detemine the F1 coefficient
if no_tumor == 1
   truePositives = sum(groundTruth == predicted);
   falsePositives = sum(~groundTruth == predicted);
   falseNegatives = sum(groundTruth == ~predicted);
else
    truePositives = sum(groundTruth & predicted);
    falsePositives = sum(~groundTruth & predicted);
    falseNegatives = sum(groundTruth & ~predicted);
end

precision = truePositives / (truePositives + falsePositives);
recall = truePositives / (truePositives + falseNegatives);

f1Score = 2 * (precision * recall) / (precision + recall);
disp(['F1 Score: ' num2str(f1Score)]);