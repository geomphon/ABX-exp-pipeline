# ABX-exp-pipeline


This folder contains everything necessary to launch the geomphon ABX experiments, validate the models and design, and clean and analyse the data.


### Required packages and libraries


**Python**

```
 #pip: 
 pandas
 numpy
 scipy 
 ffmpeg
 fastdtw==0.3.2 
 cython
 scikit-learn
 simanneal
 pydub
 h5py==2.6.0


standard_format:
 	pip install git+git://github.com/geomphon/standard-format.git@v0.1#egg=standard_format
Custom fork of python_speech_features:
 	pip install git+git://github.com/geomphon/python_speech_features_geomphon.git@v1.0GEOMPH#egg=python_speech_features
textgrid:   	
	pip install git+git://github.com/kylebgorman/textgrid.git
	
##For acosutic distances
## required: conda, brew 

	# install shennong dependencies (all excepted pykaldi)
sed '/pykaldi/d' environment.yml > environment.macos.yml
conda env create --name shennong -f environment.macos.yml
conda activate shennong

# install pykaldi (see https://github.com/pykaldi/pykaldi#from-source)
git clone https://github.com/pykaldi/pykaldi.git
cd pykaldi
brew install automake cmake git graphviz libtool pkg-config wget
pip install --upgrade pip setuptools numpy pyparsing ninja
cd tools
./check_dependencies.sh
./install_protobuf.sh
./install_clif.sh
./install_kaldi.sh
cd ..
python setup.py install
cd ..

# install shennong
make install
make test
	
```


**R**

```
- magrittr
- readr
- tidyr
- dplyr
```

You must also provide the following: 

For stimuli creation: 
1) folder of .wav files 
2) folder of .textGrid files, with names that match the .wav files exactly. 

Naming conventions for textGrid and .wavs :
		 In order to ensure that stimuli are always cross-gender, you must specify the gender of the speaker.   If the speaker is male, the first character of the .wav and .texgrid associated must be M. (F for female). If not, the design script  won't run properly.   
		 Ex : a female speaker name Katie must have both following files : FKatie.wav , FKatie.textgrid

Textgrid format:  You must have a tier name "word", in which only the words you want to work on are marked. Right now, the script assumes that you have three and only three instances of each word per .wav.  ( You can change this in the script stimlist/generate_design.py)

3) phoneme_info.csv

This is a .csv file with three columns that lists the Label, language, and Phoneme for each label in the textgrids. in our data. Note that if a phone is marked "NA" in the language column it will be skipped in the stimuli creation pipeline  
		Label,Language,Phoneme  
		AKA,NA,k  
		AKHA,ENG,kʰ  



There are four parts to this pipeline.  All parts have commands in the makefile, and each part has a folder . 


## 1. 1_stimuli 
stimuli building, stimuli selection, and design. 

takes as input:  
       .wav files  
       .text grids   
       .csv phoneme information file (this maps the annotations in the textgrid files to phonemes)  
    and then: 
	-clips each marked interval into a separate soundfile  
	-generates a list of all possible three-file combinations (= "triplets")  
	-finds an optimized subset of these triplets (to save doing calculations on all of them)  
	-caculates acoustic distances between files for each of the subset of triplets  
	-selects the phones of interest based on the mean acoustic distance between recordings  for those phones.   
	-optimizes a stimuli list based on the phones of interest, selects specific triplet instances.  
	-concatenates soundfiles to create an audio file for each of the selected triplets  


## 2. 2_validation
takes the design above, samples data, and uses the sampled data to test the models to be used.  

This is a pipeline itself, and is documented in 2_validation/ReadMe_validation_pipeline.md.  

Inputs to this pipeline are the mean acoustic distances calculated in 1_stimuli above, and the geomphon scores.  

The pipeline outputs two measure of interest:  
for a set of models, the difference between the value input as the coeffcient of the predictors of interest and the value returned by the model.  
for a set of pairs of models, the bayes factors indicating which model is a better fit.  



## 3. 3_LMEDs 

For experiment creation: 

Experiments are accomplished using  our fork of LMEDS 

clone our fork of LMEDs, 
then adjust the following documents: 
	presurvey.txt. (a demographic survey for the beginning of the experiment) 
	postsurvey.txt (a post-experiment survey) 
	dictionary.txt (all strings to be shown (e.g. instructions) that are not in the surveys above must be listed in this document) 
	sequence file  (this specifies the order of how instructions, surveys, and stimuli are presented, including randomization) 

put the entire LMEDs file on a server (or run locally, see LMEDs manual here: https://github.com/timmahrt/LMEDS) . 
	adjust the cgi file 
	adjust your server permissions 
		.cgi folder should have execute permissions 
		output folders should have write permission 


## 4. 4_results 
This folder contains scripts used for results anonymization and cleaning 

input:  
  folder of raw data downloaded from LMEDs OR folder of anonymized data 
  download the folder of LMEDS results files from the server 

 if necessary: anonymize data 
	change subject info using anonymize_lmeds_data_filenames.py 
	(be careful to store raw data or anonymization key in a secure locaiton (i.e. not synced to your git)) 
	**NB if you are using mechanical turk workers, their worker ID will be visible, and is considered individually identifiable information** 

follow the makefile commands to filter data and then clean and re-format




