#!bin/bash

debug.cross <- T
source("/home/jmiller1/QTL_Map_Raw/popgen/rQTL/scripts/QTL_remap/MAP/control_file.R")

dirso <- "/home/jmiller1/QTL_Map_Raw/popgen/rQTL/data/"


pops <- list("NBH", "NEW", "ELR")

marks <- lapply(pops, function(pop) {
  
  ## Directories
  basedir <- "/home/jmiller1/QTL_Map_Raw/popgen"
  plotdir <- file.path(basedir, "rQTL/plots")
  indpops <- file.path(basedir, "plinkfiles/ind.pops")
  popdir <- file.path(basedir, "rQTL", pop, "REMAPS")
  qtldir <- file.path(basedir, "rQTL/remap_out")
  errfile <- file.path(qtldir, "genotyping_error_rate.txt")
  
  cross.18 <- read.cross.jm(file = file.path(indpops, paste(pop, ".unphased.f2.csvr", 
    sep = "")), format = "csvr", geno = c(1:3), estimate.map = FALSE)
  
  ### Pull names from plinkfile
  path <- file.path(indpops, paste(pop, ".ped", sep = ""))
  popname <- system(paste("cut -f1 -d' '", path), intern = TRUE)
  indname <- system(paste("cut -f2 -d' '", path), intern = TRUE)
  cross.18$pheno$ID <- paste(popname, indname, sep = "_")
  
  ## Subset and drop parents
  return(subset(cross.18, ind = is.na(cross.18$pheno$Phen)))
})

### All BLI GPs
BLI <- c(subset(marks[[1]], ind = "NBH_NBH1M"), subset(marks[[2]], ind = "NEW_NEW911M"), 
  subset(marks[[3]], ind = "BLI_BI1124M"))
gt.BLI <- geno.table(BLI)

TOL <- c(subset(marks[[1]], ind = "NBH_NBH1F"), subset(marks[[2]], ind = "NEW_NEW911F"), 
  subset(marks[[3]], ind = "ELR_ER1124F"))
gt.TOL <- geno.table(TOL)

### Ind pops ###

BLI.N <- c(subset(marks[[1]], ind = "NBH_NBH1M"), subset(marks[[2]], ind = "NEW_NEW911M"))
gt.BLI.N <- geno.table(BLI.N)

BLI.S <- subset(marks[[3]], ind = "BLI_BI1124M")
gt.BLI.S <- geno.table(BLI.S)

### Each tolerant GPs
TOL.N <- c(subset(marks[[1]], ind = "NBH_NBH1F"), subset(marks[[2]], ind = "NEW_NEW911F"))
gt.TOL.N <- geno.table(TOL.N)

### Alleles to switch in north:
flip.north.B <- rownames(gt.BLI.N[which(gt.BLI.N$AA == 2), ])
flip.north.A <- rownames(gt.TOL.N[which(gt.TOL.N$BB == 2), ])
toSwitch <- c(flip.north.B, flip.north.A)

fileConn <- file(file.path(dirso, "toSwitch.N.txt"))
writeLines(toSwitch, fileConn)
close(fileConn)



#### Low cov ELR indivdual
TOL.S <- subset(marks[[3]], ind = "ELR_ER1124F")
gt.TOL.S <- geno.table(TOL.S)

### Dump vec #####

s.index <- which(gt.TOL.S$AB > 0 | gt.BLI.S$AB > 0)
elr.dump <- unique(rownames(gt.TOL.S)[s.index])

n.index <- which(gt.TOL.N$AB > 0 | gt.BLI.N$AB > 0)
nor.dump <- unique(rownames(gt.TOL.N)[n.index])

fileConn <- file(file.path(dirso, "nor.dump.txt"))
writeLines(nor.dump, fileConn)
close(fileConn)

fileConn <- file(file.path(dirso, "elr.dump.txt"))
writeLines(elr.dump, fileConn)
close(fileConn)

#### Switching phase of markers based on g.parent GTs
toB <- rownames(gt.BLI[which(gt.BLI$AA >= 1 & gt.BLI$missing >= 0 & gt.BLI$BB == 
  0), ])
toA <- rownames(gt.TOL[which(gt.TOL$BB >= 1 & gt.TOL$missing >= 0 & gt.TOL$AA == 
  0), ])
