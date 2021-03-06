## This file contains several very important functions needed to 
## properly run select_rho_partial.R, partial_cor.R, non_partial_cor.R, network_display.R and networkVis.R
 

#' @title Compute the correlation
#'
#' @description This function computes either the pearson or spearman correlation coefficient. 
#'      This function is used in non_partial_corr.R 
#' @param data_group_2 This is a n*p matrix
#' @param data_group_1 This is a n*p matrix
#' @param type_of_cor If this is NULL, pearson correlation coefficient will be calculated.
#'   Otherwise, a character string "spearman" will calculate the spearman correlation coefficient.
#'
#' @return A list of correlation matrices for both group 1 and group 2
#'
# Compute Pearson correlation or Spearman correlation
compute_cor <- function(data_group_2, data_group_1, type_of_cor) {
    if (is.null(type_of_cor) || type_of_cor == "pearson") {
        cor_group_2 <- cor(data_group_2, method = "pearson")
        cor_group_1 <- cor(data_group_1, method = "pearson")

    } else if (type_of_cor == "spearman") {
        cor_group_2 <- cor(data_group_2, method = "spearman")
        cor_group_1 <- cor(data_group_1, method = "spearman")
    }
    cor <- list("Group2" = cor_group_2, "Group1" = cor_group_1)
}


#' @title Compute the partial correlation
#'
#' @description Compute the partial correlation coefficient.
#'      This function is used in partial_corr.R 
#' @param pre_inv This is an inverse covariance matrix.
#'
#' @return An \eqn{n * n} partial correlation matrix
#' @importFrom utils tail

# Compute partial correlation
compute_par <- function(pre_inv) {
  p <- nrow(pre_inv)

  i <- rep(seq_len(p - 1), times=(p-1):1)
  k <- unlist(lapply(2:p, seq, p))

  pre_inv_i <- vapply(seq_len(p-1), function(x) pre_inv[x,x], numeric(1))
  pre_inv_i <- rep(pre_inv_i, times=(p-1):1)

  pre_inv_j <- vapply(2:p, function(x) pre_inv[x,x], numeric(1))
  pre_inv_j <- unlist(lapply(seq_len(p), function(x) tail(seq_len(p), -(x))))

  pc_value <- pre_inv[upper.tri(pre_inv)]
  pc_calc <- -pc_value / sqrt(pre_inv_i * pre_inv_j)

  pc <- matrix(0, p, p)
  pc[upper.tri(pc)] <- pc_calc
  pc[lower.tri(pc)] <- t(pc)[lower.tri(t(pc))]
  return(pc)
}



#' @title Permutations to build a differential network using correlation
#'
#' @description A permutation test that randomly permutes the sample labels in distinct
#'     biological groups for each biomolecule. The difference in each paired biomolecule
#'     is considered significant if it falls into the 2.5% tails on either end of the empirical
#'     distribution curve. This function is used in non_partial_corr.R 
#' @param m This is the number of permutations desired.
#' @param p This is the number of biomarker candidates present.
#' @param n_group_1 This is the number of subjects in group 1.
#' @param n_group_2 This is the number of subjects in group 2.
#' @param data_group_1 This is a \eqn{n*p} matrix or data.frame containing group 1 data.
#' @param data_group_2 This is a \eqn{n*p} matrix of data.frame containing group 2 data.
#' @param type_of_cor If this is NULL, pearson correlation coefficient will be calculated by default.
#'     Otherwise, a character string "spearman" will calculate the spearman correlation
#'     coefficient.
#' @importFrom utils txtProgressBar setTxtProgressBar
#'
#' @return A multi-dimensional matrix that contains the permutation results

# Permutation to build differential network using correlation
permutation_cor <- function(m, p, n_group_1, n_group_2, data_group_1, data_group_2, type_of_cor) {
    diff_p <- array(0, dim = c(m, p, p))
    pb <- txtProgressBar(min = 0, max = m, style = 3)
    for (t in 1 : m) {
        data_group_1_p <- matrix(0, n_group_1, p)
        for (i in 1 : p) {
            data_group_1_p[, i] <- data_group_1[sample(n_group_1), i]
        }
        data_group_2_p <- matrix(0, n_group_2, p)
        for (i in 1 : p) {
            data_group_2_p[, i] <- data_group_2[sample(n_group_2), i]
        }

    if (is.null(type_of_cor)) {
        cor_group_2_p <- cor(data_group_2_p, method = "pearson")
        cor_group_1_p <- cor(data_group_1_p, method = "pearson")
    } else {
        cor_group_2_p <- cor(data_group_2_p, method = "spearman")
        cor_group_1_p <- cor(data_group_1_p, method = "spearman")
    }
        diff_p[t, , ] <- cor_group_2_p - cor_group_1_p

        # update progress bar
        setTxtProgressBar(pb, t)
    }
    close(pb)
    return(diff_p)
}


