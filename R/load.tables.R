#' Load the Input-Output and Final demand tables
#' 
#' This function loads the demand tables
#' and defines all variables for the decomposition
#' 
#' @param x the intermediate demand table, it has dimensions GN x GN (G = no. of country, N = no. of industries),
#'  excluding the first row and the first column which contains the country names,
#'  and the second row and second column which contain the industry names for each country.
#'  In addition, an extra row at the end should contain final demand.
#' @param y the final demand table it has dimensions GN x MN,
#'  excluding the first row and the first column which contains the country names,
#'  the second column which contains the industry names for each country,
#'  and second row which contains the five decomposed final demands (M).
#' @return a decompr class object
#' @author Bastiaan Quast
#' @details Adapted from code by Fei Wang.
#' @export


load.tables <- function(x, y) {

  # Part 1: getting the rownames etc.
  GN <- length(x) - 2
  regnam <- unique(x[3:(GN+2),1])
  G <- length(regnam)
  N <- GN / G
  secnam <- unique(x[,2])[3:(N+2)]
  rownam <- paste( x[3:(GN+2),1], ".", x[3:(GN+2),2], sep="" )
  
  # making regions' names
  z <- rownam
  dim( z ) <- c( N, G )
  
  # making the big rownames: bigrownam
  z1 <-  t( array( rownam,dim=c( GN,G ) ) )
  tot <- rep( "sub", times=GN )
  z01 <- rbind( z1,tot )
  dim(z01 ) <- c( (G+1)*GN,1 )
  
  z2 <-  c( regnam, "TOTAL" )
  z02 <- rep( z2,times=GN )
  
  bigrownam <- paste( z01, z02, sep="." )
  
  # define dimensions
  Ad   <- array( 0,dim=c( GN,GN ) )
  Am   <- array( 0,dim=c( GN,GN ) )
  Bd   <- array( 0,dim=c( GN,GN ) )
  Bm   <- array( 0,dim=c( GN,GN ) )
  Y    <- array( 0,dim=c( GN,length( regnam ) ) )
  Yd   <- array( 0,dim=c( GN,length( regnam ) ) )
  Ym   <- array( 0,dim=c( GN,length( regnam ) ) )
  ESR  <- array( 0,dim=c( GN,length( regnam ) ) )
  Eint <- array( 0,dim=c( GN,length( regnam ) ) )
  Efd  <- array( 0,dim=c( GN,length( regnam ) ) )
  
  x <- x[ -c(1,2),-c(1,2) ]
  x <- apply( x, 2, as.numeric )
  AX <- x[ 1:GN, ]
  
  X <- x[ dim(x)[1], ]
  
  #### this might not be the best way to construct V
  V <- X - colSums( AX )
  rm( x )
  gc()
  
  A <- t(t(AX)/X)
  A[ is.na( A ) ] <- 0
  A[ A==Inf ] <- 0
  II <- diag(GN)
  B <- solve( II-A )
  Bm <- B
  Am <- A
  
  for (j in 1:length(regnam) )  {
    m=1+(j-1)*N
    n=N+(j-1)*N
    
    Ad[m:n,m:n]  <- A[m:n,m:n]
    Bd[m:n,m:n]  <- B[m:n,m:n]
    Bm[m:n,m:n]  <- 0
    Am[m:n,m:n]  <- 0
  }
  
  L <- solve( II-Ad )
  Vc <- V/X
  Vc[ is.na( Vc ) ] <- 0
  Vc[ Vc==Inf ] <- 0
  
  Vhat <- diag(GN)
  diag(Vhat) <- Vc
  
  
  # Part 2: computing final demand: Y
  y <- data.matrix( y[3:(GN+2),3:((5*G)+2)] )
  for ( j in 1:length(regnam) ){
    m=1+(j-1)*5
    n=5+(j-1)*5
    Y[ ,j ] <- rowSums( y[,m:n ] )
  }
  Ym <- Y
  
  
  # Part 3: computing export: E, Esr
  E <- cbind( AX,y )
  rm( AX, y )
  gc()
  
  for (j in 1:length(regnam) )  {
    m=1+(j-1)*N
    n=N+(j-1)*N
    E[m:n,m:n]  <- 0   # intermediate demand for domestic goods
  }
  
  for (j in 1:length(regnam))  {
    m=1+(j-1)*N
    n=N+(j-1)*N
    s=GN+1+(j-1)*5
    r=GN+5+(j-1)*5
    E[m:n,s:r]  <- 0  # final demand for domestic goods
    Yd[ m:n,j ] <- Y[m:n,j]
    Ym[ m:n,j ] <- 0
  }
  
  z <- E
  E <- rowSums( E )
  E <- as.matrix( E )
  
  for (j in 1:length(regnam))  {
    m = 1 + (j-1) * N
    n = N + (j-1) * N
    s = GN + 1 + (j-1) * 5
    r = GN + 5 + (j-1) * 5
    ESR[ ,j ] <- rowSums( z[,m:n] ) + rowSums( z[ ,s:r ] )
    Eint[ ,j ] <- rowSums( z[,m:n] )
    Efd[ ,j ] <- rowSums( z[ ,s:r ] )
  }
  
  Exp <- diag(GN)
  diag(Exp) <- rowSums(ESR)
  
  
  # Part 4: naming the rows and columns in variables
  colnames(A)   <-  rownam
  rownames( A )   <- rownam
  dimnames(B)     <- dimnames( A )
  dimnames(Bm)    <- dimnames( A )
  dimnames(Bd)    <- dimnames( A )
  dimnames(Ad)    <- dimnames( A )
  dimnames(Am)    <- dimnames( A )
  dimnames(L)     <- dimnames( A )
  names(Vc)       <- rownam
  names(X)        <- rownam
  colnames(Y)     <- regnam
  rownames( Y )   <- rownam
  dimnames(Ym)    <- dimnames( Y )
  names(E)        <- rownam
  colnames(ESR)   <- regnam
  rownames( ESR ) <- rownam
  dimnames(Eint)  <- dimnames( ESR )
  dimnames(Efd)   <- dimnames( ESR )
  

  # Part 5: creating decompr object
  out <- list( Exp = Exp,
               Vhat = Vhat,
               A = A,
               B = B,
               Ad = Ad,
               Am = Am,
               Bd = Bd,
               Bm = Bm,
               L = L,
               Vc = Vc,
               X = X,
               Y = Y,
               Yd = Yd,
               Ym = Ym,
               E = E,
               ESR = ESR,
               Eint = Eint,
               Efd = Efd,
               G = G,
               N = N,
               GN = GN,
               bigrownam = bigrownam,
               regnam = regnam,
               rownam = rownam,
               secnam = secnam,
               tot = tot,
               z = z,
               z01 = z01,
               z02 = z02,
               z1 = z1,
               z2 = z2
               )
  
  class(out) <- 'decompr'
  
  # Part 6: returning object
  return(out)
  
}