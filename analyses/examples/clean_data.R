library(tidyverse)
library(readxl)

var_names <- 
read_excel("data/var_names.xlsx") %>%
  drop_na()

raw_data <- 
  read_csv("data/cul_hsp_num.csv", col_names = F) %>% 
  .[c(-1:-3),] %>% 
  map(parse_guess) %>% 
  as_data_frame()

raw_data <- 
raw_data[var_names$var_name]
  
names(raw_data) <- var_names$new_name

data_clean <- raw_data %>% 
  drop_na(sc_4)


var_to_rev <- 
  c("orgc_4", "orgc_5", "orgc_6", "compet_2", "sc_2", "sc_3")

vars_not_outcomes <- c("memtest", "uni", "career", "ease", "manip", "ubc", "status")

f_rev <- function(x) {8 - x}

data_clean_rev <- 
  data_clean %>% map_at(var_to_rev, f_rev) %>% as_data_frame()

df_composites <- 
data_clean_rev %>%
  select(-cond_1, -cond_2) %>% 
  gather(var_name, var_resp, -response_id) %>% 
  separate(var_name, c("var_type", "var_num")) %>% 
  mutate(var_resp = as.numeric(var_resp)) %>% 
  drop_na %>% 
  group_by(response_id, var_type) %>% 
  summarise(var_mean = mean(var_resp, na.rm =T)) %>%
  ungroup() %>% 
  filter(!var_type %in% vars_not_outcomes) %>% 
  spread(var_type, var_mean)

df_comp_final <- 
df_composites %>% 
  gather(var_name, var_resp, convaccept, convcompet) %>% 
  group_by(response_id) %>% 
  summarise(convac = mean(var_resp, na.rm =T)) %>% 
  left_join(df_composites, .) %>% 
  select(-convaccept, -convcompet)

df_clean_items <- 
data_clean_rev %>% 
  select(-cond_1, -cond_2, -ubc_id, -ps_name, -ps_email)

condition_df <- 
  data_clean_rev %>% 
  select(response_id, cond_1, cond_2) %>% 
  mutate(cond = case_when(is.na(.$cond_1)~"low", 
                          !is.na(.$cond_1)~"high")) %>% 
  select(response_id, cond)

composite_data_to_write <- 
  left_join(condition_df, df_comp_final)


write_csv(composite_data_to_write, "data/preprocessed/composites.csv")
write_csv(df_clean_items, "data/preprocessed/items.csv")