#' @title Permutations to build differential network using partial correlation
#'
#' @description A permutation test that randomly permutes the sample labels in distinct
#'     biological groups for each biomolecule. The difference in paired partial correlation
#'     is considered significant if it falls into the 2.5% tails on either end of the empirical
#'     distribution curve. This function is used in partial_corr.R 
#' @param m This is the number of permutations desired.
#' @param p This is the number of biomarker candidates present.
#' @param n_group_1 This is the number of subjects in group 1.
#' @param n_group_2 This is the number of subjects in group 2.
#' @param data_group_1 This is a \eqn{n*p} matrix or data.frame containing group 1 data.
#' @param data_group_2 This is a \eqn{n*p} matrix of data.frame containing group 2 data.
#' @param rho_group_1_opt This is an optimal tuning parameter to sparse the differential network for group 1
#' @param rho_group_2_opt This is an optimal tuning parameter to sparse the differential network for group 2
#' @importFrom utils txtProgressBar setTxtProgressBar
#'
#' @return A multi-dimensional matrix that contains the permutation results

# Permutation to build differential network using partial correlation
permutation_pc <- function(m, p, n_group_1, n_group_2, data_group_1, data_group_2, rho_group_1_opt, rho_group_2_opt) {
    diff_p <- array(0, dim = c(m, p, p))
    pb <- txtProgressBar(min = 0, max = m, style = 3)
    for(t in 1 : m) {
        data_group_1_p <- matrix(0, n_group_1, p)
        for(i in 1 : p) {
            data_group_1_p[, i] <- data_group_1[sample(n_group_1), i]
        }
        data_group_2_p <- matrix(0, n_group_2, p)
        for(i in 1 : p) {
            data_group_2_p[, i] <- data_group_2[sample(n_group_2), i]
        }
        per_group_1 <- glasso(var(data_group_1_p), rho = rho_group_1_opt)
        per_group_2 <- glasso(var(data_group_2_p), rho = rho_group_2_opt)
        pc_group_1_p <- compute_par(per_group_1$wi)
        pc_group_2_p <- compute_par(per_group_2$wi)
        diff_p[t, , ] <- pc_group_2_p - pc_group_1_p
        # update progress bar
        setTxtProgressBar(pb, t)
    }
    close(pb)
    return(diff_p)
}




#' @title Calculate the positive and negative threshold based on the permutation result
#'
#' @description Calculate the positive and negative threshold based on the permutation result.
#'       This function is used in both partial_cor.R and non_partial_corr.R
#' @param thres_left This is the threshold representing 2.5 percent of the left tail of the empirical
#'     distribution curve.
#' @param thres_right This is the threshold representing 2.5 percent of the right tail of the empirical
#'     distribution curve.
#' @param p This is the number of biomarker candidates present.
#' @param diff_p  This is the permutation results from either permutation_pc or permutation_cor
#'
#' @return A list of the positive and negative thresholds

# Calculate the positive and negative threshold based on the permutation result
permutation_thres <- function(thres_left, thres_right, p, diff_p) {
    significant_thres_p <- matrix(0, p, p)
    significant_thres_n <- matrix(0, p, p)
    for (i in 1 : (p-1)) {
        for (j in (i + 1) : p) {
            significant_thres_n[i, j] <- quantile(diff_p[, i, j], probs = thres_left)
            significant_thres_n[j, i] <- significant_thres_n[i, j]
            significant_thres_p[i, j] <- quantile(diff_p[, i, j], probs = thres_right)
            significant_thres_p[j, i] <- significant_thres_p[i, j]
        }
    }
    significant_thres <- list("positive" = significant_thres_p, "negative" = significant_thres_n)
    return(significant_thres)
}




#' @title Calculate the differential network score
#'
#' @description Calculates a differential network score by using the binary link and z-scores. 
#'      This function is used in both partial_cor.R and non_partial_corr.R
#' @param binary_link This is the binary correlation matrix with 1 indicating positive correlation and -1
#'     indicating negative correlation for each biomolecular pair.
#' @param z_score This was converted from given of calulated p-value.
#'
#' @return An activity score associated with each biomarker candidate

# Calculate differential network score
compute_dns <- function(binary_link, z_score) {
    # get adjacent matrix
    diff_d <- abs(binary_link)
    # set diagonal elements to 1
    diag(diff_d) <- 1
    # compute differential network score for each row
    dns <- apply(diff_d, 1, function(x, y = z_score) sum(y[which(x == 1)]))
    return(dns)
}

#' @title Obtain p-values using logistic regression
#'
#' @description Calculate p-values using logistic regression.
#'      This function is used in both partial_cor.R and non_partial_corr.R in cases where p-values are not provided
#' @param x This is a data frame consists of data from group 1 and group 2.
#' @param class_label This is a binary array indicating 0 for group 1 and 1 for group 2.
#' @param Met_name This is an array of IDs.
#'
#' @return p-values

