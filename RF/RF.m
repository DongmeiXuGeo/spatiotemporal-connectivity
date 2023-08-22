clear;
clc;

data = xlsread('F:\0.TQP\data2\habitat\ANN\data.xlsx');
data = data(randperm(size(data,1)),:); %随机划分
ind = round(0.8 * size(data,1)); %按比例分
%data= data(randperm(length(data)));
trainData = data(1:ind, 1:end); %训练集
testData = data(ind+1:end, 1:end); %测试集

Y = trainData(:,12);
X = trainData(:,2:11);
Y_test = testData(:,12);
X_test = testData(:,2:11);
isCategorical = [zeros(15,1);ones(size(X,2)-15,1)]; 
%% 最优leaf选择
% 对于回归，一般规则是将叶子大小设置为5。通过比较不同叶子数量MSE获得最佳叶子数量
% 叶子数量越少MSE越小，即使如此也肯定不是越小越好，这里就假设leaf=5是最优了
leaf = [5 10 20 50 100];
col = 'rbcmy';
figure
for i=1:length(leaf)
    b = TreeBagger(50,X,Y,'Method','R','OOBPrediction','On',...
			'CategoricalPredictors',find(isCategorical == 1),...
            'MinLeafSize',leaf(i));
    plot(oobError(b),col(i))
    hold on
end
xlabel('Number of Grown Trees')
ylabel('Mean Squared Error') 
legend({'5' '10' '20' '50' '100'},'Location','NorthEast')
hold off
% 本研究leaf=20是最优
%% 树的数量设置，前面用了50棵树（为了收敛速度快），接下来增加到100
ntrees = [50 100 200 300 400 500];
col = 'rgbmyk';
figure
for i=1:length(ntrees)
    b = TreeBagger(ntrees(i),X,Y,'Method','R','OOBPredictorImportance','On',...
    'CategoricalPredictors',find(isCategorical == 1),...
    'MinLeafSize',20);
    plot(oobError(b),col(i))
    hold on
end
xlabel('Number of Grown Trees')
ylabel('Mean Squared Error') 
legend({'50' '100' '200' '300' '400' '500'},'Location','NorthEast')
hold off
% 本研究ntrees=500是最优

%% 训练随机森林，TreeBagger使用内容，以及设置随机森林参数
tic
leaf = 20;
ntrees = 500;
fboot = 1;
disp('Training the tree bagger')
b = TreeBagger(ntrees, X,Y, 'Method','regression', 'oobvarimp','on', 'surrogate', 'on', 'minleaf',leaf,'FBoot',fboot);
toc

%% 使用训练好的模型进行预测
disp('Estimate Output using tree bagger')
x = Y_test;
y = predict(b, X_test);
toc

% calculate the training data correlation coefficient
% 计算相关系数
cct=corrcoef(x,y);
cct=cct(2,1);


% Create a scatter Diagram
disp('Create a scatter Diagram')

% plot the 1:1 line
plot(x,x,'LineWidth',3);

hold on
scatter(x,y,'filled');
hold off
grid on

set(gca,'FontSize',18);
xlabel('Actual','FontSize',25);
ylabel('Estimated','FontSize',25);
title(['R^2=',num2str(cct^2,2)],'FontSize',30);
fn='ScatterDiagram';
fnpng=[fn,'.png'];
print('-dpng',fnpng);

%% 预测全域
%输入tif数据
[A1,R]=geotiffread('F:\0.TQP\data2\yinzitif\585\gyhbio10.tif');
[A2,R]=geotiffread('F:\0.TQP\data2\yinzitif\585\gyhbio13.tif');
[A3,R]=geotiffread('F:\0.TQP\data2\yinzitif\585\gyhbio14.tif');
[A4,R]=geotiffread('F:\0.TQP\data2\yinzitif\585\gyhbio7.tif');
[A5,R]=geotiffread('F:\0.TQP\data2\yinzitif\gyhdem.tif');
[A6,R]=geotiffread('F:\0.TQP\data2\yinzitif\gyhdis_wa.tif');
[A7,R]=geotiffread('F:\0.TQP\data2\yinzitif\gyhhfp.tif');
[A8,R]=geotiffread('F:\0.TQP\data2\yinzitif\585\ssp585.tif');
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

%随机森林
disp('Estimate Output using tree bagger')
y_pred = predict(b, pred);
toc
%输出数据
r=y_pred';
re=(r-min(r))/(max(r)-min(r));
re=reshape(re',1974,2611);
info = geotiffinfo('F:\0.TQP\Data\bio\126\gyhtif\bio3.tif');
filename = strcat('F:\0.TQP\data2\habitat\RF\syx585.tif'); % 栅格数据的每个文件地址+文件名
geotiffwrite(filename,re,R,'GeoKeyDirectoryTag',info.GeoTIFFTags.GeoKeyDirectoryTag);
%% 自变量重要性分析
% 自变量对RF模型贡献有大有小，RF的预测能力依赖于贡献大的自变量。对于每个自变量，可以观察其重要性，进行取舍组合，并查看MSE是否有改善。
% OOBPermutedPredictorDeltaError提供了每个自变量的重要性，值越大，变量越重要。
figure
bar(b.OOBPermutedPredictorDeltaError)
xlabel('Feature Number') 
ylabel('Out-of-Bag Feature Importance')

% Calculate the relative importance of the input variables
tic
disp('Sorting importance into descending order')
weights=b.OOBPermutedVarDeltaError;
[B,iranked] = sort(weights,'descend');
toc

%--------------------------------------------------------------------------
disp(['Plotting a horizontal bar graph of sorted labeled weights.']) 

%--------------------------------------------------------------------------
figure
barh(weights(iranked),'g');
xlabel('Variable Importance','FontSize',30,'Interpreter','latex');
ylabel('Variable Rank','FontSize',30,'Interpreter','latex');
title(...
    ['Relative Importance'],...
    'FontSize',17,'Interpreter','latex'...
    );
hold on
barh(weights(iranked(1:10)),'y');
barh(weights(iranked(1:5)),'r');

%--------------------------------------------------------------------------
grid on 
xt = get(gca,'XTick');    
xt_spacing=unique(diff(xt));
xt_spacing=xt_spacing(1);    
yt = get(gca,'YTick');    
ylim([0.25 length(weights)+0.75]);
xl=xlim;
xlim([0 2.5*max(weights)]);

%--------------------------------------------------------------------------
% Add text labels to each bar
for ii=1:length(weights)
    text(...
        max([0 weights(iranked(ii))+0.02*max(weights)]),ii,...
        ['Column ' num2str(iranked(ii))],'Interpreter','latex','FontSize',11);
end

%--------------------------------------------------------------------------
set(gca,'FontSize',16)
set(gca,'XTick',0:2*xt_spacing:1.1*max(xl));
set(gca,'YTick',yt);
set(gca,'TickDir','out');
set(gca, 'ydir', 'reverse' )
set(gca,'LineWidth',2);   
drawnow

%--------------------------------------------------------------------------
fn='RelativeImportanceInputs';
fnpng=[fn,'.png'];
print('-dpng',fnpng);

%--------------------------------------------------------------------------
% Ploting how weights change with variable rank
disp('Ploting out of bag error versus the number of grown trees')

figure
plot(b.oobError,'LineWidth',2);
xlabel('Number of Trees','FontSize',30)
ylabel('Out of Bag Error','FontSize',30)
title('Out of Bag Error','FontSize',30)
set(gca,'FontSize',16)
set(gca,'LineWidth',2);   
grid on
drawnow
fn='EroorAsFunctionOfForestSize';
fnpng=[fn,'.png'];
print('-dpng',fnpng);


