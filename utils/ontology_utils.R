# Version info: Bioconductor version 3.11 (BiocManager 1.30.10), R 4.0.1 (2020-06-06)
# Author iwasakishuto
# Date 2020-06-12

source("generic_utils.R")
qlibrary(clusterProfiler)
qlibrary(DOSE)
qlibrary(GOplot)
qlibrary(BiocManager)
qlibrary(RDAVIDWebService)
qlibrary(org.Hs.eg.db)
qlibrary(biomaRt)

enrichGOdotplot <- function(gene, OrgDb, keyType="ENTREZID", pvalueCutoff=0.05,
                           pAdjustMethod="BH", universe, qvalueCutoff=0.2,
                           minGSSize=10, maxGSSize=500, readable=FALSE,
                           width=14, height=8, title="", filename=NULL){
  if (FALSE){
    paste("Create a enrichGO dotplot.",
          "@reference : https://www.rdocumentation.org/packages/clusterProfiler/versions/3.0.4/topics/enrichGO",
          "=========================================================",
          "@params gene          : a vector of entrez gene id.",
          "@params OrgDb         : OrgDb",
          "@params keyType       : keytype of input gene",
          "@params pvalueCutoff  : Cutoff value of pvalue.",
          "@params pAdjustMethod : one of 'holm', 'hochberg', 'hommel', 'bonferroni', 'BH', 'BY', 'fdr', 'none'",
          "@params universe      : background genes",
          "@params qvalueCutoff  : qvalue cutoff",
          "@params minGSSize     : minimal size of genes annotated by Ontology term for testing.",
          "@params maxGSSize     : maximal size of genes annotated for testing",
          "@params readable      : whether mapping gene ID to gene Name")
  }
  options(repr.plot.width=width, repr.plot.height=height)
  df.all <- data.frame()
  subontologies <- c("MF", "BP", "CC")
  for (ont in subontologies){
    ego <- enrichGO(gene=gene, OrgDb=OrgDb, keyType=keyType, ont=ont,
                    pvalueCutoff=pvalueCutoff, pAdjustMethod=pAdjustMethod,
                    universe=universe, qvalueCutoff=qvalueCutoff,
                    minGSSize=minGSSize, maxGSSize=maxGSSize,
                    readable=readable, pool=pool)
    df.ego <- as.data.frame(ego)
    if (nrow(df.ego)>0){
      df.ego$SampleGroup <- ont
      df.all <- rbind(df.all, df.ego)
    }
  }
  df.all.nrow <- nrow(df.all)
  if (df.all.nrow>0){
    df.all <- fraction2float(df=df.all, colname="GeneRatio")
    df.all$negLog10_Qvalue <- -log10(df.all$qvalue)
    df.all$label <- paste(df.all$ID, df.all$Description)
    df.all$label <- factor(df.all$label, levels=df.all$label[order(df.all$SampleGroup, df.all$GeneRatio)])
    fig <- ggplot() +
    geom_point(data=df.all, mapping=aes(x=GeneRatio, y=label, shape=SampleGroup, color=negLog10_Qvalue, size=Count)) +
    ggtitle(label=title, subtitle=waiver()) +
    scale_colour_gradient(low="blue", high="red")
    if (is.null(NULL)==FALSE){
      ggsave(filename, width=width, height=height)
    }
    return (fig)
  }else{
    print("enrichGO returns nothing.")
  }
}

myggsave <- function(filename){
  ggsave(filename, width=14, height=8)
}

geneSYMBOL2EGID <- function(gene_symbols){
  # Convert GeneSYMBOL to ENTREZ_GENE_ID
  ENTREZ_GENE_IDs <- mget(x=gene_symbols, envir=revmap(org.Hs.egSYMBOL), ifnotfound=NA)
  return (as.character(ENTREZ_GENE_IDs))
}

EGID2KEGGID <- function(ENTREZ_GENE_IDs, expand=FALSE){
  KEGG_IDs <- mget(x=ENTREZ_GENE_IDs, envir=org.Hs.egPATH, ifnotfound=NA)
  if (expand){
    KEGG_chars <- character()
    i <- 1
    for (kegg_id in KEGG_IDs){
      for (ids in kegg_id){
        for (id in ids){
          if (is.na(id) == FALSE){
            KEGG_chars[i] <- id
            i <- i+1
          }
        }
      }
    }
    KEGG_chars <- as.character(as.integer(KEGG_chars))
    return (unique(KEGG_chars))
  }else{
    return (KEGG_IDs)
  }
}

geneSYMBOL2KEGGID <- function(gene_symbols, expand=FALSE){
  if (FALSE){
    paste("To get the KEGG IDs associated with a particular gene symbol you ",
          "must first convert the gene symbols from the `org.Hs.eg.db` package into ",
          "Entrez Gene IDs. There are two reasons for this.",
          "   1. we never want to use gene symbols as primary identifiers because they are not unique.",
          "   2. the `org.Hs.eg.db` package is Entrez Gene centric.",
          "So if you have an Entrez Gene ID, then you can get to every other ",
          "piece of information in the `org.Hs.eg.db` package database.",
          "===================================================================",
          "function: mget",
          "@params x          : A vector of variable names (or keys)",
          "@params envir      : Where to look for the key(s).",
          "@params mode       : the mode or type of object sought",
          "@params ifnotfound : a list of values to be used if the item is not found",
          "@params inherits   : should the enclosing frames of the environment be searched?",
        )
  }
  ENTREZ_GENE_IDs = geneSYMBOL2EGID(gene_symbols)
  KEGG_IDs = EGID2KEGGID(ENTREZ_GENE_IDs, expand=expand)
  return (KEGG_IDs)
}

miRBaseID2ENSEMBL <- function(mirBaseIDs){
  db  <- useMart("ensembl")
  hg  <- useDataset("hsapiens_gene_ensembl", mart=db)
  res <- getBM(attributes = c("mirbase_id", "ensembl_gene_id"),
               filters = c("mirbase_id"), 
               values = mirBaseIDs,
               mart = hg)
  return (res$ensembl_gene_id)
}

miRBaseID2KEGG <- function(mirBaseIDs){
  db  <- useMart("ensembl")
  hg  <- useDataset("hsapiens_gene_ensembl", mart=db)
  res <- getBM(attributes = c("mirbase_id", "kegg_enzyme"),
               filters = c("mirbase_id"), 
               values = mirBaseIDs,
               mart = hg)
  return (res$kegg_enzyme)
}
