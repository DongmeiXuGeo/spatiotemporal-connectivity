clear;
clc;

data = xlsread('F:\0.TQP\data2\habitat\ANN\data.xlsx');
data = data(randperm(size(data,1)),:); %Random partition
ind = round(0.8 * size(data,1)); %Proportional division
%data= data(randperm(length(data)));
trainData = data(1:ind, 1:end); %Training set
testData = data(ind+1:end, 1:end); %Test set

Y = trainData(:,12);
X = trainData(:,2:11);
Y_test = testData(:,12);
X_test = testData(:,2:11);
isCategorical = [zeros(15,1);ones(size(X,2)-15,1)]; 
%% Optimal leaf selection
% For regression, the general rule is to set the leaf size to 5. The optimal leaf quantity was obtained by comparing different leaf quantity MSE
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
% In this study, leaf=20 is optimal
%% The number of trees is set to 50 (for faster convergence), and then increased to 100...
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
% In this study, ntrees=500 is the best

%% Train random forest and set random forest parameters
tic
leaf = 20;
ntrees = 500;
fboot = 1;
disp('Training the tree bagger')
b = TreeBagger(ntrees, X,Y, 'Method','regression', 'oobvarimp','on', 'surrogate', 'on', 'minleaf',leaf,'FBoot',fboot);
toc

%% Use the trained model to make predictions
disp('Estimate Output using tree bagger')
x = Y_test;
y = predict(b, X_test);
toc

% calculate the training data correlation coefficient
% Calculating correlation coefficient
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

%% Predict the whole study area
%Importing tif data
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

%Random forest
disp('Estimate Output using tree bagger')
y_pred = predict(b, pred);
toc
%Output data
r=y_pred';
re=(r-min(r))/(max(r)-min(r));
re=reshape(re',1974,2611);
info = geotiffinfo('F:\0.TQP\Data\bio\126\gyhtif\bio3.tif');
filename = strcat('F:\0.TQP\data2\habitat\RF\syx585.tif');
geotiffwrite(filename,re,R,'GeoKeyDirectoryTag',info.GeoTIFFTags.GeoKeyDirectoryTag);

%% Importance analysis of independent variables
% OOBPermutedPredictorDeltaError provides the importance of each independent variable, the greater the value, the more important the variable.
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


