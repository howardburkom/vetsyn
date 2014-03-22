##' \code{pre_process_glm}
##'
##' Function to remove known temporal effects from time series. It fits
##' a glm model to the time series, and delivers the residuals. 
##' 
##' This function is provided for users interested in capturing
##' (saving or plotting) the results of this pre-processing step. 
##' However, in the context of syndromic
##' surveillance through objects of the class \code{syndromic},
##' pre-processing is performed in conjunction with the application of
##' control-charts, saving results into an object of the 
##' class \code{syndromic} (which does not contain slots to
##' save pre-processed data, as pre-processing is done within
##' detection algorithms.)
##'
##' @name pre_process_glm-methods
##' @docType methods
##' @seealso \code{\link{syndromic}}
##' @aliases pre_process_glm
##' @aliases pre_process_glm-methods
##' @aliases pre_process_glm,syndromic-method
##'
##' @param x a \code{syndromic} object, which must have at least 
##' the slot of observed data and a data.frame in the slot dates.
##' @param slot the slot in the \code{syndromic} object to be processed,
##' by default, "observed", but this argument can be used to
##' change it to "baseline"
##' @param syndromes an optional parameter, if not specified, all
##' columns in the slot \code{observed} (or \code{baseline} if that
##' was chosen in the previous parameter) of the \code{syndromic} object
##' will be used. The user can choose to restrict the analyses to 
##' a few syndromic groups listing their name or column position
##' in the \code{observed} matrix. See examples.
##' @param family the GLM distribution family used, by default 
##' \code{"poisson"}. if \code{"nbinom"} is used, the function
##' glm.nb is used instead.
##' @param formula the regression formula to be used. The following arguments
##' are accepted: trend (for a monotonic trend), month, dow (day of week),
##' sin, cos, Ar1 (auto-regressive for 1 days) to AR7. These elements can be combined
##' into any formula. The default is formula="dow+sin+cos+Ar1+Ar2+AR3+AR4+AR5". See examples.
##' @param period in case pre-processing is applied using "glm" AND the sin?cos functions 
##' are used, the cycle of repetitions need to be set. The default is 365, for yearly cycles.
##' @param plot whether plots comparing observed data and the result of 
##' the pre-processing should be displayed.
##' @param print.model whether the result of model fitting should be
##' printed on the console. This is recommended when the user is 
##' exploring which dependent variables to keep or drop.
##' 
##' @return A matrix with all the pre-processed vectors. 
##' 
##' @keywords methods
##' @export
##' @importFrom MASS glm.nb
##' @references Fernanda C. Dorea, Crawford W. Revie, Beverly J. McEwen, 
##' W. Bruce McNab, David Kelton, Javier Sanchez (2012). Retrospective 
##' time series analysis of veterinary laboratory data: 
##' Preparing a historical baseline for cluster detection in syndromic 
##' surveillance. Preventive Veterinary Medicine. 
##' DOI: 10.1016/j.prevetmed.2012.10.010.
##' @examples
##'data(lab.daily)
##'my.syndromic <- raw_to_syndromic (id=SubmissionID,
##'                                  syndromes.var=Syndrome,
##'                                  dates.var=DateofSubmission,
##'                                  date.format="%d/%m/%Y",
##'                                  remove.dow=c(6,0),
##'                                  add.to=c(2,1),
##'                                  data=lab.daily)
##'pre_processed_data <- pre_process_glm(my.syndromic)
##'pre_processed_data <- pre_process_glm(my.syndromic,
##'                               syndromes="Musculoskeletal")
##'pre_processed_data <- pre_process_glm(my.syndromic,
##'                               syndromes=c("GIT","Musculoskeletal"))
##'pre_processed_data <- pre_process_glm(my.syndromic,
##'                               syndromes=3)
##'pre_processed_data <- pre_process_glm(my.syndromic
##'                               syndromes=c(1,3))
##'
##'pre_processed_data <- pre_process_glm(my.syndromic,
##'                               family="nbinom")
##'setBaseline(my.syndromic)<- my.syndromic@observed
##'pre_processed_data <- pre_process_glm(my.syndromic,slot="baseline")
                             

setGeneric('pre_process_glm',
           signature = 'x',
           function(x, ...) standardGeneric('pre_process_glm'))

setMethod('pre_process_glm',
          signature(x = 'syndromic'),
          function (x,
                    slot="observed",
                    syndromes=NULL,
                    family="poisson",
                    formula="dow+sin+cos+year+AR1+AR2+AR3+AR4+AR5+AR6+AR7",
                    period=365,
                    print.model=TRUE,
                    plot=TRUE)
        {
    
      ##check that syndromes is valid
       if (class(syndromes)=="NULL"){
         syndromes <- colnames(x@observed)
         }else{
         if (class(syndromes)!="character"&&class(syndromes)!="numeric") {
     stop("if provided, argument syndromes must be a character or numeric vector")
           }
         }
      
       
       ##check that valid dates are entered
       if (dim(x@observed)[1]!=dim(x@dates)[1]){
         stop("valid data not found in the slot dates")
       }
       
      
       #make sure syndrome list is always numeric
       #even if user gives as a list of names
       if (class(syndromes)=="numeric") {
       syndromes.num <- syndromes
       }else{
         syndromes.num <- match(syndromes,colnames(x@observed))
       }

       #pulling data from the object to work out of the object
       if (slot=="baseline"){
      observed.matrix <- x@baseline
       } else {
      observed.matrix <- x@observed }
       
processed.matrix <- matrix(NA,ncol=dim(observed.matrix)[2],nrow=dim(observed.matrix)[1])
              
       
       loop=0
      for (c in syndromes.num){      
       loop=loop+1
        
        days = observed.matrix[,c]
        t = 1:length(days)
        month = as.factor(x@dates$month)
        dow <- as.factor(x@dates$dow)
        cos = cos (2*pi*t/period)
        sin = sin (2*pi*t/period)
        year <- as.factor(x@dates$year)
        AR1<-c(days[1],days[1:(length(days)-1)])
       AR2<-c(days[1:2],days[1:(length(days)-2)])
       AR3<-c(days[1:3],days[1:(length(days)-3)])
       AR4<-c(days[1:4],days[1:(length(days)-4)])
       AR5<-c(days[1:5],days[1:(length(days)-5)])
       AR6<-c(days[1:6],days[1:(length(days)-6)])
       AR7<-c(days[1:7],days[1:(length(days)-7)])
       trend=t
       
       fn.formula=as.formula(paste0("days~",formula))
       
      
      
      if (family=="nbinom"){
        #require(MASS)
        fit1     <- glm.nb(fn.formula)  
        predict1 <- predict(fit1, type="response", se.fit=TRUE)
        series   <- predict1$fit
    
      }else{
        #distribution=family            
        
        fit1 <- glm(fn.formula, family=family)
        predict1 <- predict(fit1, type="response", se.fit=TRUE)
        series   <- predict1$fit
      }    
        
       residuals <- days-series
         
          syndrome.name <- colnames(observed.matrix)[c]
         
        ##plotting and prinitng    
        if (print.model==TRUE){
              print(syndrome.name)
              print(fit1)    
            }
      
          
        if (plot==TRUE) {
          
          if (loop==1){
            par(mfrow=c(length(syndromes),1),mar=c(2,4,2,2))}
          
          plot(residuals, type="l",ylab=syndrome.name)
          lines(days,col="grey")
          legend("topleft", pch=3,col=c("black","grey"),
                 c("Pre-processed series","Original series"))
        }       
        
       processed.matrix[,c] <- residuals
       
      }
      
      return(processed.matrix)
       
          }
)