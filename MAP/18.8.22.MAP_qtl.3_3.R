#!/bin/R

### Map QTLs 3 of 3
source("/home/jmiller1/QTL_Map_Raw/popgen/rQTL/scripts/QTL_remap/MAP/control_file.R")

# load(paste(popdir,'/chr',X,'_',outname,'.QTLmap.Rsave',sep=''))

cross.18 <- read.cross(format = "csv", dir = popdir, file = paste("chr", X, "_", 
  outname, "_2.QTLmap.csv", sep = ""), geno = c("AA", "AB", "BB"), alleles = c("A", 
  "B"))

marker.warning()

print(summary(pull.map(cross.18))[as.character(X), ])

print("dropping markers by error lod")

print("2nd time removing double cross-overs")
cross.18 <- removeDoubleXO(cross.18, verbose = T)
print("Done removing dxo..")

dups <- findDupMarkers(cross.18, exact.only = FALSE, adjacent.only = FALSE)
### remove markers that are exactly the same.
cross.18 <- drop.markers(cross.18, unlist(dups))

if (reorder.marks == T) {
  print("Re-setimating map from filtered data on")
  cross.18 <- orderMarkers(cross.18, chr = X, window = 5, use.ripple = T, error.prob = 0.025, 
    map.function = "kosambi", sex.sp = F, maxit = 10000, tol = 0.001)
} else if (hoods == T) {
  ripLod <- ripple(cross.18, chr = X, window = 4, method = "likelihood", error.prob = 0.01, 
    map.function = "kosambi", maxit = 2000, tol = 1e-06, sex.sp = FALSE, verbose = TRUE, 
    n.cluster = slurmcore)
  new.ord <- ripLod[which.max(ripLod[, "LOD"]), ]
  cross.18 <- switch.order(cross.18, X, new.ord)
  png(file.path(popdir, paste(X, "_order.png", sep = "")))
  plot(gsub(paste(X, ":", sep = ""), "", markernames(cross.18)), main = "position")
  dev.off()
} else if (reprip == T) {
  cross.18 <- repRipple.jm(cross = cross.18, chr = X, error.prob = 0.05, map.function = "kosambi", 
    window = 4)
}

print(summary(pull.map(cross.18))[as.character(X), ])

print("plotting LOD matrix")
png(file.path(popdir, paste(X, "_RF_FINAL.png", sep = "")))
plotRF(cross.18, chr = chrnames(cross.18)[1], what = "both", mark.diagonal = T, col.scheme = "redblue")
dev.off()

print("Re-estimating the final map with many iterations...")
POS.map.18 <- est.map(cross.18, error.prob = 0.01, map.function = "kosambi", chr = X, 
  maxit = 10000)
cross.18 <- replace.map(cross.18, POS.map.18)
print("Done mapping..")

print(summary(pull.map(cross.18))[as.character(X), ])

vec <- as.numeric(gsub(paste(X, ":", sep = ""), "", markernames(cross.18)))

print(paste("physical positions from", min(vec), "to", max(vec)))

print("Re-estimating error rate for QTL mapping")
ers <- er.rate(cross = cross.18, cpus = slurmcore, maxit = 1000)
print(paste(ers, " error rate"))

### Add phenotype cross.18$pheno$Pheno_05 <- cross.18$pheno$Pheno
### cross.18$pheno$Pheno <- trsl.bin[as.character(cross.18$pheno$Pheno_05)]

print("Re-writing the markers to rQTL format")
write.cross(cross.18, filestem = paste(popdir, "/chr", X, "_", outname, "_3.QTLmap", 
  sep = ""), format = "csv", chr = X)

rm(cross.18)

save.image(paste(popdir, "/chr", X, "_", outname, ".QTLmap.Rsave", sep = ""))
