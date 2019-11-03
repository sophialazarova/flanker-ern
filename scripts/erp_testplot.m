%% Flanker STUDY test plots %%
% This is a supporting script for EEG_Seminar_2019_Study_ERN.m to ensure
% you assign the correct conditions to the corresponding variables. 
% Goal is to create a figure that can be compared to the figure you create
% with the GUI. Hint: you might want to modify this figure and use it for
% your report. 

clear -regexp ^ERP

STUDY = pop_erspparams(STUDY);

[STUDY erpdata erptimes] = std_erpplot(STUDY,ALLEEG,'channels',{'FCz'},'noplot', 'on');

ERP_cong_corr = erpdata{1};
ERP_cong_incorr = erpdata{2};
ERP_incong_corr = erpdata{3};
ERP_incong_incorr = erpdata{4};

% % % % % testindexing of STUDY condition
test1 = mean(ERP_cong_corr,2,'omitnan');
test2 = mean(ERP_cong_incorr,2,'omitnan');
test3 = mean(ERP_incong_corr,2, 'omitnan');
test4 = mean(ERP_incong_incorr,2, 'omitnan');

figure
subplot(2,2,1)
plot(erptimes,test1)
axis([-1000,1000,-6,6]);
title('cong corr')
%axis ij;

subplot(2,2,2)
plot(erptimes,test2)
axis([-1000,1000,-6,6]);
title('cong incorr')
%axis ij;

subplot(2,2,3)
plot(erptimes,test3)
axis([-1000,1000,-6,6]);
title('incong corr')
%axis ij;

subplot(2,2,4)
plot(erptimes,test4)
axis([-1000,1000,-6,6]);
title('incong incorr')
%axis ij;