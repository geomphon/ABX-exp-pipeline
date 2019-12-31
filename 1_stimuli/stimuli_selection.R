#!/usr/bin/env Rscript
#stimuli seleciton pipeline

#created by Amelia 
#last edit 28 Nov by Amelia 

#library(magrittr)
#library(readr)
#library(dplyr)

#takes the initial narrowed data frame of possible stimuli with acoustic 
#distances and samples a subset  to form a dataframe of length 
#144 (= desired number of trials). This new data frame of pairs is then made 
#intro triplets, and then input into the optimization script a second time, to 
#select the instances to use (which recording and which speaker) 


`%>%` <- magrittr::`%>%`

 #ARGS <-ARGS <- commandArgs(TRUE)

# Input triplet file
PAIRS <-"1_stimuli/distances_by_pair.csv" # ARGS[1] #

# Output filtered subset of these 
OUTPUT_4_each <- "2_validation/design_4_each.csv" #ARGS[2] # 
OUTPUT_3_each <- "2_validation/design_3_each.csv" #ARGS[3] #

pairs_w_dist <- readr::read_csv(PAIRS)

#English sounds the most variable between instances are b,z,d͡ʒ ɽʱ
#once these are removed, remove pairs with large mean distances
#after pairs are winnowed down, 
#sample one of each phoneme pair
#use join to select triplets that match 

filt_diff_pairs_4_each <-  dplyr::filter(pairs_w_dist, target_other=="OTH")%>%
                    dplyr::filter(.,phone_1!="z"&phone_2!="z")%>%
                    dplyr::filter(.,phone_1!="ɽʱ"&phone_2!="ɽʱ")%>%
                    dplyr::group_by(.,phone_1, phone_2, language_1) %>%
                    dplyr::summarise(.,mean_dist = mean(distance))%>% 
                    dplyr::ungroup(.) %>%
                    dplyr::filter(.,language_1=="HIN") %>%
                    dplyr::group_by(.,phone_1) %>%
                    dplyr::top_n(., -4,mean_dist) %>%
                    dplyr::ungroup(.) %>%
                    dplyr::select(phone_1,phone_2,mean_dist) %>%
                    dplyr::rename(. ,phone_HIN = phone_1, phone_ENG = phone_2)%>%
                    dplyr::slice(rep(1:nrow(.), each=4))

filt_diff_pairs_3_each <-  dplyr::filter(pairs_w_dist, target_other=="OTH")%>%
                            dplyr::filter(.,phone_1!="z"&phone_2!="z")%>%
                            dplyr::filter(.,phone_1!="ɽʱ"&phone_2!="ɽʱ")%>%
                            dplyr::group_by(.,phone_1, phone_2, language_1) %>%
                            dplyr::summarise(.,mean_dist = mean(distance))%>% 
                            dplyr::ungroup(.) %>%
                            dplyr::filter(.,language_1=="HIN") %>%
                            dplyr::group_by(.,phone_1) %>%
                            dplyr::top_n(., -3,mean_dist) %>%
                            dplyr::ungroup(.) %>%
                            dplyr::select(phone_1,phone_2,mean_dist) %>%
                            dplyr::rename(. ,phone_HIN = phone_1, phone_ENG = phone_2)%>%
                            dplyr::slice(rep(1:nrow(.), each=8))

                    
                  
readr::write_csv(filt_diff_pairs_4_each, OUTPUT_4_each)

readr::write_csv(filt_diff_pairs_3_each, OUTPUT_3_each)



