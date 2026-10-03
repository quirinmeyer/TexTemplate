# Configure your paper
TEMPLATE_PATH				:= templates/eg

# Configure programs to use
# Firefox: on WSL the Windows Firefox, which needs Windows paths (file:///C:/...), otherwise
# the Linux firefox. To use another viewer, e.g., evince, set PDF_VIEWER := evince.
FIREFOX_WINDOWS				:= /mnt/c/Program Files/Mozilla Firefox/firefox.exe
PDF_VIEWER 					:= $(shell [ -x "$(FIREFOX_WINDOWS)" ] && echo '"$(FIREFOX_WINDOWS)"' || echo firefox)

# Configure main input files
MAIN_FILE_TEX				:= main.tex
BIBLIOGRAPHY				:= common/bibliography.bib

# Configure output files
OUTPUT_DIR					:= build
OUTPUT_FILE					:= Paper1024

PACKAGE_DIR					:= $(OUTPUT_DIR)/package

# Content of the supplemental material; the arXiv version appends it to the paper as appendix.
SUPPL_BODY_TEX				:= secs/S0supplemental.tex

### Do not edit below this line
TEMPLATE_LINK				:= template
OUTPUT_FILE_PDF				:= $(OUTPUT_DIR)/$(OUTPUT_FILE).pdf

# Supplemental material: a second pdf that reads the paper's .aux for cross-references.
# It is built only if supplemental.tex exists and the template provides supplemental.tex.
SUPPL_FILE_TEX				:= $(if $(wildcard $(TEMPLATE_PATH)/supplemental.tex),$(wildcard supplemental.tex))
SUPPL_OUTPUT_FILE			:= $(OUTPUT_FILE)_Supplemental
SUPPL_FILE_PDF				:= $(if $(SUPPL_FILE_TEX),$(OUTPUT_DIR)/$(SUPPL_OUTPUT_FILE).pdf)
# Tells supplemental.tex where the paper's .aux is, so it follows OUTPUT_FILE.
SUPPL_TEX_INPUT				:= "\def\PaperAux{$(OUTPUT_DIR)/$(OUTPUT_FILE)}\input{$(SUPPL_FILE_TEX)}"

# GitHub release. The tag is the only label the release carries (no separate
# title), so override it for anything more meaningful than a dated snapshot:
#   make release RELEASE_TAG=camera-ready
RELEASE_TAG					?= $(shell date +%Y-%m-%d-%H%M)
RELEASE_FILES				:= $(OUTPUT_FILE_PDF) $(SUPPL_FILE_PDF)

BIB_PREVIEW_NAME			:= BibPreview
BIB_PREVIEW_NAME_PDF		:= $(OUTPUT_DIR)/$(BIB_PREVIEW_NAME).pdf
BIB_PREVIEW_TEX				:= template/BibPreview.tex

### Latex tools
LATEX_COMPILER				:= pdflatex -shell-escape -halt-on-error -file-line-error -output-directory $(OUTPUT_DIR)
BIBTEX_COMPILER				:= bibtex

