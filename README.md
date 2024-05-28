Graphical User Interface for Preprocessing Near Infrared Spectroscopy Data

The purpose of this repository is to implement an interface for running preprocessing pipelines for fNIRS data (it uses mainly homer3 data preprocessing functions) in an efficient way and, mainly, a graphical user interface (GUI) through which one can adjust pipeline parameters, compare pipelines, do manual cleaning and artifact detection/removal and, in general, get a good handle of the data. 

## Why another tool for fNIRS preprocessing?

Compared to other GUIs it has advantages:
- It is performant, eg it contains minor tweeks that allow it run on multiple cores, which most modern machines allow.
- It allows visualisation of the data transformation in different stages of a preprocessing pipeline (thus better handle of testing a new pipeline or tweeking parameters)
- It allows easy and visual manual removal of stimuli or rejecting noisy channels.
- Because it does one thing (preprocessing) and not many (preprocessing, averaging, analysis etc) it is simpler and can allocate complexity to improving the preprocessing interface. You preprocess the data here, export it to a snirf file and import it to your favourite toolbox for analysis.

Features that are only partially supported for now but are intended to be fully supported as such:
- It is intended to be easily called and run without the GUI (once a pipeline has been crystalised) through the command line or a batch script, eg on a cluster.
- Elements of the GUI are meant to be easily tweeked and adjusted to each specific experiment's needs, instad having a one-fit-all interface.

## License and disclaimers

Two directories contain code borrowed from third parties (copyright belongs to respective parties)
- The snirf files in `data/single_device_finger_tapping` belong to Artinis Medical Systems (from https://github.com/Artinis-Medical-Systems-B-V/snirf_data_example)
- src/external contains code written by others that may or may not have been lightly modified. See licenses in the specific subfolders for appropriate copyrights.
    - We include a copy of Homer3 in `src/external/antihommer`, with minor fixes and changes (BSD licensed, https://github.com/BUNPC/Homer3).

Otherwise, the rest of the repository is BSD licensed.
