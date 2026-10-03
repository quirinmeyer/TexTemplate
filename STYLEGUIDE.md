# Writing Style Guide

How we write papers and theses in our lab.
Follow these rules unless you have a good reason.
Discuss deviations with your supervisor.
The author guidelines of the venue always come first.

## 1. Language

### Sentences
- One idea per sentence. Aim for about 15 to 20 words.
- Split long sentences at "and", "which", "while", and semicolons.
- Active voice with "we": "We quantize $u$.", not "$u$ is quantized."
- Present tense: "We show ...", "Tab. 1 lists ...". Past tense only for history: "Shoemake introduced ...".
- Verbs, not nouns: "we compare", not "we perform a comparison".
- Start each paragraph with its message. The first sentences of all paragraphs tell the story.
- One topic per paragraph.

### Words
- One term per concept. Never vary terms for style.
- Introduce a technical term once with `\term{atlas}` where you define it. Afterwards, write it plain.
- Use `\emph` only for emphasis, and rarely.
- Cut filler words:

  | Instead of | Write |
  |---|---|
  | in order to | to |
  | due to the fact that | because |
  | is able to | can |
  | make use of, utilize | use |
  | a number of | several |
  | it should be noted that | (delete) |

- Avoid very, extremely, clearly, obviously, simply, just, quite. Give numbers instead.
- "Significantly" only for statistical significance.
- Do not call your work "novel". Show it.
- No "this" without a noun: "This measurement shows ...", not "This shows ...".
- "They" for a person of unknown gender.
- No contractions (don't, it's).
- American English: color, behavior, analyze. Set your spell checker to en-US.

### Punctuation and small words
- "e.g.," and "i.e.," always with a comma.
- `et~al.\ ` in LaTeX if no punctuation follows.
- Hyphenate compound modifiers before a noun: "floating-point number", "real-time rendering". Not after it: "runs in real time".
- Hyphen `-`, en dash `--` for ranges (10--20), em dash `---` for breaks.
- Quotes: ``` ``like this'' ```, never straight quotes.
- Non-breaking spaces: `text~\cite{X}`, `et~al.`, numbers and units (siunitx does this).
- Do not start a sentence with a symbol or a numeral.
- Lists: parallel grammar, same punctuation in every item.

### Numbers and units
- Use siunitx: `\num{32768}`, `\qty{4.5}{\milli\second}`, `\qtyrange{11}{13}{\percent}`, `\numproduct{2048 x 2048}`.
- Memory in binary prefixes: MiB, GiB (`\mebi\byte`). MB means 10^6 bytes.
- Only meaningful digits. Same number of decimals within a comparison.
- Say "a factor of 1.26" or "12 % lower". Avoid "2x faster".
- Words for one to nine in running text, numerals with units.

### Acronyms
- Define all acronyms in `lists/acronyms.tex`: `\acro{GPU}{graphics processing unit}`.
  The long form is lower case, unless it is a name.
- Irregular plurals need the long plural:
  `\newacronym[longplural={levels of detail}]{LOD}{LOD}{level of detail}`.
  Otherwise, `\acp` prints "level of details (LODs)".
- In running text, use `\ac{GPU}`.
  It prints "graphics processing unit (GPU)" at the first use, "GPU" afterwards.
  Plural `\acp`, at the start of a sentence `\Ac`, `\Acp`.
- In titles, headings, captions, and tables, use the short form `\acs{GPU}`.
  It does not count as first use.
  Floats and headings may appear before the first use in the text.
- The abstract stands alone and expands acronyms itself.
  `\glsresetall` at the start of the introduction lets the body expand them again (preset in `secs/B1intro.tex`).
- Introduce an acronym only for terms you use at least three times.
  Many acronyms make text hard to read.
- Never type an acronym by hand. Always use `\ac`.

## 2. Structure of a Paper

Our papers follow this structure:

1. **Title**: concise, title case, the method and what it does. No acronyms, except well-known ones.
2. **Abstract**: 4 to 6 sentences. Problem, gap, our idea, results with numbers. No citations, no symbols.
3. **Teaser figure**: the main result at a glance.
4. **Introduction**:
   context, problem, limitations of existing work (cited), our idea.
   Then "We make the following contributions:" with bullets.
   Each bullet starts with "We" and a verb, and is specific and checkable.
   Then the scope and limitations.
5. **Previous Work**: grouped by topic, not by paper. End each group with how our work differs. Cite fairly.
6. **Background** (optional): only what the method needs, including the notation.
7. **Method**: named after the method, not "Main Part" or "Our Method".
   Start with an overview figure and a paragraph of overview.
   Go from the overview to the details.
