clc
clear all
data = xlsread('F:\0.TQP\data2\habitat\ANN\data.xlsx');
T=data(:,12);
p=data(:,2:11);
[p_tes,t_tes,p_tra,t_tra]=split_train_test(p, T, 2, 0.2);
p_train=p_tra';
p_test=p_tes';
t_train=t_tra';
t_test=t_tes';
train=[t_tra p_tra];
test=[t_tes p_tes];
save train ;
