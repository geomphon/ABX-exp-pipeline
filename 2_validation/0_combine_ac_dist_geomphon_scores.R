#0 combine acoustic distances and hindi scores 

`%>%`<-magrittr::`%>%`

DESIGN_4each <- "2_validation/ac_dists_3each.csv"
DESIGN_3each <- "2_validation/ac_dists_4each.csv"
HINDI_SCORES <- "2_validation/hindi_scores.csv"

hindi_scores <- readr::read_csv(HINDI_SCORES) 
hindi_scores <- dplyr::rename(hindi_scores,Phone_NOTENG=phone)

diff_pairs_4 <- readr::read_csv(DESIGN_4each)
diff_pairs_4 <- dplyr::rename(diff_pairs_4,Phone_NOTENG=phone_HIN, Phone_ENG=phone_ENG)


diff_pairs_3 <- readr::read_csv(DESIGN_3each)
diff_pairs_3 <- dplyr::rename(diff_pairs_3,Phone_NOTENG=phone_HIN, Phone_ENG=phone_ENG)

new_des_4<- dplyr::left_join(diff_pairs_4,hindi_scores,
                             by="Phone_NOTENG")
readr::write_csv(new_des_4,"2_validation/design_4each.csv")

new_des_3<- dplyr::left_join(diff_pairs_3,hindi_scores,
                             by="Phone_NOTENG")
readr::write_csv(new_des_3,"2_validation/design_3each.csv")

