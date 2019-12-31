#!/bin/bash


# Pilot A: Nika
wget --output-document=data_nika_human.csv "https://github.com/n-ika/abx_test_strut/blob/6313434aa7f27677428940e1d7de73fe6da8a488/analysis/outputs/analysed_data_FINALstim.csv?raw=true"
wget --output-document=data_nika_bottleneck.csv "https://github.com/n-ika/abx_test_strut/blob/6313434aa7f27677428940e1d7de73fe6da8a488/model/unsupervised/bottleneck/distances_bottleneck.csv?raw=true"
wget --output-document=data_nika_mfcc.csv "https://github.com/n-ika/abx_test_strut/blob/6313434aa7f27677428940e1d7de73fe6da8a488/model/mfccs/ark/distances_mfccs.csv?raw=true"

# Pilot B: TIMIT
# NB: this experiment's Makefile is not up to date; these files may not exist
cp ../experiments/pilot_july_2018/results.csv data_timit_human.csv
cp ../experiments/pilot_july_2018/stimuli/item_meta_information.csv data_timit_meta.csv
cp ../experiments/pilot_july_2018/distances_bottleneck.csv data_timit_bottleneck.csv
cp ../experiments/pilot_july_2018/distances_mfcc.csv data_timit_mfcc.csv

# Pilot C: Lab speech
# NB: this experiment's Makefile is not up to date; these files may not exist;
# currently there are problems regenerating these files
cp ../experiments/pilot_Aug_2018/analysis/geomphon_pilot_results_for_analysis.csv data_lab_human.csv
cp ../experiments/pilot_Aug_2018/distances_bottleneck.csv data_lab_bottleneck.csv
cp ../experiments/pilot_Aug_2018/distances_mfcc.csv data_lab_mfcc.csv

# Long triplet file
cp ../experiments/pilot_May_2019/triplets.csv hindi_design_long.csv
