%% Setup

close all; clear; clc;

% Start EEGLAB
addpath '/store/users/geiger/plugins/matlab/eeglab2025.0.0'
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;

% Install plugins
plugin_askinstall('bva-io','pop_loadbv',1)
plugin_askinstall('iclabel','pop_iclabel',1)
plugin_askinstall('clean_rawdata','pop_clean_rawdata',1)
plugin_askinstall('amica','pop_amica',1)
plugin_askinstall('firfilt','',1)
plugin_askinstall('dipfit','',1)
plugin_askinstall('BIDS-matlab-tools','pop_importbids',1)
plugin_askinstall('viewprops','pop_prop_extended',1)
plugin_askinstall('zapline-plus','',1)
% Additionally required - installed manually: zapline, unfold
run('/store/users/geiger/plugins/matlab/unfold/init_unfold.m')

% Control structure
cfg = struct();

% Paths
cfg.filepath_in  = '/store/data/MSc_EventDuration'; % Path to BIDS files
cfg.filepath_out = '/store/data/MSc_EventDuration/derivatives/25_Jan_BSc_preprocessing'; % Output path for preprocessed data
addpath './functions'
addpath './tmp'

%% Load Data

% Subjectlists for each experiment
%subjectsOddball  = [4 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41];
%subjectsDuration = [1 2 3 4 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 27 28 29 30 31 32 33 34 35 37 38 39 40 41];
subjects = [1];
task = 'Duration'; % Either 'Oddball' or 'Duration'
ALLEEG = [];
CURRENTSTUDY = 0;

% Call BIDS tool BIDS
for subject = subjects
    filename = sprintf('sub-%03i_ses-001_task-%s_run-001_eeg.set',subject,task);
    EEG = pop_loadset('filepath',[cfg.filepath_in,sprintf('/sub-%03i/ses-001/eeg/',subject)],'filename',filename);

    % Remove channel 65 (sample number)
    EEG.data(65,:) = [];
    EEG.chanlocs(65) = [];
    EEG.nbchan=64;

    % Add columns that are missing since I couldn't load it with pop_importbids
    EEG.subject = sprintf('sub-%03i',subject);
    EEG.session = 1;
    EEG.task = task;

    % Load events
    tsv = tdfread(fullfile(cfg.filepath_in,sprintf('sub-%03i/ses-001/eeg/sub-%03i_ses-001_task-%s_run-001_events.tsv',subject,subject,task)));
    EEG.event = struct2table(tsv);
    EEG.event = renamevars(EEG.event,["sample","trial_type"],["latency","type"]); % Rename variables
    EEG.event = struct2table(table2struct(EEG.event)); % Strange but doesn't work otherwise.
    EEG.event.type = deblank(EEG.event.type);
    EEG.event = table2struct(EEG.event);

    % Copy to ALLEEG
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, 0);
end

EEG = pop_select(EEG, 'nochannel', {'VEOG','HEOG'});
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);


%% Load Channel locations
for s = 1:length(ALLEEG)
    % Loading standard file
    ALLEEG(s) = pop_chanedit(ALLEEG(s), 'lookup','Standard-10-5-Cap385.sfp');
    ALLEEG(s).urchanlocs = ALLEEG(s).chanlocs;
end

%% Downsample to 250 Hz
cfg.srate = 250; % sampling rate used for downsampling

ALLEEG = pop_resample(ALLEEG,cfg.srate);

%% Remove 50 Hz line noise
for s = 1:length(ALLEEG)
    ALLEEG(s) = clean_data_with_zapline_plus_eeglab_wrapper(ALLEEG(s),struct('noisefreqs',50));
end

%% Remove bad channels
rng(1) % Fix random

ALLEEG = pop_clean_rawdata(ALLEEG, ...
    'FlatlineCriterion', 5, ...
    'ChannelCriterion', 0.8, ...
    'LineNoiseCriterion', 4, ...
    'Highpass', [0.25 0.75], ...
    'BurstCriterion', 'off', ...
    'WindowCriterion', 'off', ...
    'BurstRejection', 'off', ...
    'Distance', 'Euclidian', ...
    'WindowCriterionTolerances', 'off');

%% Get removed channels and save them to CSV file

% Initialize result storage
results = cell(length(ALLEEG), 2);

% List of all removed channels for later visualization
allRemovedChannels = {};

for s = 1:length(ALLEEG)

    EEG = ALLEEG(s);
    
    % Get the removed channel names
    if isfield(EEG.etc, 'clean_channel_mask')
        removedChannels = EEG.urchanlocs(~EEG.etc.clean_channel_mask);
        removedChannelNames = {removedChannels.labels};
    else
        removedChannelNames = {};
    end

    removedStr = strjoin(removedChannelNames, ', '); % Convert removed channels to string seperated by commata
    results{s, 1} = EEG.subject;
    results{s, 2} = removedStr;

    allRemovedChannels = [allRemovedChannels, removedChannelNames];
