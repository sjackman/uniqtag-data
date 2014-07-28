# The supplementary material for the UniqTag paper
# UniqTag: Content-derived unique and stable identifiers for gene annotation
# Copyright 2014 Shaun Jackman

# Download the data, compute the results and render the figures and report
all: uniqtag.tsv uniqtag.html

# Remove all computed files
clean:
	rm -f *.comm *.gene *.id *.seq *.sort *.tsv *.uniqtag *.venn

# Install dependencies
install-deps: /usr/local/bin/brew
	brew install coreutils imagemagick r seqtk uniqtag wget

# Check for Homebrew
/usr/local/bin/brew:
	@if brew --version >/dev/null 2>/dev/null; then \
		echo Install Homebrew http://brew.sh/ or Linuxbrew http://brew.sh/linuxbrew/; \
	fi

.PHONY: all clean install-deps
.DELETE_ON_ERROR:
.SECONDARY:

# Download Ensembl Human genome NCBI36 build 40
Homo_sapiens.NCBI36.40.pep.all.fa.gz:
	wget ftp://ftp.ensembl.org/pub/release-40/homo_sapiens_40_36b/data/fasta/pep/Homo_sapiens.NCBI36.40.pep.all.fa.gz

# Download Ensembl Human genome NCBI36 build 45
Homo_sapiens.NCBI36.45.pep.all.fa.gz:
	wget ftp://ftp.ensembl.org/pub/release-45/homo_sapiens_45_36g/data/fasta/pep/Homo_sapiens.NCBI36.45.pep.all.fa.gz

# Download Ensembl Human genome NCBI36
Homo_sapiens.NCBI36.%.pep.all.fa.gz:
	wget ftp://ftp.ensembl.org/pub/release-$*/fasta/homo_sapiens/pep/Homo_sapiens.NCBI36.$*.pep.all.fa.gz

# Download Ensembl Human genome GRCh37
Homo_sapiens.GRCh37.%.pep.all.fa.gz:
	wget ftp://ftp.ensembl.org/pub/release-$*/fasta/homo_sapiens/pep/Homo_sapiens.GRCh37.$*.pep.all.fa.gz

# Uncompress FASTA and remove line breaks
%.fa: %.fa.gz
	seqtk seq $< >$@

# Remove the headers from a FASTA file
%.seq: %.fa
	grep -v '^>' $< >$@

# Convert a FASTA file to sorted TSV of ID, gene name and sequence
%.all.fa.tsv: %.all.fa
	awk -vORS='' '{print $$1 "\t" $$4; getline; print "\t" $$0 "\n" }' $< |sort -k2,2 -k1 >$@

# Keep the lowest-numbered protein for each gene
%.uniqgenemin.fa: %.fa.tsv
	awk 'x[$$2]++ == 0 { print $$1 " " $$2 "\n" $$3 }' $< >$@

# Join all protein isoforms separated by tilde
%.allgene.fa: %.fa.tsv
	awk 'x[$$2]++ == 0 { print $$1 " " $$2 "\n" $$3; next } \
		{ print "~" $$3 }' $< |seqtk seq - >$@

# Keep the first protein isoform in the FASTA file
%.uniqgene.fa: %.fa
	awk 'x[$$4]++ == 0 { print; getline; print; next } { getline }' $< >$@

# Extract the gene name from the FASTA header
%.gene: %.fa
	sed -En 's/^>.*gene:([^ ]*).*/\1/p' $< >$@

# Extract the ID from the FASTA header
%.id: %.fa
	sed -En 's/^>([^ ]*).*/\1/p' $< >$@

# Compute the UniqTag for each sequence in the FASTA file
%.uniqtag: %.fa
	uniqtag $< >$@

# Join the gene name, ID and UniqTag into a TSV file
%.tsv: %.gene %.id %.uniqtag
	(printf "gene\tid\tuniqtag\n" && paste $^) >$@

# Join the TSV of identifiers of two builds on the gene name
Homo_sapiens.GRCh37.70.75.%.tsv: Homo_sapiens.GRCh37.70.%.tsv Homo_sapiens.GRCh37.75.%.tsv
	join $^ |tr ' ' '\t' >$@

