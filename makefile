# LaTeX Makefile v1.0 -- LaTeX + PDF figures

##==============================================================================
# CONFIGURATION
##==============================================================================
.PHONY = clean help images set-version
MAKEFLAGS := --jobs=4
SHELL  = /bin/bash

##==============================================================================
# DIRECTORIES
##==============================================================================
IMG     = img

##==============================================================================
# FILES
##==============================================================================
DOC_SRC         = main.tex
TARGET          = sa-pap.pdf
SRC             = $(shell find . -type f -name "*.tex")
FIGURES_TEX     = $(wildcard $(IMG)/*tex)
FIGURES_PDF     = $(patsubst %.tex, %.pdf, $(FIGURES_TEX))

##==============================================================================
# RECIPES
##==============================================================================

##------------------------------------------------------------------------------
#
all: $(SRC) ## Build full thesis (LaTeX + figures)
	@printf "Generating $(TARGET)...\n"
	@latexmk -pdf main.tex

##------------------------------------------------------------------------------
# Resources:
# - https://stackoverflow.com/questions/15559359/insert-line-after-match-using-sed
#
set-version: ## Stamp the document with date and git commit hash
	@$(eval VERSION=$(shell git describe --tags))
	@grep "$(VERSION)" $(DOC_SRC) > /dev/null || \
	sed -i 's/\\today/\\today : $(VERSION)/' $(DOC_SRC)

##------------------------------------------------------------------------------
#
clean:	## Clean LaTeX and output figure files
	@rm -f $(FIGURES_PDF)
	@rm -f $(patsubst %.pdf, %.aux, $(FIGURES_PDF))
	@rm -f $(patsubst %.pdf, %.log, $(FIGURES_PDF))
	@rm -f $(TARGET)
	@latexmk -silent -C $(DOC_SRC)


##------------------------------------------------------------------------------
#
watch:	## Recompile on any update of LaTeX or SVG sources
	@while [ 1 ]; do                                                                          \
		printf "=========================  WATCHING =========================\r";         \
		find . -mmin 0.10 -type f \( -name \*.org -o -name \*.tex \) -exec make -j1 emacs \;; \
		sleep 5;                                                                          \
	done

##------------------------------------------------------------------------------
# https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help:  ## Auto-generated help menu
	@grep -P '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	sort |                                                \
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

##==============================================================================
# HELPER RECIPES
##==============================================================================

##------------------------------------------------------------------------------
#
%.pdf: %.tex  ## Figures for the manuscript
	@printf "Generating %s...\033[K\r" "$@"
	@pdflatex -shell-escape -interaction=nonstopmode -output-directory $(IMG) "$<" | \
	grep "^!" -A20 --color=always || true

##------------------------------------------------------------------------------
#
%-eps-converted-to.pdf: %.eps ## Convert eps file to PDF
	@printf "Generating %s...\033[K\r" "$@"
	@epspdf -v>/dev/null 2>&1 && epspdf $< || epstopdf $<
	mv $(basename $<).pdf $(basename $<)-eps-converted-to.pdf
