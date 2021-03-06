function [ histo li histoV histoH li2 ] = STATS_histograms( file , NMDR , nbquantile , bins , Xlim , jointXlim , avg , norm)
%This function uses a dataset of images within the folder 'file' and uses
%the name and DR of the images stored in NMDR with the fusction stats_moments
%to compute histograms of the images according to Huang & Mumford, 1999
%   nbquantile: The dataset can be divided by DR categories with
%               nbquantile for the number-1 of category wanted.
%   bins: define the number of bins of the histogram as 2^bins
%   Xlim: absolute extreme value for the histogram defined as 10^Xlim
%   jointXlim: idem for the derivative statistics (jointhisto)
%   avg: average type -> 0:mean 1:median
%
%output: - histo: the averaged histograms among the different DR categories
%          with log axes
%        - li: bin values (log10 luminance values)
%        - histoV: the vertical derivative histograms among the different
%          DR categories with log axes
%        - histoH: the horizontal derivative histograms among the different
%          DR categories with log axes
%        - li2: bin values (log10 values)

lo = 0; %set as default,

if nbquantile == 1
    drlim = median(cell2mat(NMDR(:,2)));
elseif nbquantile == 0
    drlim = max(cell2mat(NMDR(:,2)));
else
    drlim = quantile(cell2mat(NMDR(:,2)),nbquantile);
end
histo = zeros(1,2^bins, nbquantile+1);
histoV = zeros(1,2^bins, nbquantile+1);
histoH = zeros(1,2^bins, nbquantile+1);
PDF = zeros(1,2^bins, nbquantile+1);

for A = 1:size(NMDR,1)
    
    disp(strcat('hist_',num2str(A)));
    clear LUM
    nm = NMDR{A,1};
    load(strcat('./',file,'/',nm));
    
    if exist('LUM') == 0
        if exist('LUM_psf') == 1
            LUM = LUM_psf;
        end
        if exist('LUM_nk') == 1
            LUM = LUM_nk;
        end
        if exist('LUM_csf') == 1
            LUM = LUM_csf;
        end
    end
    
    dr = NMDR{A,2};
    q = 1;
    while dr>drlim(q) & q<nbquantile
        q = q+1;
    end
    if dr>drlim(q)
        q = q+1;
    end
    
    if norm == 1
        LUM = LUM./max(LUM(:));
    end
    
    if norm == 2
        LUM = (LUM-min(LUM(:)))./(max(LUM(:))-min(LUM(:)));
    end
    
    
    [logh loghV loghH li li2] = histogramcreation(LUM, avg, lo, bins, Xlim, jointXlim);
    
    histo(:,:,q) = histo(:,:,q)+logh;
    histoV(:,:,q) = histoV(:,:,q)+loghV;
    histoH(:,:,q) = histoH(:,:,q)+loghH;
    
end

%Normalization of the histograms
SOMhist = sum(histo,2);
for Q = 1:size(SOMhist,3)
    histo(:,:,Q) = histo(:,:,Q)./SOMhist(:,:,Q);
end

SOMhist = sum(histoH,2);
for Q = 1:size(SOMhist,3)
    histoH(:,:,Q) = histoH(:,:,Q)./SOMhist(:,:,Q);
end

SOMhist = sum(histoV,2);
for Q = 1:size(SOMhist,3)
    histoV(:,:,Q) = histoV(:,:,Q)./SOMhist(:,:,Q);
end

SOMhist = sum(PDF,2);
for Q = 1:size(SOMhist,3)
    PDF(:,:,Q) = PDF(:,:,Q)./SOMhist(:,:,Q);
end

lit = li;
li2t = li2;
clear li li2

for i = 1:size(lit,2)-1
    li(i) = (lit(i)+lit(i+1))/2;
    li2(i) = (li2t(i)+li2t(i+1))/2;
end

%Computes the moments of the different histograms
momhisto = momenthisto(histo, li);
momhistoV = momenthisto(histoV, li2);
momhistoH = momenthisto(histoH, li2);

replc = find(file=='/');
file(replc) = '-';

save(strcat('./Results/Histograms_',file,'_', num2str(norm),'_', num2str(avg), '_', num2str(bins)), 'histo', 'histoV', 'histoH', 'li', 'li2', 'momhisto', 'momhistoV', 'momhistoH')


%PLOT______________________________________________________________________

histoplot(histo, li , NMDR);
axis([-Xlim Xlim 10^-8.1 0.1])
xlabel('log(I(i, j)) ? average(log(I))')
ylabel('log(Histogram)')
histoplot(histoH, li2 , NMDR );
axis([-jointXlim jointXlim 10^-8.1 1])
xlabel('log(I(i, j)) ? log(I(i, j+1)))')
ylabel('log(Histogram)')
end