### Folders
TEMPLATE_FILES 				:= $(wildcard $(TEMPLATE_PATH)/**)
COMMON_FILES 				:= $(wildcard common/*.*)
CONTENT_TEX					:= $(wildcard secs/*.tex)
LISTS_TEX					:= $(wildcard lists/*.tex)
CODES_TEX					:= $(wildcard codes/*.tex)
TABLES_TEX					:= $(wildcard tabs/*.tex)
FIGURES_SVG 				:= $(wildcard figs/*.svg)
FIGURES_TEX					:= $(wildcard figs/*.tex)
# Data of the pgfplots figures, e.g., figs/data/subdivision.csv.
FIGURES_DATA				:= $(wildcard figs/data/*)
IMAGES 						:= $(wildcard imgs/*.*)

BUILD_DEP					:= Makefile $(TEMPLATE_FILES) $(COMMON_FILES) $(CONTENT_TEX) $(TABLES_TEX) $(FIGURES_SVG) $(FIGURES_TEX) $(FIGURES_DATA) $(IMAGES) $(LISTS_TEX) $(CODES_TEX)

### Build Rules. Do not edit below this line unless you know what to do.

### Timing tools
START_TIME					:= @date +%s%N > $@.time_txt
END_TIME					:= @echo "Build time in seconds: "; echo "scale=3;$$(($$(($$(date +%s%N)-$$(cat $@.time_txt))))).0 * 0.000000001"| bc; rm $@.time_txt

.PHONY: all clean rebuild bibpreview view help package arxiv arxiv-test release release-check print-release-files

# Make the main pdf and, if there is one, the supplemental pdf.
all: $(OUTPUT_FILE_PDF) $(SUPPL_FILE_PDF)

help:
	@echo "Run \"make\" with one of the options:"
	@echo "Option           Description"
	@echo "----------------------------------------------------------------------------------"
	@echo "all              Creates $(OUTPUT_FILE_PDF) $(SUPPL_FILE_PDF)"
	@echo "clean            Removes all build-artifacts including the $(OUTPUT_DIR) directory."
	@echo "view             Shows the pdfs with $(PDF_VIEWER)."
	@echo "bibpreview       Creates $(BIB_PREVIEW_NAME_PDF) to preview all entries of the"
	@echo "                 bibliography."
	@echo "package          Builds the pdfs and zips their sources for copy-editors into"
	@echo "                 $(OUTPUT_DIR)/package.zip; it builds without Inkscape."
	@echo "arxiv            Creates $(OUTPUT_DIR)/arxiv.zip for arXiv: paper with authors and the"
	@echo "                 supplemental as appendix; preview in $(OUTPUT_DIR)/$(OUTPUT_FILE)_arXiv.pdf."
	@echo "arxiv-test       Builds arxiv.zip as arXiv does (plain pdflatex, no BibTeX, no"
	@echo "                 Inkscape) and fails on errors or undefined references."
	@echo "release          Builds the pdfs and publishes them as a GitHub release."
	@echo "                 Override the tag with RELEASE_TAG=..., allow a dirty tree"
	@echo "                 with ALLOW_DIRTY=1."
	@echo "----------------------------------------------------------------------------------"
	@echo ""

# Clean up all build artifacs
clean:
	@rm -rf $(OUTPUT_DIR)
	@rm -f $(TEMPLATE_LINK)
	@rm -rf $(PACKAGE_DIR)

# Build the document pdf.
$(OUTPUT_FILE_PDF): $(TEMPLATE_LINK) $(BUILD_DEP)
	$(START_TIME)
	@$(LATEX_COMPILER) -jobname=$(OUTPUT_FILE) $(MAIN_FILE_TEX)
	-@$(BIBTEX_COMPILER) $(OUTPUT_DIR)/$(OUTPUT_FILE)
	-@makeglossaries -d $(OUTPUT_DIR)  $(OUTPUT_FILE)
	-@cd build && makeindex $(OUTPUT_FILE).nlo -s nomencl.ist -o $(OUTPUT_FILE).nls
	@$(LATEX_COMPILER) -jobname=$(OUTPUT_FILE) $(MAIN_FILE_TEX)
	@$(LATEX_COMPILER) -jobname=$(OUTPUT_FILE) $(MAIN_FILE_TEX)
	$(END_TIME)

ifneq ($(SUPPL_FILE_TEX),)
# Build the supplemental pdf. Depends on the paper for its .aux (cross-references).
$(SUPPL_FILE_PDF): $(TEMPLATE_LINK) $(BUILD_DEP) $(SUPPL_FILE_TEX) $(OUTPUT_FILE_PDF)
	$(START_TIME)
	@$(LATEX_COMPILER) -jobname=$(SUPPL_OUTPUT_FILE) $(SUPPL_TEX_INPUT)
	-@$(BIBTEX_COMPILER) $(OUTPUT_DIR)/$(SUPPL_OUTPUT_FILE)
	-@makeglossaries -d $(OUTPUT_DIR)  $(SUPPL_OUTPUT_FILE)
	@$(LATEX_COMPILER) -jobname=$(SUPPL_OUTPUT_FILE) $(SUPPL_TEX_INPUT)
	@$(LATEX_COMPILER) -jobname=$(SUPPL_OUTPUT_FILE) $(SUPPL_TEX_INPUT)
	$(END_TIME)
endif

# Rebuild the document.
rebuild: clean all

# View the pdfs. A Windows program needs Windows paths, e.g., file:///C:/... for Firefox.
PDF_URL						= $(if $(findstring .exe,$(PDF_VIEWER)),file:///$$(wslpath -w $(1) | tr '\\' '/'),$(1))
view: all
	@$(PDF_VIEWER) $(foreach f,$(realpath $(OUTPUT_FILE_PDF) $(SUPPL_FILE_PDF)),"$(call PDF_URL,$(f))") &

bibpreview: $(BIB_PREVIEW_NAME_PDF)

# Create a package to send to copy-editors: the sources of the paper and the
# supplemental, with only the SVG figures they use. The SVGs are shipped together
# with their Inkscape conversions (build/svg-inkscape), so the package builds without
# Inkscape. cp -p keeps the conversions newer than their SVGs, otherwise the svg
# package would convert them again. TikZ and pgfplots figures (figs/*.tex) and their
# data (figs/data) are shipped as they are.
PACKAGE_ZIP					:= $(OUTPUT_DIR)/package.zip
USED_SVGS					:= $(shell grep -h -v -E '^[[:space:]]*%' $(MAIN_FILE_TEX) $(SUPPL_FILE_TEX) $(wildcard $(TEMPLATE_PATH)/main.tex $(TEMPLATE_PATH)/supplemental.tex) $(wildcard secs/*.tex figs/*.tex) \
	| grep -o -E 'includesvg(\[[^]]*\])?\{[^}]*\}' | sed -E 's/.*\{([^}]*)\}/\1/' | sort -u)
PACKAGE_SOURCE_DIRS			:= $(wildcard common secs tabs codes lists imgs)
PACKAGE_FIGS				:= $(wildcard figs/*.tex figs/data)
# Class files that the template downloads (e.g., download/egPublStyle-cgf for templates/eg):
# the folders below download/ that its main.tex uses. Package and arXiv zip contain them,
# since copy-editors and arXiv cannot run the template's download.
TEMPLATE_DOWNLOADS			:= $(sort $(shell grep -h -o -E 'download/[^/}]+' $(TEMPLATE_PATH)/main.tex 2>/dev/null))

package: all
	@rm -rf $(PACKAGE_DIR) $(PACKAGE_ZIP)
	@mkdir -p $(PACKAGE_DIR)/template $(PACKAGE_DIR)/figs $(PACKAGE_DIR)/$(OUTPUT_DIR)/svg-inkscape
	@cp -r $(TEMPLATE_PATH)/* $(PACKAGE_DIR)/template
	@rm -f $(PACKAGE_DIR)/template/TabPreview.tex $(PACKAGE_DIR)/template/FigPreview.tex $(PACKAGE_DIR)/template/BibPreview.tex $(PACKAGE_DIR)/template/*.svg $(PACKAGE_DIR)/template/Makefile
	@cp -r $(PACKAGE_SOURCE_DIRS) $(PACKAGE_DIR)/
	@[ -z "$(PACKAGE_FIGS)" ] || cp -r $(PACKAGE_FIGS) $(PACKAGE_DIR)/figs/
	@for d in $(TEMPLATE_DOWNLOADS); do mkdir -p $(PACKAGE_DIR)/download && cp -r $$d $(PACKAGE_DIR)/download/ || exit 1; done
	@for f in $(USED_SVGS); do \
		cp -p $$f.svg $(PACKAGE_DIR)/figs/ && \
		cp -p $(OUTPUT_DIR)/svg-inkscape/$$(basename $$f)_svg-* $(PACKAGE_DIR)/$(OUTPUT_DIR)/svg-inkscape/ || exit 1; \
	done
	@sed -e 's/@OUTPUT_FILE@/$(OUTPUT_FILE)/' tools/Makefile.package > $(PACKAGE_DIR)/Makefile
	@cp $(MAIN_FILE_TEX) $(SUPPL_FILE_TEX) LICENSE $(PACKAGE_DIR)
	@cd $(PACKAGE_DIR) && zip -q -r $(abspath $(PACKAGE_ZIP)) .
	@echo "Created $(PACKAGE_ZIP) with $(words $(USED_SVGS)) SVG figures."

# Create the arXiv submission: one document with the paper, authors shown, and the
# supplemental as appendix. arXiv runs neither BibTeX nor Inkscape, so we ship the .bbl and
# the Inkscape conversions. The SVGs are replaced by tiny placeholders: the svg package
# needs the file to exist, but with \ArxivVersion it never converts it (50 MB limit).
# \pdfoutput=1 in the first lines makes arXiv use pdfLaTeX.
# Downloaded class files are included without their sample documents, so arXiv finds only
# one main .tex file. templates/<name>/arxiv.tex may remove the conference markings.
ARXIV_DIR					:= $(OUTPUT_DIR)/arxiv
ARXIV_ZIP					:= $(OUTPUT_DIR)/arxiv.zip
ARXIV_PDF					:= $(OUTPUT_DIR)/$(OUTPUT_FILE)_arXiv.pdf
ARXIV_LATEX					:= pdflatex -interaction=nonstopmode -halt-on-error -file-line-error
ARXIV_APPENDIX				:= $(if $(SUPPL_FILE_TEX),$(wildcard $(SUPPL_BODY_TEX)))
ARXIV_APPENDIX_SED			:= $(if $(ARXIV_APPENDIX),\\appendix\n\\input{$(ARXIV_APPENDIX)}\n)

arxiv: all
	@rm -rf $(ARXIV_DIR) $(ARXIV_ZIP) $(ARXIV_PDF)
	@mkdir -p $(ARXIV_DIR)/template $(ARXIV_DIR)/figs $(ARXIV_DIR)/$(OUTPUT_DIR)/svg-inkscape
	@cp -r $(TEMPLATE_PATH)/. $(ARXIV_DIR)/template/
	@find $(ARXIV_DIR)/template \( -name '*.tex' ! -name arxiv.tex \) -o -name '*.svg' -o -name '*.eps' -o -name Makefile | xargs rm -f
	@cp -r $(PACKAGE_SOURCE_DIRS) $(ARXIV_DIR)/
	@[ -z "$(PACKAGE_FIGS)" ] || cp -r $(PACKAGE_FIGS) $(ARXIV_DIR)/figs/
	@for d in $(TEMPLATE_DOWNLOADS); do mkdir -p $(ARXIV_DIR)/download && cp -r $$d $(ARXIV_DIR)/download/ || exit 1; done
	@[ ! -d $(ARXIV_DIR)/download ] || find $(ARXIV_DIR)/download \( -name '*.tex' -o -name '*.eps' -o -name '*.zip' \) -delete
	@for f in $(USED_SVGS); do \
		printf '%s\n' '<svg xmlns="http://www.w3.org/2000/svg"/>' '<!-- Placeholder: the figure is in $(OUTPUT_DIR)/svg-inkscape -->' > $(ARXIV_DIR)/$$f.svg && \
		cp $(OUTPUT_DIR)/svg-inkscape/$$(basename $$f)_svg-* $(ARXIV_DIR)/$(OUTPUT_DIR)/svg-inkscape/ || exit 1; \
	done
	@{ printf '%s\n' '\pdfoutput=1' '\newcommand{\BlindSubmission}{0}' '\newcommand{\ArxivVersion}{}' '\newcommand{\SupplementalName}{appendix}'; \
	   sed -e 's|^\\end{document}|$(ARXIV_APPENDIX_SED)\\end{document}|' $(TEMPLATE_PATH)/main.tex; } > $(ARXIV_DIR)/main.tex
	@cd $(ARXIV_DIR) && { $(ARXIV_LATEX) main > /dev/null; bibtex main > /dev/null; $(ARXIV_LATEX) main > /dev/null; $(ARXIV_LATEX) main > /dev/null; } \
		|| { echo "arXiv build failed, see $(ARXIV_DIR)/main.log"; exit 1; }
	@cp $(ARXIV_DIR)/main.pdf $(ARXIV_PDF)
	@cd $(ARXIV_DIR) && find . -maxdepth 1 -type f ! -name main.tex ! -name main.bbl -delete
	@cd $(ARXIV_DIR) && zip -q -r $(abspath $(ARXIV_ZIP)) .
	@echo "Created $(ARXIV_ZIP) ($$(du -h $(ARXIV_ZIP) | cut -f1)) and the preview $(ARXIV_PDF)."

# Test the arXiv zip as arXiv processes it: unzip into an empty directory and run plain
# pdflatex three times, without BibTeX and -shell-escape. A fake inkscape logs every call.
# The system TeX Live (/usr/bin) is closer to arXiv's version than a newer one in PATH.
# Fails on LaTeX errors, undefined references or citations, Inkscape calls, conference
# markings in the PDF, and zips above arXiv's size limit.
ARXIV_TEST_DIR				:= $(OUTPUT_DIR)/arxiv-test
ARXIV_TEST_TEXBIN			?= /usr/bin
ARXIV_MAX_BYTES				:= 50000000

arxiv-test: arxiv
	@rm -rf $(ARXIV_TEST_DIR)
	@mkdir -p $(ARXIV_TEST_DIR)/src $(ARXIV_TEST_DIR)/fakebin
	@printf '#!/bin/sh\necho "$$*" >> "$(abspath $(ARXIV_TEST_DIR))/inkscape_calls.log"\nexit 1\n' > $(ARXIV_TEST_DIR)/fakebin/inkscape
	@chmod +x $(ARXIV_TEST_DIR)/fakebin/inkscape
	@cd $(ARXIV_TEST_DIR)/src && unzip -q $(abspath $(ARXIV_ZIP))
	@cd $(ARXIV_TEST_DIR)/src && export PATH="$(abspath $(ARXIV_TEST_DIR))/fakebin:$(ARXIV_TEST_TEXBIN):/usr/bin:/bin" && \
		echo "arxiv-test: $$(pdflatex --version | head -1)" && \
		for i in 1 2 3; do \
			pdflatex -interaction=nonstopmode -halt-on-error main > /dev/null \
			|| { echo "arxiv-test FAILED: LaTeX error in pass $$i, see $(ARXIV_TEST_DIR)/src/main.log"; grep -m 5 -E '^!' main.log; exit 1; }; \
		done
	@cd $(ARXIV_TEST_DIR)/src && fail=0; \
	if grep -q -E 'undefined' main.log; then \
		echo "arxiv-test FAILED: undefined references or citations:"; grep -E 'undefined' main.log | sort -u | head; fail=1; fi; \
	if [ -f ../inkscape_calls.log ]; then \
		echo "arxiv-test FAILED: Inkscape was called:"; head -3 ../inkscape_calls.log; fail=1; fi; \
	if pdftotext main.pdf - | grep -q -i -E 'submitted to|guest editors|volume [0-9]+ \('; then \
		echo "arxiv-test FAILED: conference markings in the PDF:"; pdftotext main.pdf - | grep -i -E 'submitted to|guest editors|volume [0-9]+ \(' | head -3; fail=1; fi; \
	size=$$(stat -c %s $(abspath $(ARXIV_ZIP))); \
	if [ $$size -gt $(ARXIV_MAX_BYTES) ]; then \
		echo "arxiv-test FAILED: $(ARXIV_ZIP) has $$size bytes, arXiv allows $(ARXIV_MAX_BYTES)."; fail=1; fi; \
	if [ $$fail -ne 0 ]; then exit 1; fi; \
	echo "arxiv-test passed: $$(pdfinfo main.pdf | awk '/^Pages/{print $$2}') pages, $$(du -h $(abspath $(ARXIV_ZIP)) | cut -f1) zip, see $(ARXIV_TEST_DIR)/src/main.pdf."

# Preconditions for a release. A separate target so they run before the pdfs are
# built: a missing tool or a dirty tree then fails in a second instead of after a
# full three-pass latex build.
release-check:
	@command -v gh >/dev/null 2>&1 || { echo "Error: gh CLI not found. See https://cli.github.com"; exit 1; }
	@gh auth status >/dev/null 2>&1 || { echo "Error: gh is not authenticated. Run: gh auth login"; exit 1; }
	@if [ -n "$$(git status --porcelain)" ] && [ -z "$(ALLOW_DIRTY)" ]; then \
		echo "Error: working tree is dirty, the pdfs would not match the tagged commit."; \
		echo "       Commit and push first, or re-run with ALLOW_DIRTY=1."; \
		exit 1; \
	fi
	@if [ -z "$$(git branch -r --contains HEAD 2>/dev/null)" ]; then \
		echo "Error: HEAD is not on any remote branch. Run: git push"; \
		exit 1; \
	fi

# Publish the freshly built pdfs as a GitHub release on the current commit.
# Requires the gh CLI (https://cli.github.com) to be installed and authenticated.
# The pdfs are built from the recipe, not as a prerequisite, so the checks above
# are guaranteed to run first even under make -j.
release: release-check
	@$(MAKE) --no-print-directory $(RELEASE_FILES)
	@echo "Creating release $(RELEASE_TAG) from $$(git rev-parse --short HEAD) ..."
	@gh release create "$(RELEASE_TAG)" $(RELEASE_FILES) \
		--target "$$(git rev-parse HEAD)" \
		--notes "Built from commit $$(git rev-parse --short HEAD)."

# Print the pdfs a release publishes, one per line. The GitHub workflow reads
# them from here, so renaming OUTPUT_FILE needs no change there.
print-release-files:
	@printf '%s\n' $(RELEASE_FILES)

# Create the preview for bibliography. Triggered from the BibPreview.sh script.
$(BIB_PREVIEW_NAME_PDF): $(BIBLIOGRAPHY) $(TEMPLATE_LINK)
	$(START_TIME)
	@$(LATEX_COMPILER) $(BIB_PREVIEW_TEX);
	-@$(BIBTEX_COMPILER) $(OUTPUT_DIR)/$(BIB_PREVIEW_NAME)
	@$(LATEX_COMPILER) $(BIB_PREVIEW_TEX);
	@$(LATEX_COMPILER) $(BIB_PREVIEW_TEX);
	$(END_TIME)

# Create preview for tables. Triggered from the TabPreview.sh script.
$(OUTPUT_DIR)/%.pdf: tabs/%.tex $(TEMPLATE_LINK)
	$(START_TIME)
	@touch $@
	@$(LATEX_COMPILER) $(OUTPUT_DIR)/preview_tab.tex;  mv $(OUTPUT_DIR)/preview_tab.pdf $@;
	-@$(BIBTEX_COMPILER) $(OUTPUT_DIR)/preview_tab
	@$(LATEX_COMPILER) $(OUTPUT_DIR)/preview_tab.tex
	@$(LATEX_COMPILER) $(OUTPUT_DIR)/preview_tab.tex
	$(END_TIME)

# Create preview for figures. Triggered from the FigPreview.sh script.
$(OUTPUT_DIR)/%.pdf: figs/%.svg	$(TEMPLATE_LINK)
	$(START_TIME)
	@touch $@
	@$(LATEX_COMPILER) $(OUTPUT_DIR)/preview_fig.tex;  mv $(OUTPUT_DIR)/preview_fig.pdf $@;
	-@$(BIBTEX_COMPILER) $(OUTPUT_DIR)/preview_fig
	@$(LATEX_COMPILER) $(OUTPUT_DIR)/preview_fig.tex
	@$(LATEX_COMPILER) $(OUTPUT_DIR)/preview_fig.tex
	$(END_TIME)

# Create template link. Execute Makefile
$(TEMPLATE_LINK): Makefile
	@mkdir -p $(OUTPUT_DIR)
	@ln -sfn $(TEMPLATE_PATH) $(TEMPLATE_LINK)
	@if [ -f "$(TEMPLATE_PATH)/Makefile" ]; then \
		$(MAKE) -C "$(TEMPLATE_PATH)"; \
	fi