end

disp(results)

T = cell2table(results, 'VariableNames', {'Subject', 'RemovedChannels'});

folderpath = fullfile(cfg.filepath_out, 'bad_channels');

% Create 'bad_channels' folder in derivatives folder if not existent
if ~exist(folderpath, 'dir') 
    mkdir(folderpath);
end

% Save results as CSV
writetable(T, fullfile(folderpath,'bad_channels_overview.csv'));

%% Rereference using average reference
ALLEEG = pop_reref( ALLEEG,[],'interpchan',['off']);

%% Remove large spikes
ALLEEG_pre = ALLEEG; % in order to compare EEG before and after removal

for s = 1:length(ALLEEG)
    EEG = ALLEEG(s);

    winRej = uf_continuousArtifactDetect(EEG,'amplitudeThreshold',1000);
    EEG = eeg_eegrej(EEG, winRej);
    EEG.etc.crap_winrej = winRej;

    % Rewrite eeg data with removed spikes to ALLEEG variable
    ALLEEG(s) = EEG;
end

%% Compare cleaned data to the original
%subject = 2;
%vis_artifacts(ALLEEG(subject),ALLEEG_pre(subject));

%% Run amica ICA algorithm
cfg.recalculate_ica = false; % Flag wether ica weights should be recalculated

if cfg.recalculate_ica
    for s = 1:length(ALLEEG)
        
        % Filter temporary at 1.5 Hz
        EEG = ALLEEG(s);
        EEG = pop_eegfiltnew(EEG, 'locutoff',1.5);
        
        % Define parameters
        numprocs    = 1;    % 2 is to use t-mux in a parallel implementation
        max_threads = 1;    % Number of threads
        num_models  = 1;    % Number of models of mixture ICA
        max_iter    = 1000; % Max number of learning steps
        
        % Specify output directory for amica ica algorithm
        out_directory = fullfile(cfg.filepath_out,'ica','amica','weights',EEG.subject,filesep);
        % Create directory if it doesn't exist already
        if ~exist(out_directory, 'dir') 
            mkdir(out_directory);
        end
        
        % Todo Use AMICA, with automatic data rejection
        ccs_runamica15(double(EEG.data), ...
            'num_models',num_models, 'outdir',out_directory, ...
            'numprocs', numprocs, 'max_threads', max_threads, ...
            'max_iter',max_iter, 'do_reject', 1, 'pcakeep',size(EEG.data,1)-1,'tmpdir','./tmp/');
    
    end
end

%% Load amica ICA weights and remove bad components

for s = 1:length(ALLEEG)

    EEG = ALLEEG(s);
    
    out_directory= fullfile(cfg.filepath_out,'ica','amica', 'weights',EEG.subject,filesep);
    %disp(out_directory)

    % Load amica weights
    mods = loadmodout15(out_directory);

    % Apply temporary ica filter of 1.5 Hz again
    EEGica = pop_eegfiltnew(EEG, 'locutoff',1.5);

    % Load amica weights
    model_index = 1;
    EEGica.icawinv = mods.A(:,:,model_index);
    EEGica.icaweights = mods.W(:,:,model_index);
    EEGica.icasphere = mods.S(1:size(mods.W,1),:);
    EEGica.icachansind = 1:size(EEGica.data,1);

    % Check eeg data consistency
    EEGica = eeg_checkset(EEGica);

    % Make IC Label classifications
    EEGica = pop_iclabel(EEGica,'default');

    % Define selection threshold for component categories
    % (components with probability >80% non-braincomponents)
    EEGica = pop_icflag(EEGica,[NaN NaN;0.8 1;0.8 1;0.8 1;0.8 1;0.8 1;0.8 1]);

    % Visualize ICA components
    % Create directory for component outputs
    components_directory = fullfile(cfg.filepath_out, 'ica', 'amica', 'components', EEGica.subject);
    if ~exist(components_directory, 'dir') 
            mkdir(components_directory);
    end

    %Visualize components for subject s and save as PNG
    for component = 1:size(EEGica.icawinv, 2)
        % Visualize component
        figure = pop_prop_extended(EEGica, 0, component, NaN, {'freqrange', [1 80]}, {'erp', 'on'}, 0, 'ICLabel');

        % Save visualization as PNG
        saveas(figure, fullfile(components_directory, sprintf('%s_IC-%03i.png', EEGica.subject, component)));

        % Close figure to avoid clutter
        close(figure);
    end
    
    % Copy over ICA values to unfiltered EEG
    EEG.icaweights = EEGica.icaweights;
    EEG.icawinv = EEGica.icawinv;
    EEG.icasphere = EEGica.icasphere;
    EEG.icachansind = EEGica.icachansind;
    EEG.reject.gcompreject = EEGica.reject.gcompreject;
    EEG.etc.ic_classifications.ICLabel = EEGica.etc.ic_classification.ICLabel;
    EEG.etc.comp_rejected = find(EEGica.reject.gcompreject);
    
    % Remove rejected ICA components
    EEG = pop_subcomp(EEG, find(EEG.reject.gcompreject), 0);

    ALLEEG(s) = EEG;
