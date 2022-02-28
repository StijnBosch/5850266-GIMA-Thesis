clear
close all
I = double(imread('SingleDateImage_Amsterdam.tif'));
%I = I(1:50,1:50,:); % part of the image

Sz = size(I);

if Sz(3) > 1
    [coeff,scores] = pca(reshape(I,Sz(1)*Sz(2),Sz(3)));
    I = reshape(scores(:,1),Sz(1),Sz(2));
    clear coeff
end

% 16 bit conversion!
if ~strcmp(class(I),'uint16')
    mx = max(max(I));
    mi = min(min(I));
    I = uint16(((I - mi)./ (mx - mi)).*2^16-1);
end

%% scales
scales = [5 9]; % odd numbers
Fea = [];


%% TEXTURE OCCURRENCE
% Local average
I_avg = zeros(Sz(1),Sz(2),length(scales));
for i=1:length(scales)
    I_avg(:,:,i) = imfilter(I, fspecial('average',scales(i)), 'replicate');
end

% Local entropy
I_ent = zeros(Sz(1),Sz(2),length(scales));
for i=1:length(scales)
    I_ent(:,:,i) = entropyfilt(I, ones(scales(i)));
end

% Local standard deviation
I_std = zeros(Sz(1),Sz(2),length(scales));
for i=1:length(scales)
    I_std(:,:,i) = stdfilt(I, true(scales(i)));
end

% Local range
I_ran = zeros(Sz(1),Sz(2),length(scales));
for i=1:length(scales)
    I_ran(:,:,i) = rangefilt(I, true(scales(i)));
end

%% GLCM  : Co-occurrence

dir = [0 7 6 5]; % 0 deg, +45 deg, +90 deg, +135 deg
nLevels = 4;
Lx = length(dir);   % set length of direction vector
G = 2^nLevels;  % # gray levels i.e., nLevels = 4

[A0, L] = myQuantize(I, G);

I_glcm_con = zeros(Sz(1),Sz(2),length(scales));
I_glcm_cor = zeros(Sz(1),Sz(2),length(scales));
I_glcm_ene = zeros(Sz(1),Sz(2),length(scales));
I_glcm_hom = zeros(Sz(1),Sz(2),length(scales));
for i=1:length(scales)
    disp(i)
    w = scales(i);
    d = (w-1)/2;
    
    A = zeros(Sz(1)+2*d,Sz(2)+2*d);
    A(1+d:Sz(1)+d,1+d:Sz(2)+d) = A0;
    
    
    b = []; T = [];% temp arrays
    for n = 1+d:Sz(1)+d     % two outer loops go through NxM array
        disp(n)
        for m = 1+d:Sz(2)+d
            b = A(n-d:n+d,m-d:m+d);
            for k = 1:Lx     % Inner loop: orientation averaging
                CM = myGLCM(b, dir(k), 1, 1);
                stats = graycoprops(CM,'all');
                T(k,:) = [stats.Contrast stats.Correlation stats.Energy stats.Homogeneity];
            end
            T_mean = sum(T)/Lx;
            I_glcm_con(n-d,m-d,i) = T_mean(1);    %Contrast
            I_glcm_cor(n-d,m-d,i) = T_mean(2);    %Correlation
            I_glcm_ene(n-d,m-d,i) = T_mean(3);    %Energy
            I_glcm_hom(n-d,m-d,i) = T_mean(4);    %Homogeneity
            
            b = [];% clear temp array for next pass
            T = [];
        end
    end
    
end

k = 1; %first window size
figure,
subplot(2,4,1), imagesc(I_avg(:,:,2));colorbar;axis off;title('Average') 
subplot(2,4,2), imagesc(I_ent(:,:,2));colorbar;axis off;title('Entropy') 
subplot(2,4,3), imagesc(I_std(:,:,2));colorbar;axis off;title('Standard deviation') 
subplot(2,4,4), imagesc(I_ran(:,:,2));colorbar;axis off;title('Range') 
subplot(2,4,5), imagesc(I_glcm_con(:,:,2));colorbar;axis off;title('GLCM-Contrast') 
subplot(2,4,6), imagesc(I_glcm_cor(:,:,2));colorbar;axis off;title('GLCM-Correlation') 
subplot(2,4,7), imagesc(I_glcm_ene(:,:,2));colorbar;axis off;title('GLCM-Energy') 
subplot(2,4,8), imagesc(I_glcm_hom(:,:,2));colorbar;axis off;title('GLCM-Homogeneity') 
