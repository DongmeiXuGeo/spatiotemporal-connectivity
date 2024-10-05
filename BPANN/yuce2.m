clc
clear all
load train
k=1;
net=newff(p_train,t_train,16,{'tansig','purelin'},'traingdm');
net.trainParam.lr=0.02;
net.trainParam.epochs=5000;
net.trainParam.goal=0.1;
net.trainParam.mc=0.7;
[net,tr]=traingdm(net,p_train,t_train);
view(net);
test_ou=sim(net,p_test);
test_out=(test_ou-min(test_ou))/(max(test_ou)-min(test_ou));
error=t_test-test_out;
mse_max=mse(error);
disp(['The mean square error of the network is',num2str(mse_max)]);
TA=test_out';compare=[TA t_tes];
save net