8. **Implementation** (optional): what others need to reproduce it.
9. **Results and Discussion**:
   first the setup: hardware, driver and API versions, data sets with sources and licenses, parameters, how we measure.
   Then quality, performance, and memory.
   Compare against the strongest baselines at equal budgets.
   Explain why, not only what. Report negative results.
10. **Limitations and Future Work**: be honest. Reviewers find them anyway.
11. **Conclusion**: short, no new information.
12. **Acknowledgments**: funding, people, assets with authors and licenses.
13. **Supplemental material**: long proofs, extra results, video.

Every section starts with one sentence of overview that references its subsections with `\cref`.
Every claim needs a citation, a proof, or a measurement.

## 3. Mathematics

### Choose your notation deliberately
- Our default notation (below, also in `tabs/ListOfSymbols.tex`) works for most graphics papers.
  It may not fit yours.
- Before you write, list all kinds of objects of your paper:
  scalars, vectors, points, unit vectors, matrices, sets, functions, quantized values, ...
  Then choose a notation, and discuss it with your supervisor.
- Follow the conventions of your field where they exist.
- Example: our unit-quaternion paper has no points.
  It writes vectors bold and marks quantized values with an underline.
  Our default writes vectors with arrows, points bold, and quaternions underlined.
- Write the notation into `tabs/ListOfSymbols.tex` from day one. Add every new symbol.

| Object | Default | Macro |
|---|---|---|
| scalar, constant, angle | $a$, $N$, $\alpha$ | |
| vector, its components | $\vec{x}$, $x_i$ | `\vect{x}`, `x_i` |
| normalized vector | $\hat{x}$ | `\nvec{x}` |
| point | $\mathbf{p}$ | `\pnt{p}` |
| matrix, element, column | $\mathbf{A}$, $a_{i,j}$, $\vec{a}_{:,j}$ | `\mat{A}` |
| quaternion | $\underline{q}$ | `\quat{q}` |
| set | $\mathcal{A}$ | `\mathcal{A}` |
| series of vectors | $\vec{x}^{[i]}$ | `\vect{x}^{\left[i\right]}` |

### Use macros, never raw fonts
- Write `\vect{x}`, `\mat{A}`, `\pnt{p}`, not `\vec`, `\mathbf`, `\bf`.
  Then a change of notation is one line in `common/commands.tex`.
- Also define a macro for every method name, e.g., `\newcommand{\ourmethod}{...}`.
  Renaming then costs one line.

### One symbol, one meaning
- Never use one symbol for two things.
  Not in another section, not in the supplemental material, not in figures, not in code.
- Fonts of the same letter only for related objects: $x_i$ is a component of $\vec{x}$.
  Unrelated objects need different letters: no count $T$ next to a matrix $\mathbf{T}$.
- Check every new symbol against your list of symbols.
- Avoid letters with a common meaning: $e$, $i$, $\pi$, and $\varepsilon$ for something else.
- Our unit-quaternion paper had to rename symbols late:
  $U$ meant the number of states and a random threshold,
  $c$ the chart index and weights,
  $w$ the warp function and weights.
  Avoid this from the start.

### Typeset correctly
- Multiplication: juxtaposition ($2ab$) or `\cdot`.
  Never `*`, which means convolution.
  `\times` only for the cross product and dimensions ($3\times3$).
  Elementwise product: `\odot`.
- Transpose `^\top`, not `^T`. Inverse `^{-1}`.
- Names of several letters upright: `\operatorname{round}` or `\DeclareMathOperator`.
- Labels in sub- and superscripts upright: `u_\mathrm{max}`, `\kappa^\mathrm{range}`. Indices italic: `x_i`.
- Norms `\Vert \vect{x} \Vert_2`, absolute values `\vert x \vert`.
- Dots: `x_1, \ldots, x_n` between commas, `x_1 + \cdots + x_n` between operators.
- Keep inline math low: `\tfrac{1}{2}` or `1/2` instead of `\frac{1}{2}`.
- Write "for all", not $\forall$, in text.
- Optional, after ISO 80000-2: upright d in integrals (`\mathrm{d}x`), upright e and i. Be consistent.

### Equations are part of the sentence
- End a displayed equation with the punctuation of the sentence, inside the display.
- No colon before a display, unless the sentence needs one anyway ("as follows:").
- If the sentence continues after the display ("where ..."), leave no blank line.
  A blank line starts a new, indented paragraph.
- Align multi-line equations at the relation signs (`align`, `aligned`). Break lines before operators.
- Only referenced equations get a number (`showonlyrefs`, preset). Refer with `\cref`: "Eq. (4)".

```latex
The Euclidean norm of a vector $\vect{x}\in\mathbb{R}^n$ is
\begin{equation}
    \left\Vert \vect{x} \right\Vert_2 = \sqrt{\sum_{i=0}^{n-1} x_i^2},
    \label{eq:Norm}
\end{equation}
where $x_i$ are the components of $\vect{x}$.
```

