HTML := $(patsubst %.md,%.html,$(wildcard *.md))
PDF := $(patsubst %.md,%.pdf,$(wildcard *.md))
DOCX := $(patsubst %.md,%.docx,$(wildcard *.md))
PNGS := $(patsubst %.dot,%.png,$(wildcard *.dot))

html: png $(HTML)

pdf: png $(PDF)

docx: png $(DOCX)

%.html: %.md
	pandoc $< -o $@

%.pdf: %.md
	pandoc $< -o $@

%.docx: %.md
	pandoc $< -o $@

png: $(PNGS)

%.png: %.dot
	dot -o$@ -Tpng $<

clean:
	-rm *.pdf
	-rm *.html
	-rm *.docx
	-rm *.png

#html: er
#	pandoc -s systemdokumentation.md -o systemdokumentation.html
#
#pdf: er
#	pandoc -s systemdokumentation.md -o systemdokumentation.pdf
#
#docx: er
#	pandoc -s systemdokumentation.md -o systemdokumentation.docx
#
#er:
#	dot -oer.png -Tpng er.dot
