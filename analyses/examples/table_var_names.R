library(tidyverse)

f_recode <- function(vec_rec) {
  case_when(vec_rec == "interest" ~ "Interest in working at CCB", 
            vec_rec == "orgc"~ "Anticipated organizational commitment", 
            vec_rec == "selfefficacy"~ "Anticipated self efficacy", 
            vec_rec == "convaccept"~ "Anticipated feelings of acceptance in coversations", 
            vec_rec == "convcompet"~ "Anticipated feelings of competence in coversations", 
            vec_rec == "convhostil"~ "Anticipated feelings of hostility in coversations",
            vec_rec == "compet"~ "Anticipated competitiveness at CCB", 
            vec_rec == "trust"~ "Anticipated trust at CCB", 
            vec_rec == "sit"~ "Anticipated social identity at CCB", 
            vec_rec == "status"~ "Anticipated gender differences in status at CCB", 
            vec_rec == "discrim"~ "Anticipated gender based discriminationat CCB",
            vec_rec == "manip"~ "Manipulation check",
            vec_rec == "sc"~ "Stigma consciousness")
} 


var_names <- 
readxl::read_excel("data/var_names.xlsx") %>% 
  drop_na(new_name) %>% 
  select(var_name = new_name, label) %>% 
  mutate(label = stringr::str_replace_all(label, "(\r|\n)", "")) %>% 
  filter(var_name != "cond_1" & var_name != "cond_2" & var_name != "response_id")

table_for_output <- 
var_names %>% 
  filter(stringr::str_detect(var_name, "[0-9]$")) %>% 
  separate(var_name, c("var_name", "item")) %>%  
  filter(var_name != "memtest") %>% 
  mutate(var_descrip = f_recode(var_name)) %>% 
  select(var_name, item, var_descrip, label)


write_csv(table_for_output, "output/table_of_var_names.csv")
