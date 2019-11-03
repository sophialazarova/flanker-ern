%====================================================================
% EEG Seminar & Practical Klatt, Reiser, Hucke                         
%=====================================================================
% Extract the data to export for statistics
% 1. For each condition correct and incorrect create a grand average 
% (group level)and determine the time point of the absolute minimum around 
% the response
% 2. On the subject level, for all four factor levels, extract and average 
% the data in a small time window around the previously determined time point
% 3. Export data to do statistics

%eeglab;

% !!!! Load STUDY manually !!!!!

% Define Path variables for export
PATHOUT = ['/Users/sophia/Desktop/uni/eeg/stats'];

% Before we start, some basics on data handling
% 101 indexing:
vector = [5 4 6 8 3]
%indexing single positions in a vector
vector(3)
vector(5)
% If we want to get more than one element at a time we can use a second 
% vector with the same length to index the original vector. This new vector
% has ones at the positions at which we want to get the element of the original
% vector and zeros at those positions that do not interest us. 
index1 = [false false true false true]
index2 = logical([0 0 1 0 1])
index3 = logical([1 1 0 0 0])
indexed_vector1 = vector(index1)
indexed_vector2 = vector(index2)
indexed_vector3 = vector(index3)
%% Back to our data
% Extract data from STUDY 

clear -regexp ^ERP %this clears all variables beginning with ERP

% This is important if you
% previously ran a topoplot script - the STUDY saves your settings about 
% time windows etc. We don't want that here.
STUDY = pop_erpparams(STUDY, 'topotime', []); 

% This loads all data from channel FCz.
% STUDY loads our preselected study design
% erpdata loads our precomputed erp data
% erptimes loads our time series vector in 2 ms steps (Sampling rate = 500 Hz)
% - first erptimes-datapoint = -1000ms
% - last erptimes-datapoint = 1000ms
[STUDY erpdata erptimes] = std_erpplot(STUDY,ALLEEG,'channels',{'FCz'},'noplot', 'on');

% Sometimes you do not know which index corresponds to which condition
% Here it helps to plot each condition and compare it to the plots you have
% created using the GUI. For this use the script:
% EEG_Seminar_2019_Study_testplot.m
ERP_cong_corr = erpdata{1}; %data for congruent, correct trials
ERP_cong_incorr = erpdata{2}; %data for congruent, incorrect trials
ERP_incong_corr = erpdata{3}; %...
ERP_incong_incorr = erpdata{4};

%we want to detect the ERN peak within the average of correct vs.                       
%incorrect trials
ERP_corr = mean([ERP_cong_corr,ERP_incong_corr],2,'omitnan')
ERP_incorr = mean([ERP_cong_incorr,ERP_incong_incorr],2,'omitnan')

%plot the grand average: correct vs. incorrect
figure
plot(erptimes,ERP_corr',erptimes,ERP_incorr')
axis([-1000,1000,-6,6]); %define your x and y axis
legend('corr','incorr'); %this needs to correspond to the order in which you plot your variables
title('grand average') %choose a title
axis ij; %this inverts the axis (negative up, positive down)

%% HERE WE NEED OUR INDEXING KNOWLEDGE (Demonstration purpose)
% REMEMBER: erptimes loads our time series vector in 2 ms steps (Sampling rate = 500 Hz)
% - first erptimes-datapoint = -1000 ms (500 data points)
% - last erptimes-datapoint = 1000 ms(500 data points)
erptimes % to view it in more detail, double-click the variable in the workspace

% We expect our peak to be around or response 
% --> 0 ms or 501st datapoint of erptime variable
find(erptimes==0)
erptimes(501)

% Now we want to create a variable that tells us which timepoints lie
% within our time window of interest (-100ms : 100ms).
timewin_min = -100 % datapoint 451 (or 501 - 50)
timewin_max = 100 % datapoint 551 (or 501 + 50)
% Now we take our erptime vector and compare each element with the
% following statement to see if the statement is true or false. Hereby, we
% create a new indexing vector which only contains ones at positions that
% lie within our search window of interest. 
timewindow_search = erptimes > timewin_min & erptimes < timewin_max
% timewindow: We created a time window variable with 1s and 0s (comparable
% to truth table)
% - 1s indicate timepoints within our time window of interest
% - 0s indicate timepoints outside of our time window of interest

% We create a new variable erpwindow which contains our timepoints in ms
% within our time window. In order to get to this, we use timewindow to
% INDEX erptimes 
% --> As an output we will only get those datapoints of
% erptimes at those vector positions which previously got a "1" in
% timewindow. Demonstration:
erpwindow = erptimes(timewindow_search) %in ms

