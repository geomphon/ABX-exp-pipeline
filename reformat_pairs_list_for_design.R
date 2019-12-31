#build design from selected stim



#reorder phonemes so that they alternate which lang is first 

filt_diff_pairs$language_1 <-NA
filt_diff_pairs$phone_1 <- NA
filt_diff_pairs$phone_2 <- NA

for (i in (1:nrow(filt_diff_pairs))) {
  filt_diff_pairs$language_1[i] <- sample(c("HIN","ENG"),1)
}
for (i in (1:nrow(filt_diff_pairs))) {             
  filt_diff_pairs$phone_1[i]<- ifelse(filt_diff_pairs$language_1[i]=="HIN",
                                      filt_diff_pairs$phone_HIN[i],
                                      filt_diff_pairs$phone_ENG[i])
  filt_diff_pairs$phone_2[i]<- ifelse(filt_diff_pairs$language_1[i]=="HIN",
                                      filt_diff_pairs$phone_ENG[i],
                                      filt_diff_pairs$phone_HIN[i])
}


diff_pairs <-dplyr::select(filt_diff_pairs,"phone_1","phone_2","language_1") %>%
  dplyr::left_join(.,pairs_w_dist,
                   by=c("phone_1","phone_2","language_1"))%>%
  dplyr::group_by(phone_1,phone_2,language_1) %>%
  dplyr::sample_n(1)



same_pairs <- dplyr::filter(pairs_w_dist, target_other=="TGT")%>%
  dplyr::filter(.,phone_1!="z"&phone_2!="z")%>%
  dplyr::group_by(.,phone_1, phone_2, language_1) %>%
  dplyr::sample_n(6)


full_filt_pairs<-dplyr::bind_rows(diff_pairs,same_pairs)


readr::write_csv(full_filt_pairs, OUTPUT)