toSwitch <- c(toB, toA)

fileConn <- file(file.path(dirso, "toSwitch.txt"))
writeLines(toSwitch, fileConn)
close(fileConn)


if (pop == "ELR") {
  ### Better set for ELR
  not.het <- rownames(gt.BLI)[which(gt.BLI$AB == 0 & gt.BLI$AA >= 2 | gt.BLI$AB == 
    0 & gt.BLI$BB >= 2)]
  ### Each tolerant GPs
  SOc <- c(subset(marks[[3]], ind = "BLI_BI1124M"), subset(marks[[3]], ind = "ELR_ER1124F"))
  SO <- geno.table(SOc)
  SO.mis.A <- rownames(SO)[which(SO$missing == 1 & SO$AB == 0 & SO$AA == 1 & SO$BB == 
    0)]
  SO.mis.B <- rownames(SO)[which(SO$missing == 1 & SO$AB == 0 & SO$AA == 0 & SO$BB == 
    1)]
  
  SO.ok <- rownames(SO)[which(SO$AA == 1 & SO$BB == 1)]
  BBfix <- rownames(gt.BLI)[which(gt.BLI$BB[SO.mis.A] == 2)]
  AAfix <- rownames(gt.BLI)[which(gt.BLI$AA[SO.mis.B] == 2)]
  SO.bm <- rownames(SO)[which(SO$missing == 2)]
  bmfix <- rownames(gt.BLI)[gt.BLI[SO.bm, 3] >= 2 | gt.BLI[SO.bm, 5] >= 2]
  onlythese <- c(SO.ok, BBfix, AAfix, bmfix)
  
  fileConn <- file(file.path(dirso, "elr.down.txt"))
  writeLines(onlythese, fileConn)
  close(fileConn)
}




SOc <- c(subset(marks[[3]], ind = "BLI_BI1124M"), subset(marks[[3]], ind = "ELR_ER1124F"))
SO <- geno.table(SOc)
SO.d.1 <- rownames(SO)[which(SO$AB >= 1)]
SO.d.2 <- rownames(SO)[which(SO$AA > 1 | SO$BB > 1)]
justdrop <- c(SO.d.1, SO.d.2)

fileConn <- file(file.path(dirso, "elr.down.txt"))
writeLines(justdrop, fileConn)
close(fileConn)


SOc <- subset(cross.pars, ind = "BLI_BI1124M")
gtp <- geno.table(SOc)
swit <- rownames(gtp[gtp$AA == 1, ])
cross.18 <- switchAlleles(cross.18, markers = swit)

#### done####



cross.18 <- read.cross.jm(file = file.path(indpops, paste(pop, ".unphased.f2.csvr", 
  sep = "")), format = "csvr", geno = c(1:3), estimate.map = FALSE)

### Pull names from plinkfile
path <- file.path(indpops, paste(pop, ".ped", sep = ""))
popname <- system(paste("cut -f1 -d' '", path), intern = TRUE)
indname <- system(paste("cut -f2 -d' '", path), intern = TRUE)
cross.18$pheno$ID <- paste(popname, indname, sep = "_")
cross.pars <- subset(cross.18, ind = "BLI_BI1124M")
gtp <- geno.table(cross.pars)
swit <- rownames(gtp[gtp$AA == 1, ])

cross.pars <- switchAlleles(cross.pars, markers = swit)
cross.18 <- switchAlleles(cross.18, markers = swit)
gtp <- geno.table(cross.pars)
cross.check <- subset(cross.18, ind = "ELR_10876")
gtc <- geno.table(cross.check)
BB_10876 <- intersect(rownames(gtc[gtc$BB == 1, ]), rownames(gtp[gtp$BB == 1, ]))
gtm <- geno.table(subset(crOb, ind = "ELR_10876"))
gtp <- gtp[which(gtp$BB == 1), ]
swits <- rownames(gtp[which(gtp$BB == 1), ])

sapply(1:24, function(X) {
  
  c(sum(rownames(gtm[which(gtm$chr == X), ]) %in% rownames(gtp))/length(rownames(gtm[which(gtm$chr == 
    X), ])), sum(rownames(gtm[which(gtm$chr == X), ]) %in% rownames(gtp)))
})