% Finally, we index our ERP datapoints with our erpwindow to get the ERP
% datapoints between -100ms and +100ms
ERP_corr_timewin = ERP_corr(timewindow_search)
ERP_incorr_timewin = ERP_incorr(timewindow_search)

%find the minimum (=negative peak) within that selected range of data
[corr_min_val corr_min_time] = min(ERP_corr_timewin)
[incorr_min_val incorr_min_time] = min(ERP_incorr_timewin)

%we need to add 451 to it because corr_min_time only gives us the index
%within our selection of timepoints
%if we then look at our erptimes variable again, we get the timepoint (in
%erptimes, NOT ms) at which the minimum/peak is located
corr_min_time = erptimes(corr_min_time + 451);
incorr_min_time = erptimes(incorr_min_time + 451);

%plot the grand average: correct vs. incorrect
figure
plot(erptimes,ERP_corr','b-',erptimes,ERP_incorr','r-')
hold on
plot(corr_min_time,corr_min_val,'b*')
plot(incorr_min_time,incorr_min_val,'r*')
hold off
axis([-1000,1000,-6,6]); %define your x and y axis
legend('corr','incorr'); %this needs to correspond to the order in which you plot your variables
title('grand average') %choose a title
axis ij; %this inverts the axis (negative up, positive down)

%% find the local minima
% there is also a build-in Matlab function that allows us to detect the peak
% Find negative peak for CORRECT grand average in a 200 ms time window
% around the response (time = 0)
% !! Before localizing the peak with findpeaks we have to invert the
% !! datapoints of ERP_corr, because findpeaks only detects maxima and not
% !! minima
% !! error-related NEGATIVITY

%this will return a plot indicating the local peak
findpeaks(-1*ERP_corr(timewindow_search)',erptimes(timewindow_search)); % !!! *-1 since findpeaks only detects MAXIMA
%this will write the peak and its corresponding time point (in ms) to a variable
%pks_corr should be identical to corr_min_val
%time_corr should be identical to corr_min_time
[pks_corr,time_corr] = findpeaks(-1*ERP_corr(timewindow_search)',erptimes(timewindow_search),'SortStr', 'descend');
corr_erptime = find(erptimes == time_corr(1)); % translate time_corr (ms) to erptime index (row in erptime variable that corresponds to timepoint = 6 ms)

% Find negative peak for INCORRECT grand average in a 200 ms time window
% around the response (time = 0)
%this will return a plot indicating the local peak
findpeaks(-1*ERP_incorr(timewindow_search)',erptimes(timewindow_search)); % *-1 since findpeaks only detects MAXIMA
%this will write the peak and its corresponding time point (in ms) to a variable
%pks_incorr should be identical to incorr_min_val
%time_incorr should be identical to incorr_min_time
[pks_incorr,time_incorr] = findpeaks(-1*ERP_incorr(timewindow_search)',erptimes(timewindow_search),'SortStr','descend');
incorr_erptime = find(erptimes == time_incorr(1)); % translate locs_incorr to erptime index

%% Calculate mean amplitude for time windows (+/-20 ms or +/- 10 sample points) around the minima
timewindow_mean = [-20,20]; % ms
timewindow_mean = timewindow_mean * 0.5; % 500 samples / 1000 ms; %sampling points

% for every subject, calculate the mean amplitude for every condition 
% (time_corr +/- timewindow_mean) or (time_incorr +/- timewindow_mean)
meanmat = [];
for subj = 1:size(ERP_incong_incorr,2)
    mean_cong_corr = mean(ERP_cong_corr([corr_erptime+timewindow_mean(1):corr_erptime+timewindow_mean(2)],subj),1); %average across 1st dimension = time
    mean_cong_incorr = mean(ERP_cong_incorr([incorr_erptime+timewindow_mean(1):incorr_erptime+timewindow_mean(2)],subj),1)
    mean_incong_corr = mean(ERP_incong_corr([corr_erptime+timewindow_mean(1):corr_erptime+timewindow_mean(2)],subj),1)
    mean_incong_incorr = mean(ERP_incong_incorr([incorr_erptime+timewindow_mean(1):incorr_erptime+timewindow_mean(2)],subj),1)
    meanmat(subj,:) = [subj, mean_cong_corr, mean_cong_incorr, mean_incong_corr, mean_incong_incorr] 
end

csvwrite([PATHOUT '/meanmat.csv'],meanmat)