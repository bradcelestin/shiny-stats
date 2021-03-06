
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
#library(shinyjs)
library(ggplot2)

shinyServer(function(input, output, session) {
  
  doFlip <- function(nCoins, p, times){
    outcome <- rbinom(times, nCoins, p)
    return(outcome)
  }
  
  rv <- reactiveValues(
    outcomes = numeric(),
    started = F
  )
  
  observeEvent(input$flip1, {
    runFlips(1)
  })
  
  observeEvent(input$flip10, {
    runFlips(10)
  })
  
  observeEvent(input$flip100, {
    runFlips(100)
  })
  
  observeEvent(input$flip1000, {
    runFlips(1000)
  })
  
  observeEvent(input$flip10000, {
    runFlips(10000)
  })
  
  observe({
    x <- input$probHeads
    if(is.na(x)){ return() }
    if(x > 1) {
      updateNumericInput(session, 'probHeads',value=1)
    } else if(x < 0){
      updateNumericInput(session, 'probHeads',value=0)
    }
  })
  
  runFlips <- function(n){
    rv$started <- T
    o <- doFlip(input$numCoins, input$probHeads, n)
    rv$outcomes <- c(rv$outcomes, o)
  }
  
  observeEvent(input$reset, {
    rv$started <- F
    rv$outcomes <- numeric()
  })
  
  output$distPlot <- renderPlot({
    if(length(rv$outcomes)==0){ return(NULL) }
    
    data <- data.frame(table(rv$outcomes))
    colnames(data) <- c("val","freq")
    data$val <- as.numeric(as.character(data$val))
    data$freq <- as.numeric(as.character(data$freq))
    
    if(input$displayType == 'number'){
      rng <- input$range
    } else if(input$displayType == 'percentile'){
      rng <- quantile(rv$outcomes, probs = input$percentile/100, type =1)
    }
    
    data$inrange <- sapply(data$val, function(b){
      # if(input$rangeType == 'inside'){
        if(b >= rng[1] & b <= rng[2]){
          return("red")
        } else {
          return("black")
        }
#       } else {
#         if(b >= rng[1] & b <= rng[2]){
#           return("black")
#         } else {
#           return("red")
#         }
#       }
    })
    
    data$inrange <- as.factor(data$inrange)
    
    fillv <- levels(data$inrange)
    
    p <- ggplot(data, aes(x=val,y=freq, fill=inrange)) +
      geom_bar(stat="identity")+
      labs(y="# of trials\n",x="\n# of heads in trial")+
      scale_fill_manual(guide=F, values=fillv)+
      scale_x_continuous(expand = c(0, 0), breaks = scales::pretty_breaks()) +  
      theme_minimal(base_size=18) + 
      scale_y_continuous(expand = c(0, 0)) +
      theme(panel.grid.major.x = element_blank(),
            panel.grid.minor.x = element_blank(),
            panel.grid.minor.y = element_blank(),
            # panel.grid.major.y = element_line(color = "white"),
            plot.background = element_blank(),
            panel.ontop = FALSE)
    
    if(input$numCoins==1){
      p = p + scale_x_continuous(breaks = c(0, 1), labels = c("Tails", "Heads")) + 
        labs(y="# of trials\n",x="\nOutcome")
    }
    
    return(p)
    
  })
  
  output$rangeInfo <- renderText({
    if( length(rv$outcomes) == 0 ) { return("Flip some coins to see the result!") }
    
    if( input$displayType == 'number' ){
      # if(input$rangeType == 'inside'){
        v <- sum(rv$outcomes >= input$range[1] & rv$outcomes <= input$range[2])
#       } else {
#         v <- sum(rv$outcomes < input$range[1] | rv$outcomes > input$range[2])
#       }
      # p <- v / length(rv$outcomes)*100
      
      return(paste0("There have been ",length(rv$outcomes)," runs of the simulation. ",v," of the outcomes are between ",input$range[1]," and ",input$range[2], "."))
      
    } else if( input$displayType == 'percentile'){
      q <- quantile(rv$outcomes, probs = input$percentile/100, type =1)
      
      return(paste0("There have been ",length(rv$outcomes)," runs of the simulation.",
                    "The ",input$percentile[1]," percentile is ",q[[1]]," and the ",input$percentile[2]," percentile is ",q[[2]],"."))
    }
    
    
    return(paste0("There have been ",length(rv$outcomes)," runs of the simulation. ",round(p,digits=2),"% of the outcomes meet the selection criteria. ",
                  "The ",input$percentile," percentile is ",q,"."))
    
  })
  
  observe({
    if(rv$started){
      disable("numCoins")
      disable("probHeads")
    }
    if(!rv$started){
      enable("numCoins")
      enable("probHeads")
    }
  })
  
  output$evaluationPanel <- renderUI({
    maxV <- input$numCoins
    qV <- round(maxV / 4)
    sliderInput("range",label="Select outcomes inside the range", min=0,max=input$numCoins,step=1,value=c(qV,input$numCoins-qV))
  })
  
})
