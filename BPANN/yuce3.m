clc
clear all
load net
%输入tif数据
[A1,R]=geotiffread('F:\0.TQP\data2\yinzitif\370\gyhbio10.tif');
[A2,R]=geotiffread('F:\0.TQP\data2\yinzitif\370\gyhbio13.tif');
[A3,R]=geotiffread('F:\0.TQP\data2\yinzitif\370\gyhbio14.tif');
[A4,R]=geotiffread('F:\0.TQP\data2\yinzitif\370\gyhbio7.tif');
[A5,R]=geotiffread('F:\0.TQP\data2\yinzitif\gyhdem.tif');
[A6,R]=geotiffread('F:\0.TQP\data2\yinzitif\gyhdis_wa.tif');
[A7,R]=geotiffread('F:\0.TQP\data2\yinzitif\gyhhfp.tif');
[A8,R]=geotiffread('F:\0.TQP\data2\yinzitif\370\ssp370.tif');
[A9,R]=geotiffread('F:\0.TQP\data2\yinzitif\gyhndvi.tif');
[A10,R]=geotiffread('F:\0.TQP\data2\yinzitif\gyhslope.tif');
AA(:,1)=A1(:);
AA(:,2)=A2(:);
AA(:,3)=A3(:);
AA(:,4)=A4(:);
AA(:,5)=A5(:);
AA(:,6)=A6(:);
AA(:,7)=A7(:);
AA(:,8)=A8(:);
AA(:,9)=A9(:);
AA(:,10)=A10(:);
AA=double(AA);
AA(AA==-9999)=nan;
AA(AA<-1000000)=nan;
AA(AA==15)=nan;
pred=AA;
results=sim(net,pred');
r=results';
re=(r-min(r))/(max(r)-min(r));
re=reshape(re',1974,2611);
%re还原为tif格式
info = geotiffinfo('F:\0.TQP\Data\bio\126\gyhtif\bio3.tif');
filename = strcat('F:\0.TQP\data2\habitat\ANN\syx370.tif'); % 栅格数据的每个文件地址+文件名
geotiffwrite(filename,re,R,'GeoKeyDirectoryTag',info.GeoTIFFTags.GeoKeyDirectoryTag);
%xlswrite('compare_20.xlsx',compare);%改名称