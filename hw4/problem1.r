library("class")
library("MASS")
library("ggplot2")

data       <- read.csv('data/winequality-red.txt', sep=";", header=TRUE)
data.size  <- nrow(data)
train.size <- round(3/5 * data.size)
test.size  <- data.size - train.size

train.data <- head(data, train.size)
test.data  <- tail(data, test.size)

## arrange and vp.layout are from:
## http://gettinggeneticsdone.blogspot.com/2010/03/arrange-multiple-ggplot2-plots-in-same.html
vp.layout <- function(x, y) viewport(layout.pos.row=x, layout.pos.col=y)

arrange <- function(..., nrow=NULL, ncol=NULL, as.table=FALSE) {
    dots <- list(...)
    n <- length(dots)
    if(is.null(nrow) & is.null(ncol)) { nrow = floor(n/2) ; ncol = ceiling(n/nrow)}
    if(is.null(nrow)) { nrow = ceiling(n/ncol)}
    if(is.null(ncol)) { ncol = ceiling(n/nrow)}
    ## NOTE see n2mfrow in grDevices for possible alternative
    grid.newpage()
    pushViewport(viewport(layout=grid.layout(nrow,ncol) ) )
    ii.p <- 1
    for(ii.row in seq(1, nrow)){
        ii.table.row <- ii.row
        if(as.table) {ii.table.row <- nrow - ii.table.row + 1}
        for(ii.col in seq(1, ncol)){
            ii.table <- ii.p
            if(ii.p > n) break
            print(dots[[ii.table]], vp=vp.layout(ii.table.row, ii.col))
            ii.p <- ii.p + 1
        }
    }
}

ef.train <- function (x) {
    1 - sum(train.data$quality == round(x)) / train.size
}

ef.test <- function (x) {
    1 - sum(test.data$quality == round(x)) / test.size
}

ef.data <- function (x) {
    1 - sum(data$quality == round(x)) / data.size
}

l      <- exp(seq(-15,5,by=0.01))
routput <- data.frame("lambda"=l)
model  <- lm.ridge(train.data$quality~., data=train.data[,1:11], lambda=l)

train.pred <- as.matrix(train.data[,1:11]) %*% t(coef(model)[,-1]) +  rep(1,train.size) %o% coef(model)[,1]
routput     <- cbind(routput, data.frame("Train"=apply(train.pred, 2, ef.train)))

test.pred  <- as.matrix(test.data[,1:11]) %*% t(coef(model)[,-1]) +  rep(1,test.size) %o% coef(model)[,1]
routput     <- cbind(routput, data.frame("Test"=apply(test.pred, 2, ef.test)))

data.pred  <- as.matrix(data[,1:11]) %*% t(coef(model)[,-1]) +  rep(1,data.size) %o% coef(model)[,1]
routput     <- cbind(routput, data.frame("Full"=apply(data.pred, 2, ef.data)))

rd <- melt(routput, id="lambda")
rp <- ggplot(rd, aes(lambda, value, colour=variable))
rp <- rp + geom_line()
rp <- rp + scale_colour_discrete(name = "")
rp <- rp + scale_x_continuous(expression(lambda))
rp <- rp + scale_y_continuous("Error Rate")

koutput <- data.frame()
for (k in 2:50) {
    pred <- knn.cv(data[,1:11], data$quality, k=k)
    err  <- 1 - sum(data$quality == pred) / data.size
    koutput <- rbind(koutput, data.frame(k=k, err=err))
}

kd <- melt(koutput, id="k")
kp <- ggplot(kd, aes(k, value, colour=variable))
kp <- kp + geom_line()
kp <- kp + opts(legend.position="none")
kp <- kp + scale_y_continuous("Error Rate")

arrange(rp, kp, ncol=1)
