#!/usr/bin/env Rscript

library(circlize)
library(ComplexHeatmap)
library(RColorBrewer)

fill_cn_data_chroms = function(data, chrom_colname, expected_chroms){
  data_chroms = unique(data$chrom_colname)
  chroms_to_add = expected_chroms[! expected_chroms %in% data_chroms]
  for (chrom in chroms_to_add){ 
    r = nrow(data)+1
    data[r,"LogRatio"] = 0
    data[r,"Position"] = 0
    data[r,"state"] = 0
    data[r,"Chr"] = chrom
  
  }
  return(data)
}

#plot remixt
plot_remixt = function(copy_number, gene_annotations){
  chroms_needed = c(1:22, "X")

  copy_number[copy_number$major_raw > 8, ]$major_raw = 9
  copy_number[copy_number$minor_raw > 8, ]$minor_raw = 9
  
  circos.track(factors= paste0("chr", copy_number$chromosome), ylim=c(0, 8), x=copy_number$start, "track.height" = 0.15,
               panel.fun = function(x, y) {
                 for (state in 0:8){
                   circos.lines(c(0, max(x)), c(state, state), col = "gray")
                 }
               })
  cn_combined = copy_number
  cn_combined["combined"] = cn_combined$major_raw + cn_combined$minor_raw
  cn_combined = cn_combined[cn_combined$combined <= 8,]
  
  circos.trackPoints(factors= paste0("chr", cn_combined$chromosome),  
                     x = cn_combined$start, y = cn_combined$combined, cex = 0.1, col = "black")
  
  
  circos.track(factors= paste0("chr", copy_number$chromosome), ylim=c(0, 8), x=copy_number$start, "track.height" = 0.15,
               panel.fun = function(x, y) {
                 for (state in 0:8){
                   circos.lines(c(0, max(x)), c(state, state), col = "gray")
                 }
               })
  circos.trackPoints(factors= paste0("chr", copy_number$chromosome),  
                     x = copy_number$start, y = copy_number$major_raw, cex = 0.1, col = "red")
  
  circos.trackPoints(factors= paste0("chr", copy_number$chromosome),  
                     x = copy_number$start, y = copy_number$minor_raw, cex = 0.1, col = "blue")
}




#add a copy number track to the circos plot
#copy_number -> copy number data.frame
#gene_annotations -> gene_annotations data.frame
plot_copy_number = function(copy_number, gene_annotations){
  cnCol <- c("#00FF00", "#006400", "#0000FF", "#880000",
             "#BB0000", "#CC0000", "#DD0000", "#EE0000", rep("#FF0000",493))
  names(cnCol) <- c(0:500)
  chroms_needed = c(1:22, "X")
  if (! all (chroms_needed %in% copy_number$Chr)){
    copy_number = fill_cn_data_chroms(copy_number, "Chr", chroms_needed)
  }

  circos.track(factors= paste0("chr", copy_number$Chr), ylim=c(-4, 6), x=copy_number$Position, "track.height" = 0.15,
               panel.fun = function(x, y) {
                 for (state in -4:6){
                   circos.lines(c(0, max(x)), c(state, state), col = "#00000040")
                 }
               })

    for (state in unique(copy_number$state)){
    x = copy_number$Position[copy_number$state == state]
    y = copy_number$LogRatio[copy_number$state == state]
    f = copy_number$Chr[copy_number$state == state]
    col = cnCol[state+1]
    circos.trackPoints(factors= paste0("chr", f),  x = x, y = y, cex = 0.1, col=col)
  }

}

#add the svs to the circos plot as links
#svs -> data.frame of breakpoints
plot_svs = function(svs, palette){
  if (! nrow(svs)){
    return()
  }
  print(palette)
  for (sv in 1:nrow(svs)){
    chr1 = paste0("chr", svs[sv, "chromosome_1"])
    chr2 = paste0("chr", svs[sv, "chromosome_2"])
    p1 =  svs[sv, "position_1"]
    p2 =  svs[sv, "position_2"]
    color = palette[svs[sv, "rearrangement_type"]]

    if (chr1 == "chrY" | chr2 == "chrY"){
      next
    }

    circos.link(chr1, p1, chr2, p2, col = color, h.ratio=0.7)
    
  }
}

