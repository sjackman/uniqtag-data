all: uniqtag.tsv uniqtag.html

.PHONY: all
.DELETE_ON_ERROR:
.SECONDARY:

edirect_query='GRCh38[Title] "Primary Assembly"[Title]'

cds_aa.orig.fa cds_na.orig.fa: %.fa:
	esearch -db nuccore -query $(edirect_query) \
		|efetch -format fasta_$* >$@

%.cds_aa.fa:
	esearch -db nuccore -query '$*[Title] "Primary Assembly"[Title]' \
		|efetch -format fasta_cds_aa >$@

Homo_sapiens.NCBI36.54.pep.%.fa.gz:
	wget ftp://ftp.ensembl.org/pub/release-54/fasta/homo_sapiens/pep/Homo_sapiens.NCBI36.54.pep.$*.fa.gz

Homo_sapiens.GRCh37.%.pep.all.fa.gz:
	wget ftp://ftp.ensembl.org/pub/release-$*/fasta/homo_sapiens/pep/Homo_sapiens.GRCh37.$*.pep.all.fa.gz

Homo_sapiens.GRCh37.%.pep.abinitio.fa.gz:
	wget ftp://ftp.ensembl.org/pub/release-$*/fasta/homo_sapiens/pep/Homo_sapiens.GRCh37.$*.pep.abinitio.fa.gz

%.fa: %.fa.gz
	seqtk seq $< >$@

%.seq: %.fa
	grep -v '^>' $< >$@

%.all.fa.tsv: %.all.fa
	awk -vORS='' '{print $$1 "\t" $$4; getline; print "\t" $$0 "\n" }' $< |sort -k2,2 -k1 >$@

%.uniqgenemin.fa: %.fa.tsv
	awk 'x[$$2]++ == 0 { print $$1 " " $$2 "\n" $$3 }' $< >$@

%.allgene.fa: %.fa.tsv
	awk 'x[$$2]++ == 0 { print $$1 " " $$2 "\n" $$3; next } \
		{ print "~" $$3 }' $< |seqtk seq - >$@

%.uniqgene.fa: %.fa
	awk 'x[$$4]++ == 0 { print; getline; print; next } { getline }' $< >$@

%.uniqseq.fa: %.fa
	bioawk -cfastx 'x[$$seq]++ == 0 { print ">" $$name " " $$comment "\n" $$seq }' $< >$@

%.uniqtagdedup: %.fa
	uniqtag $< >$@

%.uniqtag: %.uniqtagdedup
	sed 's/-.*//' $< >$@

%.sort: %
	sort $< >$@

%.gene: %.fa
	sed -En 's/^>.*gene:([^ ]*).*/\1/p' $< >$@

%.id: %.fa
	sed -En 's/^>([^ ]*).*/\1/p' $< >$@

%.id-uniqtag: %.id %.uniqtag
	paste $^ >$@

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

%.venn: %.comm
	printf "%u\t%u\t%u\n" `grep -c $$'^[^\t]' $<` \
		`grep -c $$'^\t\t' $<` \
		`grep -c $$'^\t[^\t]' $<` >$@

%-design.tsv:
	printf "%s\t%s\t%s\n" >$@ \
		Table A B \
		$* 55 75 \
		$* 60 75 \
		$* 65 75 \
		$* 70 75 \
		$* 74 75

%-data.tsv: \
		Homo_sapiens.GRCh37.55.75.pep.%.venn \
		Homo_sapiens.GRCh37.60.75.pep.%.venn \
		Homo_sapiens.GRCh37.65.75.pep.%.venn \
		Homo_sapiens.GRCh37.70.75.pep.%.venn \
		Homo_sapiens.GRCh37.74.75.pep.%.venn
	(printf 'Only.A\tBoth\tOnly.B\n' && cat $^) >$@

%.tsv: %-design.tsv %-data.tsv
	paste $^ >$@

%.tsv.md: %.tsv
	abyss-tabtomd $< >$@

%.md: %.Rmd
	Rscript -e 'knitr::knit("$<", "$@")'
	mogrify -units PixelsPerInch -density 300 figure/*

%.html: %.md
	Rscript -e 'markdown::markdownToHTML("$<", "$@")'

uniqtag.tsv: \
		all.uniqgenemin.gene.tsv \
		all.uniqgenemin.id.tsv \
		all.uniqgenemin.seq.tsv \
		all.uniqgenemin.uniqtag.tsv
	(head -n1 $< && tail -qn+2 $^) >$@

uniqtag.md: uniqtag.tsv
