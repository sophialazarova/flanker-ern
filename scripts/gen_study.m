%====================================================================
% EEG Seminar & Practical Klatt, Reiser, Hucke                         
%=====================================================================
% This script serves as a substitute for manually creatig the study by
% uploading every single subject. Secondly, the 2x2 study design is created
% with factors 'accuracy' (incorrect,correct) and 'congruency' (congruent,incongurent).
close all; clear all;

PATHIN = ['/Users/sophia/Desktop/uni/eeg/report_preprocessing']; % filepath where you load your data from
PATHOUT = ['/Users/sophia/Desktop/uni/eeg/study']; % filtepath where processed files will be stored to
EEGLAB_PATH = ['/Users/sophia/sotfware/eeglab14_1_2b'];
SUBJECT = {'VP_01','VP_02','VP_03','VP_04','VP_05','VP_06','VP_07','VP_08','VP_09','VP_10','VP_11','VP_13','VP_14','VP_15'};


[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
% load datasets into study

%this will look a little different if you do it via the gui - but it is
%more elegant using a loop
indexcount = 1;
for s = 1:length(SUBJECT)
    [STUDY ALLEEG] = std_editset( STUDY, ALLEEG, 'commands',{ ...
       {'index' indexcount 'load' [PATHIN '/' SUBJECT{s} '_pruned_resplock.set'] 'subject' [SUBJECT{s}] }});
    indexcount = indexcount + 1;
end %sub

eeglab redraw;

% define study-parameters
% here we define which variables from our EEG.event structures we want to
% be considered within our STUDY design
STUDY = std_makedesign(STUDY, ALLEEG, 1, 'variable1','corr','variable2','cong','name','Flanker', ...
    'pairing1','on','pairing2','on','delfiles','off','defaultdesign','off','values1',{'corr','incorr'},'values2',{'cong','incong'},'subjselect',{SUBJECT},...
    'filepath', PATHOUT);

%calculate the ERPs based on our STUDY design
%you get a .daterp file for every combination of our STUDY variables (i.e.
%corr and cong)
[STUDY ALLEEG] = std_precomp(STUDY, ALLEEG, {},'interp','on','recompute','on','erp','on'); 

%save STUDY
[STUDY ALLEEG] = pop_savestudy(STUDY, 'filepath', [PATHOUT],'filename', 'FLANKER_STUDY');

%NOTE: if you want to work with the STUDY gui after running this script you
%will have to reload the STUDY into EEGLAB manually