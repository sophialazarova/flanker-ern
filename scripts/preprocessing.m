% =========================================================================
% Preprocessing of the acquired data from the EEG recording sessions.
% - delete practice trials
% - edit channel info (channel names assigned to scalp coordinates)
% - filter non-useful frequencies (high and low filter, freqs that do not represent cognitive function)
% - reject noisy channels
% - epoch data 
% - ICA
% - ADJUST eye movement/discontinuties removal (rejection of  artifact components)
% - DIPFIT dipole-based rejection of components
% - interpolation
% - re-epoch to responses
% =========================================================================

close all; clear all;

PATHIN = ['/Users/sophia/Desktop/uni/eeg/raw_data'];
PATHOUT = ['/Users/sophia/Desktop/uni/eeg/report_preprocessing'];
PATHSTATS = ['/Users/sophia/Desktop/uni/eeg/report_preprocessing'];
EEGLAB_PATH = ['/Users/sophia/sotfware/eeglab14_1_2b'];
SUBJECT = {'VP_01','VP_02','VP_03','VP_04','VP_05','VP_06','VP_07','VP_08','VP_09','VP_10','VP_11','VP_13','VP_14','VP_15'};

DipFit_crit=0.4; %criterion for dipole fit function: every signal components with residual variance higher than 40% (0.4) will be removed from data

