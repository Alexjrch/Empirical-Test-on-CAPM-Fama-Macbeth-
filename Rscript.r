
installed.packages('lmtest','car')
library(lmtest)
library(tseries)
library(gmm)


#import dataset
mydata<-read.csv('stock_return.csv')
rf<-read.csv('tbill.csv')
```


#calculate excess returns
market.index=mydata$X.GSPTSE
excess.market.return=mydata$X.GSPTSE-rf
names(excess.market.return)<-c('EMR')
riskfree<-rf$tb


for (i in 1:45){
  rf[i+1]<-riskfree
}
names(rf)=rep('risk free',46)
excess.stocks.return=mydata-rf
excess.stocks.return[,1]=NULL


#make our data into panel data
longdata<-reshape(excess.stocks.return,varying = list(names(excess.stocks.return)),
                    v.names="return",timevar = "stocks",direction = 'long')
for (i in 1:45) {
  begin=(i-1)*60+1
  ends=begin+59
  longdata[begin:ends,1]<-names(excess.stocks.return[i])
}




paneldata<-data.frame(longdata$return,longdata$stocks,longdata$id)
paneldata[,4]<-rep(excess.market.return$EMR,45)
names(paneldata)<-c('s.return','firm','time','m.return')



#testing for heteroskedasticity
bptest(s.return~m.return+factor(firm),data = paneldata)
#compare fiexed and random effect model
library(plm)
fixed.model<-plm(s.return~m.return,data = paneldata,index = c('firm','time'),model = 'within')
random.model<-plm(s.return~m.return,data = paneldata,index = c('firm','time'),model = 'random')
summary(fixed.model)
phtest(fixed.model,random.model)
#testing for serial correlation
pbgtest(random.model)



z <- as.matrix(excess.stocks.return$AEM)
t <- nrow(z)
zm <- excess.market.return$EMR
h <- matrix(zm, t, 1)
res <- gmm(z ~ zm, x = h)
summary(res)
unname(res$coefficients[2])



turns <- 0
gmm.beta <- c()
for (be in excess.stocks.return) {
  turns=turns+1
  z <- as.matrix(be)
  t <- nrow(z)
  zm <- excess.market.return$EMR
  h <- matrix(zm, t, 1)
  gmmfit <- gmm(z~zm, x = h)
  gmm.beta[turns] <- unname(gmmfit$coefficients[2])
}
gmm.beta




#reressions for estimates of alpha and beta with OLS
alpha.value<-c()
alpha.pvalue<-c()
beta.value<-c()
beta.pvalue<-c()
dw.pvalue<-c()
bp.pvalue<-c()
dw.teststat<-c()
bp.teststat<-c()
turns=0
for (beta in excess.stocks.return){
  turns=turns+1
  fit<-lm(beta~excess.market.return$EMR)
  
  a.value<-unname(fit$coefficients[1])
  b.value<-unname(fit$coefficients[2])
  
  dw.pvalue[turns]<-dwtest(fit)$p.value
  bp.pvalue[turns]<-bptest(fit)$p.value
  
  dw.teststat[turns]<-dwtest(fit)$statistic
  bp.teststat[turns]<-bptest(fit)$statistic
  
  alpha.value[turns]<-a.value
  beta.value[turns]<-b.value
  
  alpha.pvalue[turns]<-summary(fit)$coefficients[1,4]
  beta.pvalue[turns]<-summary(fit)$coefficients[2,4]
}
stockname=names(excess.stocks.return)
names(alpha.value)<-stockname
names(beta.value)<-stockname
names(dw.pvalue)<-stockname
names(bp.pvalue)<-stockname
names(dw.teststat)<-stockname
names(bp.teststat)<-stockname
names(alpha.pvalue)<-stockname
names(beta.pvalue)<-stockname
par(mfrow=c(1,2))
plot(beta.value,main = 'stock beta')
plot(beta.pvalue,main = 'p-value pf beta')
abline(h=0.05,col='red')
plot(alpha.value,main = 'stock alpha')
plot(alpha.pvalue,main = 'p-value of alpha')
abline(h=0.05,col='red')
plot(dw.teststat,main = 'DW test-stat')
plot(dw.pvalue,main = 'DW p-value')
abline(h=0.05,col='red')
plot(bp.teststat,main = 'BP test-stat')
plot(bp.pvalue,main = 'BP p-value')
abline(h=0.05,col='red')
#p-value from tests of alpha=0
#(alpha.pvalue)
#alpha for most series does not equal 0
#original CAPM doesn't work
#there is arbitrage oppoturnity
#as potential autocorrelation problems may happen
#DW test for all stock seruies to obtain p-values for the test
#test for those p-value whether equal zero
#(dw.pvalue)
#t.test(dw.pvalue)
#there is almostly no autocorrelation problem in residaul
#print('--------------------------------------------------------------------------------------')
#as potential heteroskadasity pronblems may happen
#BP test for all stock seruies to obtain p-values for the test
#test for those p-value whether equal zero 
#(bp.pvalue)
#t.test(bp.pvalue)
#no hetero.



#regression without constant term OLS
beta.value<-c()
turns=0
for (beta in excess.stocks.return){
  turns=turns+1
  fit<-lm(beta~0+excess.market.return$EMR)
  
  b.value<-unname(fit$coefficients)
  beta.value[turns]<-b.value
}
names(beta.value)<-stockname
(beta.value)



stock.beta=sort(beta.value,decreasing = TRUE)
stock.beta
ranked.name<-names(stock.beta)



#formation of 9 portfolios
p1<-cbind(mydata$FM,mydata$ECA,mydata$TECK.B,mydata$WEED,mydata$CNQ)
colnames(p1)<-c(ranked.name[1:5])
p2<-cbind(mydata$BBD.B,mydata$CVE,mydata$BB,mydata$SU,mydata$K)
colnames(p2)<-c(ranked.name[6:10])
p3<-cbind(mydata$IMO,mydata$IPL,mydata$MG,mydata$PPL,mydata$WPM)
colnames(p3)<-c(ranked.name[11:15])
p4<-cbind(mydata$TRP,mydata$CP,mydata$SNC,mydata$ABX,mydata$CCO)
colnames(p4)<-c(ranked.name[16:20])
p5<-cbind(mydata$SJR.B,mydata$ENB,mydata$CNR,mydata$DOL,mydata$SAP)
colnames(p5)<-c(ranked.name[21:25])
p6<-cbind(mydata$WN,mydata$CTC.A,mydata$AEM,mydata$T,mydata$OTEX)
colnames(p6)<-c(ranked.name[26:30])
p7<-cbind(mydata$FNV,mydata$CCL.B,mydata$BCE,mydata$RCI.B,mydata$GIL)
colnames(p7)<-c(ranked.name[31:35])
p8<-cbind(mydata$L,mydata$EMA,mydata$BHC,mydata$CSU,mydata$BIP.UN)
colnames(p8)<-c(ranked.name[36:40])
p9<-cbind(mydata$FTS,mydata$MRU,mydata$WCN,mydata$KL,mydata$ATD.B)
colnames(p9)<-c(ranked.name[41:45])



#calculate weights within portfolio
#apply it to whole time period for portfolio return
portfolio.return<-data.frame(matrix(ncol = 9,nrow = 60))
names(portfolio.return)<-c('pr1','pr2','pr3','pr4','pr5','pr6','pr7','pr8','pr9')
portfolio.return[,1]<-p1%*%(portfolio.optim(p1,shorts = TRUE)$pw)
portfolio.return[,2]<-p2%*%(portfolio.optim(p2,shorts = TRUE)$pw)
portfolio.return[,3]<-p3%*%(portfolio.optim(p3,shorts = TRUE)$pw)
portfolio.return[,4]<-p4%*%(portfolio.optim(p4,shorts = TRUE)$pw)
portfolio.return[,5]<-p5%*%(portfolio.optim(p5,shorts = TRUE)$pw)
portfolio.return[,6]<-p6%*%(portfolio.optim(p6,shorts = TRUE)$pw)
portfolio.return[,7]<-p7%*%(portfolio.optim(p7,shorts = TRUE)$pw)
portfolio.return[,8]<-p8%*%(portfolio.optim(p8,shorts = TRUE)$pw)
portfolio.return[,9]<-p9%*%(portfolio.optim(p9,shorts = TRUE)$pw)
#calculate excess portfolio return
rf[,10:46]<-NULL
for (j in 1:9){
  rf[j]<-riskfree
}
names(rf)=rep('risk free',9)
excess.portfolio.return=portfolio.return-rf



#regression on CAPM with portfolio
portfolio.beta<-c()
nums=0
for (b in excess.portfolio.return){
  nums=nums+1
  p.model<-lm(b~0+excess.market.return$EMR)
  
  b.value<-unname(p.model$coefficients)
  portfolio.beta[nums]<-b.value
}
#estimated beta values of portfolios
portfolio.beta



#relation between expected return of portfolios and their beta
#regression on portfolio return with their beta for each period
csdata<-data.frame(matrix(ncol = 60,nrow = 9))
for (k in 1:60) {
  csdata[,k]<-t(portfolio.return[k,])
}
po.pvalue<-c()
turns<-0
for (g in 1:60) {
  turns=turns+1
  ex=as.vector(csdata[,g])
  cs.model<-lm(ex~portfolio.beta)
  x=summary(cs.model)
  po.pvalue[turns]<-x$coefficients[2,4]
}  
names(po.pvalue)<-c(1:60)
(po.pvalue)
plot(po.pvalue, col='white')
turns<-0
for (point in po.pvalue) {
  turns=turns+1
  if (point > 0.05) {
    points(turns,point,col='lightgreen',pch=19,cex=1)
  } else {
    points(turns,point,col='lightblue',pch=19,cex=1.5)
    text(turns,point,labels=turns,cex = 0.5)
  }
}
abline(h=0.05,col='red')