### Proofs and derivations
- Define every symbol before its first use.
- Repeat the name when a symbol returns after a while: "the sample spacing $\varepsilon$".
- Keep proofs short: one chain of (in)equalities, then the equality case.
- Prefer elementary, algebraic arguments.
- Long proofs go into the supplemental material.
- Verify every formula numerically with a small script. It finds errors early.

## 4. Figures

### Vector graphics
- Diagrams and sketches: SVG in Inkscape, included with `\includesvg`.
  LaTeX typesets the text, so fonts and math match the paper.
  Write LaTeX directly into Inkscape text boxes.
- Exact geometry and plots from data: TikZ and pgfplots.
  pgfplots reads CSV files, so data and plot stay consistent.
- Python plots: export SVG with text as text (`plt.rcParams['svg.fonttype'] = 'none'`), include with `\includesvg`.
- Never include plots as PNG or JPEG.

### Raster images
- Only for renderings and screenshots.
- PNG, never JPEG. JPEG artifacts look like rendering errors and corrupt error images.
- Place raster images in an SVG and embed them, do not link them.
- Native resolution, never upscaled. Show zoom-ins with nearest-neighbor sampling.
- Compare images under the same conditions: view, crop, exposure, tone mapping.

### Layout
- Draw at the final size: set the SVG page to the column or text width and include it unscaled.
  Then fonts and line widths match the paper.
- Give the page width in mm: Inkscape's pt is 1/72 inch, TeX's pt 1/72.27 inch.
  The EG column (240 pt) is 84.35 mm wide, the text (504 pt) 177.14 mm.
  The test bed in the appendix of the sample paper prints the widths of your template.
- Align with snapping and Align and Distribute (Shift+Ctrl+A). Equal sizes and gaps for sub-figures.
- Text in figures is not smaller than the caption text.
- Line widths, colors, dashes, and arrow heads from `figs/BaseTemplate.svg` and the palette `tools/inkscape/PaperPalette.gpl`.
- Avoid transparency.
- Label sub-figures (a), (b), ... always at the same place. Refer to them in caption and text.
- No titles inside figures. The caption has the title.

### Color
- One color per method in all figures and plots.
- Color-blind safe. Never red against green alone. Add line styles or markers.
- Perceptually uniform colormaps (viridis, magma) for magnitudes, diverging maps for signed values. Never rainbow (jet).
- Every color-coded image has a colorbar with quantity, unit, and range. Use the same range for compared images.

### Placement
- Reference every figure in the text, in the order of appearance.
- Prefer the top of the page (`[t]`). Full-width figures with `figure*`.
- Do not fight float placement before the final version.
- Credit assets in the caption or the acknowledgments: author, source, license.

## 5. Captions
- Start every caption with a title: `\captiontitle{Test Meshes}` prints "Test Meshes." in the style of the venue.
  Change the style once in `common/commands.tex`, e.g., `\textbf` if the venue sets captions in italics.
- The title is a short noun phrase in title case.
- Then 1 to 3 sentences: what we show, how to read it (axes, colors, units, (a), (b)), and the takeaway.
- Active voice: "We compare ...". Never "This figure shows ...".
- Self-contained: readable without the text.
- Figure captions below the figure.
  Table captions: follow the venue and be consistent.
  Our recent EG papers put them below; `templates/eg/main.tex` sets `\captionsetup{tableposition=bottom}` for it.
- Theses with a list of figures: give the title as short caption, `\caption[Test Meshes]{\captiontitle{Test Meshes} ...}`.

```latex
\caption{\captiontitle{Test Meshes}
    $V$ denotes the number of vertices, $T$ the number of triangles.
    Random colors mark the meshlets.}
```

## 6. Tables

We use modern tables (booktabs).
`tabs/subdivision.tex` is an example; `scripts/sample_paper.py` writes it.

- Vertical lines sparingly, only if columns are ambiguous without them.
- Horizontal lines of different weight, by meaning:
  - `\toprule` and `\bottomrule` (thick) frame the table,
  - `\midrule` (medium) separates the header from the body and row groups,
  - `\cmidrule(lr){2-3}` (thin, partial) groups columns under a shared header.
- `\addlinespace` instead of a line for subtle row groups.
- No double lines, no grid.
- Units in brackets in the header, not in the cells: `Time [\si{\milli\second}]`.
- Arrows in the header: `$\downarrow$` lower is better, `$\uparrow$` higher is better.
- Right-align numbers, or align them at the decimal point (siunitx `S` columns). Same number of decimals per column.
- Bold the best value per group, `\textbf{\num{0.59}}`, and say so in the caption.
- Order rows meaningfully: baselines first, ours last.
- Never scale a table with `\resizebox`. Fonts then vary.
  Use `\small` or `\footnotesize`, shorter headers, or transpose the table.
