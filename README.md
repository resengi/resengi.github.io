# Resengi Website

Marketing and financials site for Resengi, served at
[resengi.io](https://resengi.io). Static HTML/CSS/JS plus two Flutter web projects that render the live charts and open-source demos.

## Structure

```
.
├── index.html, why.html, services.html,
│   financials.html, opensource.html, contact.html  # Static pages
├── css/style.css                                   # All styles
├── js/main.js                                      # Nav, mobile menu, CSV table
├── data/expenses.csv                               # Source of truth for financials
├── images/, icons/, favicon.svg, og-image.png      # Assets
├── charts/                                         # Flutter project: live charts
│   └── README.md                                   #   (financials.html iframe)
├── examples/                                       # Flutter project: package demos
│   └── README.md                                   #   (opensource.html iframes)
├── llms.txt, llms-full.txt                         # LLM-friendly site summaries
├── sitemap.xml, robots.txt, .well-known/, CNAME    # SEO / hosting config
└── .github/workflows/                              # CI/CD
```

The static pages are hand-written HTML. The Flutter projects
under `charts/` and `examples/` are the only parts that need compiling; their build output lives at `/flutter-charts/` and `/flutter-examples/` and are loaded by the static pages via iframes.

## Local development

For pure HTML/CSS/JS edits, just open the file in a browser. No server needed unless you want to test the financials page (which fetches the CSV via `fetch()` and needs a real origin).

## Deployment

GitHub Pages, deploy-from-branch on `main`. CI builds the Flutter
projects on push and commits the build output back to `main` so Pages can serve it directly. See `.github/workflows/` for the workflow.

The custom domain (`resengi.io`) is configured via the `CNAME` file at the repo root.

## Editing common things

**Adding an expense row.** Append to `data/expenses.csv`. The financials table and the charts both read from this file at runtime.

**Editing copy on a static page.** Edit the relevant `*.html` directly. If the change is also reflected in the LLM summaries, update `llms.txt` and `llms-full.txt` to match.

**Changing chart appearance or behavior.** See `charts/README.md`.

**Updating an open-source package demo.** See `examples/README.md`.

**Adding a new page.** Create the HTML file, add it to the nav in every existing page (header and footer), and add an entry to `sitemap.xml`.

## Notes

- All icons are Lucide; see `icons/ATTRIBUTION.md`.
- The site assumes JavaScript for the financials table, the mobile nav, and the open-source demos. Static content (copy, hero, services, contact info) works without JS.
- Security contact and disclosure policy live in
  `.well-known/security.txt`.