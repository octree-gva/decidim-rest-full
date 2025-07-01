workspace {
  model {   
    user = person "Participant"
    
    !include "./decidim.dsl.include"
  }
  
  views {
    !include "./view.dsl.include"
    !include "./scenarios.dsl.include"
  }
}