pvalue_logit <- function(x, class_label, Met_name) {
    data_tp <- as.data.frame(t(x))    # n*p
    class_label_tp <- as.data.frame(t(class_label))
    # attach metabolites ID and class label in the data set
    X_df <- cbind(data_tp, class_label_tp)
    colnames(X_df)[1:(ncol(X_df)-1)] <- Met_name
    colnames(X_df)[ncol(X_df)] <- "Class"
    glm.fit <- glm(Class ~. , family = "binomial", data = X_df)
    ## Sort metabolites based on their p-values
    pvalue <- summary(glm.fit)$coefficients[,4][2:ncol(X_df)]
    pvalue_df <- data.frame("ID" = Met_name, "p.value" = pvalue)
    return(pvalue_df)
}



#' @title Create log likelihood error function
#'
#' @description Calculates the log likelihood error function. This function is 
#'      used inside the function choose_rho found below. 
#' @param data This is a matrix or data.frame.
#' @param theta This is a precision matrix.
#'
#' @return log likelihood error function

# Create log likelihood error function
loglik_ave <- function(data, theta){
    loglik <- c()
    loglik <- log(det(theta)) - sum(diag(var(data) %*% theta))
    return(-loglik)
}





#' @title Generating a list of errors and their corresponding \eqn{log(rho)} values
#'
#' @description This functions output is later used to draw an error curve using cross-validation. 
#'          This function is used in select_rho_partial.R to help visualize 
#'          the error curve for both group 1 and 2 in the data preprocessing step
#' @param data This is a matrix.
#' @param n_fold This parameter specifies the n to n-fold cross_validation.
#' @param rho This is the multiple regularization parameter values used to evaluate in terms of errors.
#'
#' @return a list of errors and their corresponding \eqn{log(rho)}

# Draw error curve
choose_rho <- function(data, n_fold, rho) {
  # randomly shuffle the data
  Data <- data[sample(nrow(data)), ]
  # create n_fold equally size folds
  folds <- cut(seq(1, nrow(Data)), breaks = n_fold, labels = FALSE)
  # tune parameters
  d <- ncol(Data)

  loglik <- lapply(seq_along(rho), function(i) {
    vapply(seq_len(n_fold), function(j) {
      # segement your data by fold using the which() function
      testIndexes <- which(folds == j, arr.ind = TRUE)
      testData <- Data[testIndexes, ]
      trainData <- Data[-testIndexes, ]
      # use test and train data partitions however you desire...
      cov <- var(trainData) # compute the covariance matrix
      pre<- glasso(cov, rho = rho[i])
      loglik_ave(testData, pre$wi)
    }, numeric(1))})

  loglik_cv <- vapply(loglik, mean, numeric(1))
  loglik_rho <- vapply(loglik, function(x) sd(x) / sqrt(n_fold), numeric(1))

  #plot(rho, loglik_cv, xlab = expression(lambda), ylab = "Error")
  #lines(rho, loglik_cv)
  error <- list("log.cv" = loglik_cv, "log.rho" = loglik_rho)
  return(error)
}        
                       
#' @title Scale list of numbers
#'
#' @description This function is used to help spread out data values across 0 to 1. This is so that it 
#'              will be easier to distinguish values later incorporated into the network_display function 
#'
#' @param x This is a list of numbers taken form on the columns outputted from calling patial_corr.R or non_partial_corr.R
#'
#' @return Scaled version of data that fits between 0 to 1

# Rescaling data points
scale_range <- function(x){(x-min(x))/(max(x)-min(x))}


#' @title Color Bar
#'
#' @description This function creates a customized color bar optimized to be used in network_display.R
#'               
#' @param lut This is a hue range that will be used to display the same color gradient 
#'             used to fill in the nodes in the network display
#' @param min This is an integer representing the starting point of the labled color gradient. 
#'             It is also used for scaling purposes when setting the dimentions of the color bar
#' @param max This is an integer representing the ending point of the labled color gradient. 
#'             It is also used for scaling purposes when setting the dimentions of the color bar
#' @param nticks This is the number of tick marks the user would like to be displayed across the color bar
#' @param ticks This is a sequence with a length of 'nticks' which ranges from min to max evenly spaced
#' @param title This is the title that is desired to be displayed based on what data parameters were inputted
#'
#' @return A horizontal color bar representative of the inputted data

# Function to plot a horizontal color bar  
color.bar <- function(lut, min, max=-min, nticks=5, ticks=seq(min, max, len=nticks), title='') {
  scale = (length(lut)-1)/(max-min)

  plot(c(ceiling(max(max)),0), c(4,min), type='n', bty='n', xaxt='n', xlab='', yaxt='n', ylab='', main=title)
  axis(1, ticks, las=1)
  for (i in 1:(length(lut)-1)) {
    y = (i-1)/scale + min
    rect(y,0,y+1/scale, 3, col=lut[i], border=NA)
  }
}
