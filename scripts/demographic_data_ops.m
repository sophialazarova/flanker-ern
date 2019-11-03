PATHIN = ['/Users/sophia/Desktop/uni/eeg/stats'];
parsedData = readmatrix([PATHIN '/participants_data.csv']);

% .csv legend
% age|gender|handness|vision
% 1-female, 2-male
% 1-right, 2-left
% 1-none, 2-glasses, 3-lenses

demData = parsedData(:,:);

%mean and standard deviation of age
meanAge = mean(demData(:,1))
stdAge = std(demData(:,1))

%count male and female participants
dataSize=size(demData(:,1));
genderCol = demData(:,2);
femaleCount=0;
maleCount=0;
for i=1:dataSize(1)
    if genderCol(i) == 1
        femaleCount = femaleCount + 1;
    else
        maleCount = maleCount + 1;
    end
        
end

%Calculate percentage
femalePercentage = femaleCount/dataSize(1)*100;
malePercentage = maleCount/dataSize(1)*100;