- A script writes the table from the data. Name the script in a comment at the top of the table file.

```latex
\begin{tabular}{@{}llrr@{}}
\toprule
 & & \multicolumn{2}{c}{Error [\si{\degree}]} \\
\cmidrule(lr){3-4}
Budget & Method & Max $\downarrow$ & Mean $\downarrow$ \\
\midrule
\multirow{2}{*}{32} & Baseline & 0.0996 & 0.0537 \\
                    & Ours & \textbf{0.0826} & \textbf{0.0475} \\
\bottomrule
\end{tabular}
```

## 7. Code
- Listings only if code says it better than text or pseudocode.
- Short, under 20 lines, no boilerplate.
- `lstlisting` with `language=...`, a label, and a caption with `\captiontitle`.
- Names in code match the symbols in the text. `mathescape=true` lets you write `$u$`, `$C_2$`.
- Spaces, no tabs. Lines must fit the column.
- Algorithms: pseudocode with line numbers (`algpseudocode`). Refer to lines.
- Identifiers, API calls, and file names in the text: `\texttt{ExecuteIndirect}`.
- Publish the code and link the repository. Anonymize the link for the review.

## 8. References and Citations
- Internal references with `\cref` and `\Cref`: "Sec. 3", "Tab. 1", "Eq. (4)", written out at the start of a sentence.
  Never type `Fig.~\ref`.
- No "above", "below", or "the following figure". Use `\cref`.
- A citation is never a noun.
  Not "As suggested by [Unt21], ...",
  but "Meshlets work for skinned meshes [Unt21]." or "Unterguggenberger et al. [Unt21] use meshlets."
- `text~\cite{X}.` before the period. Several citations in one `\cite{A,B}`.
- Citation keys: family name of the first author, two-digit year, first letters of the first three significant words of the title.
  Example: Unterguggenberger et al. 2021, *Conservative Meshlet Bounds for Robust Culling of Skinned Meshes*: `Unterguggenberger21CMB`.
- Keep a copy of every cited PDF in the bibliography folder.
- Complete entries, consistent venue names, DOIs. Protect capitals: `{GPU}`. Check them with `./BibPreview.sh`.
- Cite the published version, not the preprint. Cite software, data sets, and assets.

## 9. LaTeX Source
- One sentence per line. Diffs and merges stay readable.
- Labels with a prefix for the type: `sec:`, `fig:`, `tab:`, `eq:`, `lst:`. Be consistent.
- Notation and method names in `common/commands.tex`, packages in `common/packages.tex`, never in section files.
- No manual layout (`\vspace`, `\\`, `\newpage`, font sizes) before the final version.
- `\todo{who}{what}` for open points. Before submitting, no `\todo` is left.
- Every number in the text comes from a table, a figure, or a script. Recheck all of them after every data update.
- Zero warnings: no undefined references, no multiply defined labels, no overfull boxes.
- Final polish: no single word on the last line of a paragraph. Rephrase.

## 10. Assets
- For every asset in a figure, create a folder in `Asset/` with
  - `AssetInformation.txt`: author, contact, source (e.g., URL), date obtained, who obtained it,
  - the license file,
  - a screenshot of the source showing the model and its license.
- Prefer Creative Commons assets.
- Do not use "Lenna". IEEE, Taylor & Francis, and Nature Publishing Group disallow or discourage it.

## 11. Workflow
- Start with a skeleton: headings, one topic sentence per paragraph, sketches of the figures, the contributions.
  Get feedback early.
- Make figures early. They drive the story.
- Read only the first sentences of all paragraphs. They should tell the story.
- Read your text aloud.
- Check spelling and grammar, e.g., with LTeX (LanguageTool) in VS Code.
- Commit often with meaningful messages.
- AI tools: follow the policy of the venue and the lab, and disclose their use.
  Verify every statement and every number. You are responsible for the content.

## Checklist Before You Hand In a Draft
- [ ] Every figure and table is referenced in order and has a caption with a title.
- [ ] Every symbol is defined, listed in `tabs/ListOfSymbols.tex`, and has one meaning only.
- [ ] Displayed equations end with punctuation. No `*` for multiplication.
- [ ] Notation only via macros. No `\bf`, `\vec`, `\mathbf` in the text.
- [ ] Terms introduced with `\term`, acronyms only via `\ac`.
- [ ] Numbers and units with siunitx.
- [ ] Figures as vector graphics, raster images as PNG, colorbars with units.
- [ ] Tables without `\resizebox`, with units in the header.
- [ ] Spell and grammar check done.
- [ ] No warnings, no overfull boxes, no `\todo`.
- [ ] For review: anonymized (`\BlindSubmission`), no identifying links.
- [ ] `make package` and `make arxiv-test` pass.
