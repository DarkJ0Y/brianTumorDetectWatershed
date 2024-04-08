% Specify the path to the folder containing images and masks
close all;
clear all;
warning off;

folderPath_images = 'G:\MatLab\EEE 312 Matlab\DSP_Project_brain_tumor_detector\tumor_img';
folderPath_masks = 'G:\MatLab\EEE 312 Matlab\DSP_Project_brain_tumor_detector\mask_img';

% Get a list of all image files in the folder
imageFiles = dir(fullfile(folderPath_images, '*.tif'));
maskFiles = dir(fullfile(folderPath_masks, '*_mask.tif'));

% Check if the number of image files and mask files match
if numel(imageFiles) ~= numel(maskFiles)
    error('Number of image files and mask files do not match.');
end

% Loop through each image file and process it
numFiles = numel(imageFiles);
dice = zeros(1, numFiles);
IoU = zeros(1, numFiles);
f1Score = zeros(1, numFiles);

for i = 1:numFiles
    % Construct the full file paths
    imagePath = fullfile(folderPath_images, imageFiles(i).name);
%     if contains(imageFiles(i).name,num2str(i))
        maskPath = fullfile(folderPath_masks, maskFiles(i).name);
        if contains(maskFiles(i).name,'_mask')
             % Perform brain tumor detection and evaluation
           [dice(i), IoU(i), f1Score(i)] = brainTwoDetectFunc_two(imagePath, maskPath);
        
        end
%     end
end

% Calculate the average of the dice, IoU, and F1 score
diceValue = mean(dice);
IoUValue = mean(IoU);
f1ScoreValue = mean(f1Score);



%Standard deviation4
diceStd = std(dice);
IoUStd = std(IoU);
f1ScrStd = std(f1Score);


% calculte the normal distribution
%for dice coefficient
% diceX = linspace(min(dice),max(dice),1000);
x = linspace(0,1,1000);
pdfDice = normpdf(x,diceValue,diceStd);
% figure;
% plot(diceX,pdfDice,"b");

%for IoU score
% IoUX = linspace(min(IoU),max(IoU),1000);
pdfIoU = normpdf(x,IoUValue,IoUStd);
% figure;
% plot(IoUX,pdfIoU,"b");

%for F1score 
% f1ScrX = linspace(min(f1Score),max(f1Score),1000);
pdff1Scr = normpdf(x,f1ScoreValue,f1ScrStd);
% figure;
% plot(f1ScrX,pdff1Scr,"b");
figure;
plot(x,pdfDice,'b');
hold on;
plot(x,pdfIoU,'r');
hold on;
plot(x,pdff1Scr,'g');
legend('Dice coefficient','IoU Score','F1 Score');
grid on;


% Display the average scores
disp(['Average Dice Coefficient: ', num2str(diceValue),' and the standard deviation : ',num2str(diceStd)]);
disp(['Average IoU Score: ', num2str(IoUValue),' and the standard deviation : ',num2str(IoUStd)]);
disp(['Average F1 Score: ', num2str(f1ScoreValue),' and the standard deviation : ',num2str(f1ScrStd)]);