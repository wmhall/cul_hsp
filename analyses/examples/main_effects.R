library(tidyverse)
library(lsmeans)
library(forcats)

composite_df <- 
  read_csv("data/preprocessed/composites.csv")

item_df <- 
  read_csv("data/preprocessed/items.csv")

data_df <- left_join(composite_df, select(item_df, response_id, status_1))

fm_df <- 
  data_df %>%  
  mutate(cond = case_when(.$cond == "low"~0, 
                          .$cond == "high"~1)) %>% 
  gather(var_name, var, -response_id, -cond, -sc) %>% 
  nest(-var_name) %>% 
  mutate(fm = data %>% map(~lm(var ~ 1 + cond + sc, data = .)), 
         fm_tidy = fm %>% map(broom::tidy))

fm_df %>% 
  select(var_name, fm_tidy) %>% 
  unnest() %>% 
  filter(term == "cond") %>% 
  mutate_if(is.numeric, round, digits = 2)



fm_df_factored <- 
  data_df %>% 
  mutate(cond = as_factor(cond) %>% fct_relevel("low", "high")) %>% 
  gather(var_name, var, -response_id, -cond, -sc) %>% 
  nest(-var_name) %>% 
  mutate(fm = data %>% map(~lm(var ~ 1 + cond + sc, data = .)), 
         fm_tidy = fm %>% map(broom::tidy), 
         adj_mean = fm %>% map(~lsmeans(.,pairwise ~ cond, adjust="none") %>% 
                                 cld %>% as_data_frame %>% rename(var=lsmean)))

f_make_plot <- function(fm_adj_means, fm_data, y_lab) {
  ggplot(fm_adj_means, aes(x = cond, y = var)) + 
    geom_bar(stat = "identity", aes(fill = cond)) + 
    geom_errorbar(data = fm_adj_means, aes(ymax = upper.CL, ymin=lower.CL),
                  position=position_dodge(width=0.9), width=0.25) + 
    geom_jitter(data = fm_data, aes(x = cond, y = var), alpha = .3) +
    scale_x_discrete("Gender inclusive policy count", labels = c("low" = "Low","high" = "High")) +
    ylab(y_lab) + guides(fill=FALSE) +
    coord_cartesian(ylim=c(1,7))
  }

fm_plots <- 
fm_df_factored %>% 
  mutate(plots = pmap(list(adj_mean, data, var_name), f_make_plot)) 

write_rds(fm_plots, "output/main_analyses_output.rds")


# make grid plots ---------------------------------------------------------

facet_plot <- 
fm_plots %>% 
  select(var_name, adj_mean) %>%
  unnest() %>%
  ggplot(., aes(x = cond, y = var)) + 
  facet_grid(~var_name) +
  geom_bar(stat = "identity", aes(fill = cond)) +
  geom_errorbar(aes(ymax = upper.CL, ymin=lower.CL),
                position=position_dodge(width=0.9), width=0.25) + 
  scale_x_discrete("Gender inclusive policy count", 
                   labels = c("low" = "Low","high" = "High")) +
  coord_cartesian(ylim=c(1,7)) + guides(fill=FALSE)


ggsave("plots/facet_grid_main_effects.png", facet_plot)

  

# testing converstaion analyses - overal and by item ----------------------

conv_data_df <- 
data_df %>% 
  select(response_id, cond, convac, 
         convhostil, sc) %>% 
  left_join(select(item_df, response_id, 
                   convaccept_1, convcompet_1,
                   convhostil_1, convhostil_2)) %>% 
  mutate(cond = as_factor(cond) %>% fct_relevel("low", "high")) %>% 
  gather(var_name, var, -response_id, -cond, -sc) %>% 
  nest(-var_name) %>% 
  mutate(fm = data %>% map(~lm(var ~ 1 + cond + sc, data = .)), 
         fm_tidy = fm %>% map(broom::tidy), 
         adj_mean = fm %>% map(~lsmeans(.,pairwise ~ cond, adjust="none") %>% 
                                 cld %>% as_data_frame %>% rename(var=lsmean)))


conv_plot_output <- 
conv_data_df %>% 
  select(var_name, adj_mean) %>% 
  unnest() %>%
  mutate(var_name = as_factor(var_name) %>% fct_relevel("convac", "convhostil",
                                                        "convaccept_1", "convcompet_1", 
                                                        "convhostil_1", "convhostil_2")) %>% 
  ggplot(., aes(x = cond, y = var)) + 
  facet_grid(~var_name) +
  geom_bar(stat = "identity", aes(fill = cond)) +
  geom_errorbar(aes(ymax = upper.CL, ymin=lower.CL),
                position=position_dodge(width=0.9), width=0.25) + 
  scale_x_discrete("Gender inclusive policy count", 
                   labels = c("low" = "Low","high" = "High")) +
  coord_cartesian(ylim=c(1,7)) + guides(fill=FALSE)

  
conv_models_output <- 
  conv_data_df %>% 
  rowwise() %>% 
  mutate(plots = list(conv_plot_output)) %>% 
  ungroup()

conv_models_output %>% 
  write_rds("output/conv_output.rds")