# Sort the file
%.sort: %
	sort $< >$@

# Compare an older Ensembl build to build 75
# Note: BSD comm has a bug possibly related to long lines and so GNU comm is
# used instead.
Homo_sapiens.Ensembl.40.75.%.comm: Homo_sapiens.NCBI36.40.%.sort Homo_sapiens.GRCh37.75.%.sort
	gcomm $^ >$@

Homo_sapiens.Ensembl.45.75.%.comm: Homo_sapiens.NCBI36.45.%.sort Homo_sapiens.GRCh37.75.%.sort
	gcomm $^ >$@

Homo_sapiens.Ensembl.50.75.%.comm: Homo_sapiens.NCBI36.50.%.sort Homo_sapiens.GRCh37.75.%.sort
	gcomm $^ >$@

Homo_sapiens.GRCh37.55.75.%.comm: Homo_sapiens.GRCh37.55.%.sort Homo_sapiens.GRCh37.75.%.sort
	gcomm $^ >$@

Homo_sapiens.GRCh37.60.75.%.comm: Homo_sapiens.GRCh37.60.%.sort Homo_sapiens.GRCh37.75.%.sort
	gcomm $^ >$@

Homo_sapiens.GRCh37.65.75.%.comm: Homo_sapiens.GRCh37.65.%.sort Homo_sapiens.GRCh37.75.%.sort
	gcomm $^ >$@

Homo_sapiens.GRCh37.70.75.%.comm: Homo_sapiens.GRCh37.70.%.sort Homo_sapiens.GRCh37.75.%.sort
	gcomm $^ >$@

Homo_sapiens.GRCh37.74.75.%.comm: Homo_sapiens.GRCh37.74.%.sort Homo_sapiens.GRCh37.75.%.sort
	gcomm $^ >$@

# Count the overlap of two sets
%.venn: %.comm
	printf "%u\t%u\t%u\n" `grep -c $$'^[^\t]' $<` \
		`grep -c $$'^\t\t' $<` \
		`grep -c $$'^\t[^\t]' $<` >$@

# Create the experimental design table
%-design.tsv:
	printf "%s\t%s\t%s\n" >$@ \
		Table A B \
		$* 40 75 \
		$* 45 75 \
		$* 50 75 \
		$* 55 75 \
		$* 60 75 \
		$* 65 75 \
		$* 70 75 \
		$* 74 75

# Compute the experimental data table
%-data.tsv: \
		Homo_sapiens.Ensembl.40.75.pep.%.venn \
		Homo_sapiens.Ensembl.45.75.pep.%.venn \
		Homo_sapiens.Ensembl.50.75.pep.%.venn \
		Homo_sapiens.GRCh37.55.75.pep.%.venn \
		Homo_sapiens.GRCh37.60.75.pep.%.venn \
		Homo_sapiens.GRCh37.65.75.pep.%.venn \
		Homo_sapiens.GRCh37.70.75.pep.%.venn \
		Homo_sapiens.GRCh37.74.75.pep.%.venn
	(printf 'Only.A\tBoth\tOnly.B\n' && cat $^) >$@

# Join the experimental design and data tables
%.tsv: %-design.tsv %-data.tsv
	paste $^ >$@

# Compute the data table
uniqtag.tsv: \
		all.uniqgenemin.gene.tsv \
		all.uniqgenemin.id.tsv \
		all.uniqgenemin.seq.tsv \
		all.uniqgenemin.uniqtag.tsv
	(head -n1 $< && tail -qn+2 $^) >$@

# Generating uniqtag.md requires uniqtag.tsv
uniqtag.md: uniqtag.tsv

# Generate the Markdown from the RMarkdown
%.md: %.Rmd
	Rscript -e 'knitr::knit("$<", "$@")'
	mogrify -units PixelsPerInch -density 300 figure/*.png

# Generate the HTML from the Markdown
%.html: %.md
	Rscript -e 'markdown::markdownToHTML("$<", "$@")'
