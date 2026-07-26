
.PHONY: all clean cleanall pkg pages help

all: pkg pages

clean:
	@rm -rf tmp

cleanall: clean
	@rm -rf public *.deb

pkg:
	./make-package-debian

pages: pkg
	./make-webpages

help:
	@echo "Possibles targets:"
	@echo " * all     : make manual"
	@echo " * install : complete install"
	@echo " * update  : update install (do not update cron file)"
	@echo " * sync    : sync with official repository"
	@echo " * upload  : upload on public dav forge space"
	@echo " * stat    : svn stat with gnuplot graph"
	@echo " * pkg     : build Debian package"
	@echo "ignore - svn rules to ignore some files"
