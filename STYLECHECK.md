# Checking a Paper Against the Style Guide with an AI

The prompt below lets an AI check your paper against [STYLEGUIDE.md](STYLEGUIDE.md).
It does not replace the checklist of the style guide, your own reading, or your supervisor.

- Use only AI tools that your lab and the venue allow for unpublished work.
- The AI makes mistakes, and it finds problems that are none.
  Check every finding against the style guide before you change anything.
- With a tool that reads your project, e.g., Claude Code, start it in the root folder of the project and paste the prompt.
- With a chat tool, attach `STYLEGUIDE.md`, the files that the prompt lists, and, if possible, the PDF.
- If the paper is too long, also paste the second prompt.

## Prompt

```text
Check my paper against the style guide of our lab, STYLEGUIDE.md.
This is a check of the style, not a review of the content.
Do not edit any file; only report.

Material:
- STYLEGUIDE.md: the rules. Check only these rules.
  If I provide the author guidelines of the venue, they override the style guide.
- The LaTeX sources:
  - secs/*.tex: the text. secs/structure.tex and secs/appendix.tex give the order.
    Skip secs/D1TestBed.tex, a test of the template.
  - template/main.tex: title, authors, and abstract.
  - tabs/*.tex: tables. tabs/ListOfSymbols.tex lists the notation and the symbols of the paper.
  - figs/*.tex: TikZ and pgfplots figures. codes/*.tex: code listings.
  - common/commands.tex: notation macros. lists/acronyms.tex: acronyms.
    common/bibliography.bib: references.
- If available: the PDF and the .log file in build/.

Procedure:
1. Read STYLEGUIDE.md completely.
2. Read the sources in the order of the paper.
3. Go through the style guide section by section, and check every rule against the whole paper.
   The notation of the paper is the one in tabs/ListOfSymbols.tex, even if it differs from our default.
   Rules that are easy to miss:
   - "this" without a noun; citations used as nouns; "above", "below", or "the following figure" instead of \cref;
   - sentences with more than one idea or more than about 25 words; passive voice where "we" works;
     filler words; contractions; "novel", "very", "clearly", "obviously", "simply", "just";
   - claims without a citation, a proof, or a measurement;
   - acronyms typed by hand instead of \ac; acronyms used fewer than three times;
   - symbols not defined before their first use, missing in tabs/ListOfSymbols.tex,
     or with two meanings, also across captions, figures, code, and the supplemental material;
   - raw fonts in the text (\mathbf, \vec, \bf) instead of the notation macros; * for multiplication;
     ^T instead of ^\top; names of several letters in italics;
   - displayed equations without punctuation at their end; a blank line before the "where" that continues a display;
   - captions without \captiontitle, in passive voice, or not self-contained;
     figures and tables that the text never references, or references out of order;
   - tables with \resizebox, vertical lines, units in the cells, or bold values that the caption does not explain;
   - numbers without siunitx; different numbers of decimals within a comparison; "2x faster";
   - more than one sentence per line in the source; labels without the prefixes sec:, fig:, tab:, eq:, lst:;
     \vspace, \\, \newpage, or font sizes in the text; leftover \todo;
   - contributions that do not start with "We" and a verb; sections without an overview sentence;
   - citation keys that do not follow the scheme of the guide; references without DOI or with unprotected capitals;
   - in the PDF, if available: a single word on the last line of a paragraph; text in figures smaller than the caption;
     colorbars without quantity, unit, or range;
   - in the log, if available: warnings, undefined references, overfull boxes.
4. Story check: list the first sentence of every paragraph, in order.
   Then say in at most three sentences whether they tell the story of the paper, and where the story breaks.

Report:
- Only clear violations of a rule in STYLEGUIDE.md.
  Do not report preferences, and do not report text that follows the guide.
- For each finding: file and line, the rule with its section in the guide, the exact quote,
  and the smallest change that fixes it.
  Do not rewrite paragraphs, and do not add content or claims.
- Report a recurring problem once, with all its locations.
- Mark findings that you are unsure about as "unsure", and say why.
- Group the findings by the sections of STYLEGUIDE.md. Write "No findings" for a section without violations.
- End with the five most important findings and the items of the checklist
  "Before You Hand In a Draft" that fail.
```

## Second Prompt: The Paper Is Too Long

Replace `<N>` by the number of lines that you must save.

```text
The paper is <N> lines too long.
Propose cuts that follow Section 12 of STYLEGUIDE.md, cheapest first: layout, bibliography, words, content.
For each cut, give the file and line, the change, and the lines it saves.
Never propose smaller fonts, margins, or spacing, or \resizebox.
Stop when the cuts save <N> lines.
```