#add a legend to the plot
add_legend = function(palette, remixt, titan){
  
  if (titan){
    titan_colors =  c("#00FF00", "#006400", "#0000FF", "#880000",
                      "#BB0000", "#CC0000", "#DD0000", "#EE0000", "#FF0000")
    names(titan_colors) = c("1", "2", "3", "4", "5", "6", "7", "8", "9+")
    
    cn_leg = Legend(labels = rev(names(titan_colors)), type = "points", 
                 legend_gp = gpar(col = rev(titan_colors), lwd = 2), title_position = "topleft", 
                 title = "Titan State")
    
    
    cn_states = Legend(labels = c("Titan LogRatio (-4 - 6)"), type="lines",
                       legend_gp=gpar(col=c("gray"), lwd=2), 
                       title_position = "topleft")
  }
  
  if (remixt){
    cn_leg = Legend(labels = c("major + minor","major", "minor"), type="points",
                  legend_gp=gpar(col=c("black","red", "blue"), lwd=2), 
                  title_position = "topleft", title = "Remixt")
    
    cn_states = Legend(labels = c("Copy Number State (0 - 8+)"), type="lines",
                       legend_gp=gpar(col=c("gray"), lwd=2), 
                       title_position = "topleft")
  }
  

  cn_leg = packLegend(cn_leg, cn_states)
  
  
  svs = Legend(labels = names(palette), type = "points", 
               legend_gp = gpar(col = palette, lwd = 2), title_position = "topleft", 
               title = "Structural Variants")
  
  draw(cn_leg, x = unit(4, "mm"), y = unit(4, "mm"), just = c("left", "bottom"))
  draw(svs, x = unit(1, "npc") - unit(2, "mm"), y = unit(4, "mm"), 
       just = c("right", "bottom"))
  
  
  #draw(gene_annotations,x = unit(1, "cm"), y = unit(1, "cm"), just = c("left", "top"))
  
  
}

#initialize a circos plot and fill with copy number ring, svs and legend
#copy_number -> copy number data.frame
#annotations -> gene annotations data.frame
#svs -> sv data.frame
circos_plot_titan = function(titan, annotations, svs, label){
  require(circlize)
  
  circos.initializeWithIdeogram(chromosome.index = paste0("chr", c(1:22, "X")))
  palette = brewer.pal(length(f), "Set2")
  names(palette) = c("duplication", "deletion", "unbalanced", "balanced", "foldback", "inversion")
  
  plot_copy_number(titan, annotations)
  plot_svs(svs, palette)
  circos.clear()
  par(family="sans")
  add_legend(palette, FALSE, TRUE)
  title(label)
}


circos_plot_remixt = function(remixt, annotations, svs, label){
  require(circlize)
  
  circos.initializeWithIdeogram(chromosome.index = paste0("chr", c(1:22, "X")))
  palette = brewer.pal(length(f), "Set2")
  names(palette) = c("duplication", "deletion", "unbalanced", "balanced", "foldback", "inversion")
  
  plot_remixt(remixt, annotations)
  plot_svs(svs, palette)
  circos.clear()
  par(family="sans")
  add_legend(palette, TRUE, FALSE)
  title(label)
}

circos_plot = function(titan, remixt, annotations, svs, label){
  require(circlize)
  
  circos.initializeWithIdeogram(chromosome.index = paste0("chr", c(1:22, "X")))
  palette = brewer.pal(length(f), "Set2")
  names(palette) = c("duplication", "deletion", "unbalanced", "balanced", "foldback", "inversion")
  plot_copy_number(titan, annotations)
  
  plot_remixt(remixt, annotations)
  plot_svs(svs, palette)
  circos.clear()
  par(family="sans")
  add_legend(palette, TRUE, FALSE)
  title(label)
}

#make a pdf and write circos plot to it
#copy_number -> copy number data.frame
#annotations -> gene annotations data.frame
#svs -> sv data.frame
#outfile -> path for output pdf file
make_circos_remixt = function(copy_number, annotations, svs, outfile, sample_label){
  
  #save plot to pdf
  pdf(outfile, 8, 9)
  
  #create plot
  circos_plot_remixt(copy_number, annotations, svs, sample_label)
  
  #turn off pdf
  dev.off()
  
}

make_circos = function(titan, remixt, annotations, svs, outfile, sample_label){
  
  #save plot to pdf
  pdf(outfile, 8, 9)
  
  #create plot
  circos_plot(titan, remixt, annotations, svs, sample_label)

  #turn off pdf
  dev.off()
  
}


make_circos_titan = function(copy_number, annotations, svs, outfile, sample_label){
  
  #save plot to pdf
  pdf(outfile, 8, 9)
  
  #create plot
  circos_plot_titan(copy_number, annotations, svs, sample_label)

  #turn off pdf
  dev.off()
  
}


args <- commandArgs(TRUE)
titan <- read.csv(args[1], sep = "\t")
remixt <- read.csv(args[2], sep = "\t")
annotations <- read.csv(args[3], sep = "\t")
sv_calls <- read.csv(args[4], colClasses=c("rearrangement_type"="character"))
remixt_name <- args[4]
titan_name <- args[4]
sample_id <- args[4]

make_circos_remixt(remixt, annotations, sv_calls, remixt_name, sample_id)
make_circos_titan(titan, annotations, sv_calls, titan_name, sample_id)
