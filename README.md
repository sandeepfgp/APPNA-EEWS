![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)
# APPNA-EEWS
Automatic P-wave Picker Next-gen Algorithm for Earthquake Early Warning System

## APPNA_Algorithm_rec.m 
This is  a MATLAB implementation of the APPNA Algorithm for detecting P-wave arrivals from seismic signals in an offline processing mode. The algorithm processes seismic data files (*.dat),  and identifies P-wave onset.

### 📂 Input & Output
#### Input
- Folder containing `.dat` files with raw seismic waveform data. For examples see the folder **sample_waveform** 
- Each file should be a single-column numeric array.
#### Output
1. **Summary CSV**  
 - File: `pwave_summary_IQR_Weighted_MAD_RMS.csv`  
 - Columns:  
   - `Filename` — processed file  
   - `PwaveArrival_iqr` — detected arrival (seconds, NaN if not found)  
   - `Threshold_iqr` — adaptive IQR threshold  
   - `NoiseLevel` — weighted MAD + RMS noise estimate  
   - `Timestamp` — processing time  

2. **Diagnostic Plots (per file)**  
 - **Filtered waveform** with vertical line at detected P-wave  
 - **Envelope with adaptive threshold** and detected P-wave marker 
  
### ⚡ Usage
1.	Set file path in the script by updating the folder_path variable.
2.	Run the script. It will process all .dat files in the folder and save a summary .csv in the same folder.
3.	Optional: Uncomment the plotting section at the end of the script to visualize envelope, threshold, and detected P-wave arrival.
### 🛠️ Requirements
- MATLAB R2018a or later
- Signal Processing Toolbox
- Statistics and Machine Learning Toolbox
- Curve Fitting Toolbox

### 📜 License
#This project is licensed under the GNU Affero General Public License v3.0 (AGPL-3.0).





