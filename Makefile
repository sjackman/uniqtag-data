all: Homo_sapiens.pep.abinitio.unique.uniqtag.venn

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

%.unique.seq: %.seq
	awk 'x[$$0]++ == 0' $< >$@

%.uniqtag: %.seq
	uniqtag $< >$@

%.uniqtag.sort: %.uniqtag
	sort $< >$@

%.id: %.fa
	sed -En 's/^>([^ ]*).*/\1/p' $< >$@

%.id-uniqtag: %.id %.uniqtag
	paste $^ >$@

Homo_sapiens.NCBI36.54.GRCh37.75.%.comm: Homo_sapiens.NCBI36.54.%.sort Homo_sapiens.GRCh37.75.%.sort
	comm $^ >$@

Homo_sapiens.GRCh37.74.75.%.comm: Homo_sapiens.GRCh37.74.%.sort Homo_sapiens.GRCh37.75.%.sort
	comm $^ >$@

Homo_sapiens.NCBI36.54.GRCh37.%.pep.abinitio.uniqtag.comm: Homo_sapiens.NCBI36.54.pep.abinitio.uniqtag.sort Homo_sapiens.GRCh37.%.pep.abinitio.uniqtag.sort
	comm $^ >$@

Homo_sapiens.GRCh37.%.75.pep.all.uniqtag.comm: Homo_sapiens.GRCh37.%.pep.all.uniqtag.sort Homo_sapiens.GRCh37.75.pep.all.uniqtag.sort
	comm $^ >$@

Homo_sapiens.GRCh37.%.75.pep.abinitio.uniqtag.comm: Homo_sapiens.GRCh37.%.pep.abinitio.uniqtag.sort Homo_sapiens.GRCh37.75.pep.abinitio.uniqtag.sort
	comm $^ >$@

Homo_sapiens.GRCh37.%.75.pep.abinitio.unique.uniqtag.comm: Homo_sapiens.GRCh37.%.pep.abinitio.unique.uniqtag.sort Homo_sapiens.GRCh37.75.pep.abinitio.unique.uniqtag.sort
	comm $^ >$@

%.venn: %.comm
	printf "%u\t%u\t%u\n" `grep -c $$'^[^\t]' $<` \
		`grep -c $$'^\t\t' $<` \
		`grep -c $$'^\t[^\t]' $<` >$@