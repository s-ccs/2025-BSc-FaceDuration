# **BSc-Thesis:** Effect of stimulus duration on event-related potentials during a rapid serial visual presentation task
**Author:** *Jan Sauter*

**Supervisor(s):** *René Skukies*, *Martin Geiger*

**Year:** *2025*

## Project Description
The main goal was to assess the effect of stimulus durations (100-15000 ms) in a rapid serial presentation (RSVP) task with faces as visual stimuli and no inter-stimulus intervals (ISIs).
Further the applicability of deconvolution-based overlap correction in combination with duration modelling was assessed.
Also linear and non-linear modelling approaches for the duration effect were compared and the effect of ISIs was analyzed with a control task condition where ISIs varied (800-2500 ms).
An additional analysis on a habituation effect during a stimulus sequence was conducted as well.

## Zotero Library Path
>Please provide the link to the Zotero group here or include a `Bib`-File in the `report` folder

## Instruction for a new student

Preprocessing:

Analysis:


>If a fellow student wants to reproduce all your results. What scripts, in which order, with which data need to be run?
>
>Be as specific as possible. Plan to spend **at least 1h** on this.
>
>Optional: Add a pipeline plot in which the different steps are displayed together with the corresponding scripts.

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
