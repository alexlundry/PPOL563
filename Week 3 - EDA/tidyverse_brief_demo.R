library(tidyverse)

delays <- nycflights13::flights %>% 
   select(year:day, ends_with("delay"), distance, air_time, origin, dest) %>% 
   mutate(speed = distance / air_time * 60,
          dc_airport = ifelse(dest %in% c("DCA", "IAD", "BWI"), 1, 0)) %>% 
             group_by(dest) %>% 
             summarize(count = n(), 
                       dist = mean(distance, na.rm = T),
                       delay = mean(arr_delay, na.rm = T),
                       dc_airport = max(dc_airport)) %>% 
             filter(count > 20, 
                    dest != "HNL")
