PATHOUT = ['/Users/sophia/Desktop/uni/eeg/stats'];

%% Setup the Import Options
opts = delimitedTextImportOptions("NumVariables", 7);

% Specify range and delimiter
opts.DataLines = [1, Inf];
opts.Delimiter = [",", ";"];

% Specify column names and types
opts.VariableNames = ["Var1", "Var2", "congruency", "Var4", "accuracy", "RT", "subject"];
opts.SelectedVariableNames = ["congruency", "accuracy", "RT", "subject"];
opts.VariableTypes = ["string", "string", "double", "string", "double", "double", "categorical"];
opts = setvaropts(opts, [1, 2, 4], "WhitespaceRule", "preserve");
opts = setvaropts(opts, [1, 2, 3, 4, 7], "EmptyFieldRule", "auto");
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Import data

Flankermerged = readtable("/Users/sophia/Desktop/uni/eeg/Flanker_merged.csv", opts);

% Segment data by subject
VP_01 = Flankermerged(1:400,1:3);
VP_02 = Flankermerged(401:800,1:3);
VP_03 = Flankermerged(801:1200,1:3);
VP_04 = Flankermerged(1201:1600,1:3);
VP_05 = Flankermerged(1601:2000,1:3);
VP_06 = Flankermerged(2001:2400,1:3);
VP_07 = Flankermerged(2401:2800,1:3);
VP_08 = Flankermerged(2801:3200,1:3);
VP_09 = Flankermerged(3201:3600,1:3);
VP_10 = Flankermerged(3601:4000,1:3);
VP_11 = Flankermerged(4001:4400,1:3);
VP_13 = Flankermerged(4401:4800,1:3);
VP_14 = Flankermerged(4801:5200,1:3);
VP_15 = Flankermerged(5201:5600,1:3);

%% Clear temporary variables
clear opts

% get average values for cong_corr, cong_incorr, incong_corr, incong_incorr
% trials for each participant

rtTable = [];
rtTable(1,:) = getGrandAverage(VP_01);
rtTable(2,:) = getGrandAverage(VP_02);
rtTable(3,:) = getGrandAverage(VP_03);
rtTable(4,:) = getGrandAverage(VP_04);
rtTable(5,:) = getGrandAverage(VP_05);
rtTable(6,:) = getGrandAverage(VP_06);
rtTable(7,:) = getGrandAverage(VP_07);
rtTable(8,:) = getGrandAverage(VP_08);
rtTable(9,:) = getGrandAverage(VP_09);
rtTable(10,:) = getGrandAverage(VP_10);
rtTable(11,:) = getGrandAverage(VP_11);
rtTable(12,:) = getGrandAverage(VP_13);
rtTable(13,:) = getGrandAverage(VP_14);
rtTable(14,:) = getGrandAverage(VP_15);

csvwrite([PATHOUT '/rt_meanmat.csv'],rtTable)

function row = getGrandAverage(subjectData)
    cong_incorr = [];
    cong_corr = [];
    incong_corr = [];
    incong_incorr = [];
    for i=1:400
        if subjectData{i,1} == 1 && subjectData{i,2} == 1
            currentIndex = size(cong_corr)+1;
            cong_corr(currentIndex) = subjectData{i,3};
        elseif subjectData{i,1} == 1 && subjectData{i,2} == 0
            currentIndex = size(cong_incorr)+1;
            cong_incorr(currentIndex) = subjectData{i,3};
        elseif subjectData{i,1} == 0 && subjectData{i,2} == 0
            currentIndex = size(incong_incorr)+1;
            incong_incorr(currentIndex) = subjectData{i,3};
        elseif subjectData{i,1} == 0 && subjectData{i,2} == 1
            currentIndex = size(incong_corr)+1;
            incong_corr(currentIndex) = subjectData{i,3};
        end
    end
    
    row = [mean(cong_corr) mean(cong_incorr) mean(incong_corr) mean(incong_incorr)];
end