% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/helper_function.R
\name{permutation_cor}
\alias{permutation_cor}
\title{Permutations to build a differential network using correlation}
\usage{
permutation_cor(m, p, n_group_1, n_group_2, data_group_1, data_group_2,
  type_of_cor)
}
\arguments{
\item{m}{This is the number of permutations desired.}

\item{p}{This is the number of biomarker candidates present.}

\item{n_group_1}{This is the number of subjects in group 1.}

\item{n_group_2}{This is the number of subjects in group 2.}

\item{data_group_1}{This is a \eqn{n*p} matrix or data.frame containing group 1 data.}

\item{data_group_2}{This is a \eqn{n*p} matrix of data.frame containing group 2 data.}

\item{type_of_cor}{If this is NULL, pearson correlation coefficient will be calculated by default.
Otherwise, a character string "spearman" will calculate the spearman correlation
coefficient.}
}
\value{
A multi-dimensional matrix that contains the permutation results
}
\description{
A permutation test that randomly permutes the sample labels in distinct
    biological groups for each biomolecule. The difference in each paired biomolecule
    is considered significant if it falls into the 2.5% tails on either end of the empirical
    distribution curve. This function is used in non_partial_corr.R
}
