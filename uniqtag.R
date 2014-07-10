library(lattice)

# Read the data
data <- read.delim('uniqtag.tsv',
	colClasses = c(A = 'factor', B = 'factor'))

# Plot a stacked bar chart of the Venn diagrams
png('ensembl.png',
	width = 450, height = 300)
barchart(A ~ Both + Only.A + Only.B, data,
	stack = TRUE,
	auto.key = list(space = 'bottom', columns = 3),
	#main = 'Intersection of UniqTag identifiers between\nolder builds of the Ensembl human genome\nand the current build 75',
	xlab = 'Number of common and different UniqTags\n',	
	ylab = 'Older Ensembl build')
dev.off()