end

%% Generate overview of removed ICA components

% ICLabel classes (order from ICLabel output)
%classes = {'Brain', 'Muscle', 'Eye', 'Heart', 'Line Noise', 'Channel Noise', 'Other'};
classes = EEGica.etc.ic_classification.ICLabel.classes;

% Initialize table storage
nSubjects = numel(ALLEEG);
summary = cell(nSubjects, numel(classes)+1); % +1 for subject column

for s = 1:nSubjects
    % Subject ID
    summary{s,1} = ALLEEG(s).subject;

    % Get rejected components for this subject
    rejICs = ALLEEG(s).etc.comp_rejected;

    % Get ICLabel classifications
    if isfield(ALLEEG(s).etc.ic_classifications, 'ICLabel')
        iclabels = ALLEEG(s).etc.ic_classifications.ICLabel.classifications; % nICs x 7 matrix
        [~, maxclass] = max(iclabels, [], 2); % class index per IC
    else
        error('ICLabel results not found in EEG(%d)', s);
    end

    % Fill class columns
    for c = 1:numel(classes)
        % Find rejected ICs that belong to this class
        compIdx = rejICs(maxclass(rejICs) == c);

        % Store as a string list, e.g., "2, 5, 7"
        if isempty(compIdx)
            summary{s,c+1} = '';
        else
            summary{s,c+1} = strjoin(string(compIdx), ', ');
        end
    end
end

% Convert to table
colNames = [{'Subject'}, classes];
T = cell2table(summary, 'VariableNames', colNames);

% Save as CSV
outFile = fullfile(cfg.filepath_out, 'ica', 'amica','ica_rejection_overview.csv');
writetable(T, outFile);

disp(['Overview saved to: ' outFile]);


%% Continuous ASR rejection
% reset seed
rng(1)

% replace the above rawdata with uf_artifacexcludeASR ????
for s = 1:length(ALLEEG)

    EEG = ALLEEG(s);

    EEG.etc.uf_winrej = uf_continuousArtifactDetectASR(EEG,'channel',find({EEG.chanlocs.type} == "EEG"),'cutoff',20,'tolerance',1e-5);
    
    fPath = fullfile(cfg.filepath_out,'ASRcleaning',EEG.subject);
    if ~exist(fPath,'dir')
        mkdir(fPath);
    end

    writematrix(EEG.etc.uf_winrej,fullfile(fPath,[EEG.subject '_desc-ASRCleaningTimes.tsv']),'Delimiter','tab','FileType','text')

    ALLEEG(s) = EEG;
end

%% Interpolate Bad Channel
for s = 1:length(ALLEEG)
    EEG = ALLEEG(s);

    EEG = pop_interp(EEG, EEG.urchanlocs, 'spherical');

    ALLEEG(s) = EEG;
end

%% Highpass-Filter data
ALLEEG = pop_eegfiltnew(ALLEEG, 'locutoff',0.1);

%% Checkset and save data
ALLEEG = eeg_checkset(ALLEEG);

%% Save preprocessed EEG data
for s = 1:length(ALLEEG)
    EEG = ALLEEG(s);
    EEG.filepath = fullfile(cfg.filepath_out,'/preprocessed/',EEG.subject,'eeg');
    if ~exist(EEG.filepath,'dir')
        mkdir(EEG.filepath);
    end

    ALLEEG(s) = EEG;
end

ALLEEG = pop_saveset(ALLEEG, 'savemode', 'resave');


%% Write events files
for s = 1:length(ALLEEG)
    EEG = ALLEEG(s);

    EEG.filepath = fullfile(cfg.filepath_out,'/preprocessed/',EEG.subject,'eeg');
    if ~exist(EEG.filepath,'dir')
        mkdir(EEG.filepath);
    end

    % Define output path
    fileOut = fullfile(EEG.filepath, sprintf('%s_ses-001_task-%s_run-001', EEG.subject, task));

    disp(fileOut)

    % Save events in BIDS format
    bids_writeeventfile(EEG, fileOut, 'omitsample', 'off');

end
