# **BSc-Thesis:** Effect of stimulus duration on event-related potentials during a rapid serial visual presentation task
**Author:** *Jan Sauter*

**Supervisor(s):** *René Skukies*, *Martin Geiger*

**Year:** *2025*

## Project Description
The main goal was to assess the effect of stimulus durations (100-15000 ms) in a rapid serial presentation (RSVP) task with faces as visual stimuli and no inter-stimulus intervals (ISIs).
Further the applicability of deconvolution-based overlap correction in combination with duration modelling was assessed.
Also linear and non-linear modelling approaches for the duration effect were compared and the effect of ISIs was analyzed with a control task condition where ISIs varied (800-2500 ms).
An additional analysis on a habituation effect during a stimulus sequence was conducted as well.

## Instruction for a new student

### Preprocessing
The Preprocessing script `Preprocessing_final.m` was ran on the raw data from Martin Geigers study `/store/dat/MSc_EventDuration`.
Script requirements: `function/ccs_runamica15.m` script running the amica algorithm (provided by the CCS group)

Preprocessed EEG data and corresponding event files were saved to derivative folder `/store/dat/MSc_EventDuration/derivatives/25_Jan_BSc_preprocessing/preprocessed_final` in BIDS conform format.
Due to issues with the preprocessing script the VEOGU EOG channel subjects 13, 38 were not preprocessed.

The script contains boolean values which indicate wether output should be genrated for several steps of the preprocessing, which would then be saved in the derivative folder. Final results of these outputs can be found in the following directories/files:
- Channels removed (`bad_channels/bad_channels_overview_final.csv`)
- ICA components and overview (overview: `ica/amica/ica_rejection_overview_final.csv`, individual components: `ica/amica/components_final/ica_rejection_overview_final.csv`)
- Sections marked by ASR rejection (`ASR_cleaning_final`)

The `filter_50Hz` folder also contains the output from two suspicious subjects which were saved manually

### Analysis
For the individual inspection of the ERPs from each subject, the `anaylsis_singleSubjects.jl` must be ran.
The script offers interaction feautures which allow to select a subject and channel (P7, PO7, P8, PO8, O1, O2) for inspection of the ERPs.

Analysis accross all subjects was conducted in the `analysis_group_blank.jl` for the ISI effect and `analysis_group_duration.jl` for the stimulus duration effect.
The scripts also contain interaction features which allow to choose the channel which should be visualized and toggle between task conditions regarding the cluster-depth permutation test outputs for the ISI effect analysis.
Plots used in figures were usually generated at the end of a section and then used in Affinity Designer to generate complex plots.
These complex plots are saved in the `plots` folder of this git repository.

The notebooks produce plots in the outputs from which the complex plots are generated from or can at least be retraced to.

The notebook `visualizations.jl` contains which generates visualizations for the stimulus duration and ISI duration distributions, which were also used in the `task.png` figure.
`visualizations.ipynb` contains code in order to generate visualizations of removed channels.

## Overview of Folder Structure 

```
│projectdir          <- Project's main folder. It is initialized as a Git
│                       repository with a reasonable .gitignore file.
│
├── report           <- **Immutable and add-only!**
│   ├── proposal     <- Proposal PDF
│   ├── thesis       <- Final Thesis PDF
│   ├── talks        <- PDFs (and optionally pptx etc) of the Intro,
|   |                   Midterm & Final-Talk
|
├── _research        <- WIP scripts, code, notes, comments,
│   |                   to-dos and anything in an alpha state.
│
├── plots            <- All exported plots go here, best in date folders.
|   |                   Note that to ensure reproducibility it is required that all plots can be
|   |                   recreated using the plotting scripts in the scripts folder.
|
├── notebooks        <- Pluto, Jupyter, Weave or any other mixed media notebooks.*
│
├── scripts          <- Various scripts, e.g. simulations, plotting, analysis,
│   │                   The scripts use the `src` folder for their base code.
│
├── src              <- Source code for use in this project. Contains functions,
│                       structures and modules that are used throughout
│                       the project and in multiple scripts.
│
├── test             <- Folder containing tests for `src`.
│   └── runtests.jl  <- Main test file
│   └── setup.jl     <- Setup test environment
│
├── README.md        <- Top-level README. A fellow student needs to be able to
|   |                   continue your project. Think about her!!
|
├── .gitignore       <- focused on Julia, but some Matlab things as well
│
├── (Manifest.toml)  <- Contains full list of exact package versions used currently.
|── (Project.toml)   <- Main project file, allows activation and installation.
└── (Requirements.txt)<- in case of python project - can also be an anaconda file, MakeFile etc.
                        
```

\*Instead of having a separate *notebooks* folder, you can also delete it and integrate your notebooks in the scripts folder. However, notebooks should always be marked by adding `nb_` in front of the file name.
