%====================================================================
% EEG Seminar & Practical Klatt, Reiser, Hucke                         
%=====================================================================
clear all;
PATHIN = ['/Users/sophia/Desktop/uni/eeg/stats'];

% Load meanmat created in previous script [...Study_ERN.m]
meanmat = csvread([PATHIN '/meanmat.csv']);

% Exclude subject column from meanmat and rename
Data = meanmat(:,2:end);

% [h,p,kstat,critval] = lillietest(Data(:,1))
% [h,p,kstat,critval] = lillietest(Data(:,2))
% [h,p,kstat,critval] = lillietest(Data(:,3))
% [h,p,kstat,critval] = lillietest(Data(:,4))
% 
% hist(Data(:,1),20)
% hist(Data(:,2),20)
% hist(Data(:,3),20)
% hist(Data(:,4),20)

clear table

% Create a table reflecting the within subject factors
% step 1: create factor names
factorNames = {'congruent' 'correct'};
% step 2: create a table containing all factor combinations of our 2x2
% design (cong*corr, cong*incorr, incong*corr, incong*incorr)
within = table({'cong';'cong';'incong';'incong'},...
               {'corr';'incorr';'corr';'incorr'},...
               'VariableNames',{'congruent' 'correct'});
    
%Create data table
varNames = {'cong_corr','cong_incorr','incong_corr','incong_incorr'};
table = array2table(Data,'VariableNames',varNames);

% Fit repeated measures model: 
% 1st input argument: data table
% 2nd input argument: formula in Wilkinson notation
% within-factor: all combinations of cong_corr-incong_incorr
% between-factor: none (or 1)
% within variable specifies the names of our factor combinations
% for further information on the notation, see fitrm documentation
rm = fitrm(table,'cong_corr-incong_incorr~1','WithinDesign',within)

%Run repeated measures ANOVA on the specified model
%ANOVA_results contains our table of effects
[ANOVA_result] = ranova(rm,'WithinModel','congruent + correct + congruent*correct')

% calculate partial eta squared
% Sum of squares effect / (Sum of squares effect + Sum of Squares error)
peta_main_cong = ANOVA_result{3,1}/(ANOVA_result{3,1}+ANOVA_result{4,1}); 
peta_main_corr = ANOVA_result{5,1}/(ANOVA_result{5,1}+ANOVA_result{6,1});
peta_IA = ANOVA_result{7,1}/(ANOVA_result{7,1}+ANOVA_result{8,1});


figure;
boxplot([table.incong_corr+table.cong_corr,table.cong_incorr+table.incong_incorr], {'Correct', 'Incorrect'})
hold on
plot(1, mean(table.incong_corr+table.cong_corr), 'dg')
plot(2, nanmean(table.incong_incorr+table.cong_incorr), 'dg')
hold off
ylabel('Potential (μV)');
xlabel('Condition');

figure;
boxplot([table.incong_corr, table.cong_corr, table.cong_incorr, table.incong_incorr], {'incong_corr', 'cong_corr', 'cong_incorr', 'incong_incorr'})
hold on
plot(1, mean(table.incong_corr), 'dg')
plot(2, nanmean(table.cong_corr), 'dg')
plot(3, nanmean(table.cong_incorr), 'dg')
plot(4, nanmean(table.incong_incorr), 'dg')
hold off
ylabel('Potential (μV)');
xlabel('Condition');