[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
subcount = 1;

for subj = 1:length(SUBJECT)                                                  

    EEG = pop_loadset(['Flanker_' SUBJECT{subj}, '.set'], PATHIN);
    VP = SUBJECT{subj};
    EEG = eeg_checkset(EEG, 'eventconsistency');

    %% Remove practice trials
    EEG=letterkilla(EEG); 
    practicecount = 0;

    for i = 1:length(EEG.event)
        if any(ismember(EEG.event(i).type,[11,12,21,22])) %check if current event i corresponds to stimulus trigger
            practicecount = practicecount + 1;
        end
        if practicecount == 11 % experimental block starts with trigger event 11
            practiceend = i;
            break
        end
    end 

    EEG.event(1:practiceend-1) = [];
    EEG = eeg_checkset(EEG, 'eventconsistency');
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

    %% Edit channel info
    % Assigning channels to coordinates across the scalp
    EEG=pop_chanedit(EEG, 'lookup',[EEGLAB_PATH '/plugins/dipfit3.0/standard_BESA/standard-10-5-cap385.elp']);
    EEG = eeg_checkset(EEG, 'eventconsistency');
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

    %% Filter data
    % Filter out non-useful frequencies in signal
    EEG = pop_eegfiltnew(EEG,'locutoff',0.5,'hicutoff',30); %high-pass filer 0.5 Hz, low-pass filter 30 Hz
    EEG = pop_saveset(EEG,'filename',[VP '_filter.set'],'filepath',PATHOUT);
    EEG = eeg_checkset( EEG, 'eventconsistency' );

    %% Reject bad channels
    % Remove noisy channels and re-reference to average again.
    chanlocs=EEG.chanlocs;
    [EEG,indelec] = pop_rejchan(EEG,'elec',[1:EEG.nbchan], 'threshold',5,'norm','on','measure','kurt'); % reject channels based on kurtosis (a procedure to detect inconsistencies)
    num_rejcount(subcount,1) = length(indelec);
    EEG = pop_reref( EEG, [] );

    % Summarize rejected channels of all participants.
    Bad={'none'};
    for h=1:length(indelec)
        Bad{h}=chanlocs([indelec(h)]).labels;
    end

    BadChans{subj,:}=Bad;

    %% Calculate response time
    EEG=letterkilla(EEG); % removes letters from triggers (S201 -> 201)

    for i = 1:length(EEG.event)
        if any(ismember(EEG.event(i).type,[11,12,21,22]))
            if any(ismember(EEG.event(i+1).type,[111,211,212,112,221,121,222,122]))
                EEG.event(i).rt = EEG.event(i+1).latency - EEG.event(i).latency;
            end
        end
    end

    EEG = eeg_checkset( EEG, 'eventconsistency' );

    %% Epoch data
    % Signal should be seperated into trials. We define every possible stimulus
    % trigger (11,12,21,22); eeglab will just ignore triggers which are not part of the dataset
    EEG = pop_epoch( EEG, {'11','12','21','22'}, [-1 2], 'newname', [VP '_epochs_stim'], 'epochinfo', 'yes'); % time range of epoch is define in secons referred to the respective trigger
    EEG = eeg_checkset( EEG, 'eventconsistency' );
    EEG = pop_rmbase( EEG, [-200 0]); % baseline correction: usually 500 or 200 ms before the onset of the first stimulus trigger
    EEG = eeg_checkset(EEG);
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

    % Trial rejection. Reject single trials with large signal fluctuations (1000 mV within one trial)
    [EEG rmepochs] = pop_autorej(EEG, 'nogui','on','threshold',1000,'startprob',5,'maxrej',5);
    num_rejcount(subcount,2) = length(rmepochs);

    %% Independent component analysis (ICA)
    % Decomposes signal into independent "sources" which allow us to easily identify artifacts 
    % (blinks, noisy electrodes, vertical eye movements, muscle artifacts...)
    % Largest possible number of components is the number of channels.
    % Actually with an average reference we are conducting a principal
    % component analysis with a limited number of components to channels-1.
    % Average reference brings dependence into our data
    EEG = pop_runica(EEG, 'extended',1,'interupt','on','pca',EEG.nbchan-1);
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    EEG = eeg_checkset( EEG );
    EEG=pop_saveset(EEG,'filename',[VP '_IC.set'],'filepath',PATHOUT);

    %% Artifact rejection procedures
    % ADJUST for automatic rejection of artifact ICs  containing eye
    % movements or discontinueties.
    eeglab redraw; % there might be a bug with the ADJUST plugin, so just in case
    [art,horiz,vert,blink,disc] = ADJUST(EEG,[PATHOUT '/' VP '_ad.txt']);
    
    % Rejection of ICs depending on dipoles (Dipfit).
    % Estimatimates dipoles (localization of signal source) and excludes ICs whose dipoles are 
    % estimated to be located outside of the brain or have high residual
    % variance.
    EEG = pop_dipfit_settings(EEG, 'hdmfile', [EEGLAB_PATH '/plugins/dipfit2.3/standard_BESA/standard_BESA.mat'],...
        'coordformat', 'Spherical',...
        'mrifile', [EEGLAB_PATH '/plugins/dipfit2.3/standard_BESA/avg152t1.mat'],...
        'chanfile', [EEGLAB_PATH '/plugins/dipfit2.3/standard_BESA/standard-10-5-cap385.elp'],...
        'chansel', [1 : EEG.nbchan]); % As we rejected bad channels a few steps before, each dataset has a different num of channels, thus it is desirable to use a variable instead of a fixed channel number.

    % Estimates the source location of the signal in each IC
    EEG = pop_multifit(EEG, [1 : EEG.nbchan], 'threshold', 100, 'dipplot', 'off', 'plotopt', {'normlen' 'on'});

    % Remove artifact ICs resulting from ADJUST function
    EEG = pop_subcomp( EEG, art, 0);
    EEG = eeg_checkset( EEG );
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

    art_dipfit = [];
    art_comp = 0;
    for i = 1: length(EEG.dipfit.model)
        if EEG.dipfit.model(i).rv > DipFit_crit %we defined DipFit_crit at the very beginning of this script
            art_comp = art_comp + 1;
            art_dipfit(art_comp) = i;
        end;
    end;

    % remove artifact ICs dependend on dipole fit (art_dipfit)
    EEG = pop_subcomp( EEG, art_dipfit, 0);
    EEG = eeg_checkset( EEG );
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);


    % Interpolate (re-calculate from surrounding electrodes' signal) the
    % signal of the channels we removed at the beginning of the script.
    EEG = eeg_interp(EEG,chanlocs, 'spherical');

    EEG=pop_saveset(EEG,'filename',[VP '_pruned_stimlock.set'],'filepath',PATHOUT);

    %% Re-epoch data to responses
    EEG = pop_epoch( EEG, {'111','211','212','112','221','121','222','122'}, [-1  1], 'newname', [VP '_epochs_resp'], 'epochinfo', 'yes'); % time range of epoch is define in secons referred to the respective trigger
    EEG = letterkilla(EEG);

    for i = 1:length(EEG.event)
        if EEG.event(i).type == 111 & EEG.event(i-1).type == 11
            EEG.event(i).corr = 'corr'; %correct
            EEG.event(i).cong = 'cong'; %congruent
            EEG.event(i).code = 'Response';
        elseif EEG.event(i).type == 211 & EEG.event(i-1).type == 11
            EEG.event(i).corr = 'incorr'; %incorrect
            EEG.event(i).cong = 'cong'; % congruent
            EEG.event(i).code = 'Response';
        elseif EEG.event(i).type == 212 & EEG.event(i-1).type == 12
            EEG.event(i).corr = 'corr'; %correct
            EEG.event(i).cong = 'cong'; %congruent
            EEG.event(i).code = 'Response';
        elseif EEG.event(i).type == 112 & EEG.event(i-1).type == 12
            EEG.event(i).corr = 'incorr'; %incorrect
            EEG.event(i).cong = 'cong'; %congruent
            EEG.event(i).code = 'Response';
        elseif EEG.event(i).type == 221 & EEG.event(i-1).type == 21
            EEG.event(i).corr = 'incorr'; %incorrect
            EEG.event(i).cong = 'incong'; %incongruent
            EEG.event(i).code = 'Response';
        elseif EEG.event(i).type == 121 & EEG.event(i-1).type == 21
            EEG.event(i).corr = 'corr'; %correct
            EEG.event(i).cong = 'incong'; %incongruent
            EEG.event(i).code = 'Response';
        elseif EEG.event(i).type == 222 & EEG.event(i-1).type == 22
            EEG.event(i).corr = 'corr'; %correct
            EEG.event(i).cong = 'incong'; %incongruent
            EEG.event(i).code = 'Response';
        elseif EEG.event(i).type == 122 & EEG.event(i-1).type == 22
            EEG.event(i).corr = 'incorr'; %incorrect
            EEG.event(i).cong = 'incong'; %incongruent
            EEG.event(i).code = 'Response';
        else
            EEG.event(i).corr = 'none'; %incorrect
            EEG.event(i).cong = 'none'; %incongruent
        end
    end % length(EEG.event)

    EEG = eeg_checkset( EEG );
    EEG=pop_saveset(EEG,'filename',[SUBJECT{subj} '_pruned_resplock.set'],'filepath',PATHOUT);

end;

csvwrite([PATHSTATS '/num_rejcount.csv'], num_rejcount);

eeglab redraw; % necessary after running script-based commands
