library(tidyverse)
library(forcats)
library(lsmeans)

composite_df <- 
read_csv("data/preprocessed/composites.csv")

item_df <- 
  read_csv("data/preprocessed/items.csv")

manip_df <- 
item_df %>% 
  left_join(select(composite_df, response_id, cond)) %>% 
  select(response_id, cond, manip_frep, manip_policy1,
         manip_policy2, manip_policy3) %>% 
  mutate(cond = fct_relevel(as_factor(cond), c("low", "high")))

fm_df <- 
manip_df %>% 
  gather(var, var_resp, -response_id, -cond) %>%
  nest(-var) %>% 
  mutate(fm = data %>% map(~lm(var_resp ~ 1 + cond, data = .)), 
         fm_tidy = fm %>% map(broom::tidy))

fm_df %>% 
  select(var, fm_tidy) %>% 
  unnest() %>% 
  filter(term == "condhigh") %>% 
  mutate_if(is.numeric, round, digits = 2)

fm_df_adj_means <- 
fm_df %>% 
  mutate(adj_mean = fm %>% 
           map(~lsmeans(.,pairwise ~ cond, adjust="none") %>% 
                                   cld %>% as_data_frame %>% rename(var=lsmean)))



f_make_plot <- function(fm_adj_means, fm_data, y_lab) {
  ggplot(fm_adj_means, aes(x = cond, y = var)) + 
    geom_bar(stat = "identity", aes(fill = cond)) + 
    geom_errorbar(data = fm_adj_means, aes(ymax = upper.CL, ymin=lower.CL),
                  position=position_dodge(width=0.9), width=0.25) + 
    geom_jitter(data = fm_data, aes(x = cond, y = var_resp), alpha = .3) +
    scale_x_discrete("Gender inclusive policy count", labels = c("low" = "Low","high" = "High")) +
    ylab(y_lab) + guides(fill=FALSE) +
    coord_cartesian(ylim=c(1,7))
}

fm_plots <- 
  fm_df_adj_means %>% 
  mutate(plots = pmap(list(adj_mean, data, var), f_make_plot)) 



plot_for_output <- 
fm_df_adj_means %>% 
  select(var_name = var, adj_mean) %>% 
  unnest() %>%
  ggplot(., aes(x = cond, y = var)) + 
  facet_grid(~var_name) +
  geom_bar(stat = "identity", aes(fill = cond)) +
  geom_errorbar(aes(ymax = upper.CL, ymin=lower.CL),
                position=position_dodge(width=0.9), width=0.25) + 
  scale_x_discrete("Gender inclusive policy count", 
                   labels = c("low" = "Low","high" = "High")) +
  coord_cartesian(ylim=c(1,7)) + guides(fill=FALSE)


manip_df_for_output <- 
fm_df_adj_means %>% 
  rowwise() %>% 
  mutate(plots = list(plot_for_output)) %>% 
  ungroup()

write_rds(manip_df_for_output, "output/manip_modoel_data.rds")
