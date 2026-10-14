# Job Search Finder

[![Job Search Finder](docs/shot-jobsearch.jpg)](https://mariaserrano01.github.io/digitalportfolio/job-search-finder/)

A **marketing job finder**: pick a country and the screen splits into **analytical roles** and **strategic roles**, each filtered by role type. Part of a marketing analytics portfolio. One HTML file, no build step, no framework, no server: everything runs in the browser.

**Live page:** [mariaserrano01.github.io/digitalportfolio/job-search-finder](https://mariaserrano01.github.io/digitalportfolio/job-search-finder/) · or open `index.html` locally. Part of [María Serrano's portfolio](../README.md).

## The three sections

1. **Job search.** Filter by **country** first (United States by default; Colombia and all countries available), then the screen splits in two: **Analytical roles** (analytics, insights, growth, CRM, digital) and **Strategic roles** (strategy, brand, operations, communications), each with its own **role type** and area filter. Work arrangement (on-site, hybrid, remote), job type, level, industry, pay and skills apply to both sides. Every card explains what the job is, the requirements and, for the researched openings, where it sits in marketing, what to study and how to approach it. Below the split, KPI tiles and charts (openings by area, by role type, by work arrangement, by industry, pay ranges against your minimum) react to every filter. Any opening can be promoted to Dream Jobs with one click.
2. **Learn the areas.** The eight areas of marketing, grouped the same way. Analytical: Marketing Analytics, Consumer Insights & Market Research, Growth & Performance Marketing, CRM & Lifecycle Marketing, Product & Digital Marketing. Strategic: Marketing Strategy, Brand Management, Marketing Operations & Communications. Each card gives the question the area answers, what you do, methods, tools, the role types you will see in postings (clickable), where the jobs are and what to study.
3. **Dream Jobs.** A shortlist ranked with a Relevance score (0–100): resume match 35 · role fit 25 · your interest 25 · salary compatibility 15. Filters for country, track (analytical or strategic), area and role type, a detail view with the score breakdown, favorites, application status, 1–10 ratings, notes, CSV/JSON export, and charts (relevance of the top 15, published pay vs your minimum, the skills postings ask for colored by whether your resume has them, openings by area, role type and industry, your pipeline).

## Your profile and your data

- **Resume.** Upload a PDF, Word (.docx) or text file, or paste the text. The page scans it for the skills each posting asks for (its named tools plus a lexicon of about 130 marketing, analytics and business skills) and shows a match percentage with the skills found and missing. The resume never leaves the browser, is kept in memory only and is gone on reload.
- **Salary targets.** A target and a minimum per currency: USD per year for the United States, COP per month for Colombia (other currencies appear when your openings use them). Every posting gets a Salary Match label against the pay the employer publishes; in Job search, "Hide below my minimum" uses the minimum.
- **My data.** Add your own openings (any marketing role, any country) and areas, hide the sample set, and export or import everything as one JSON file. Targets, openings, areas, favorites, statuses, ratings and notes are saved in this browser's local storage. Nothing is sent anywhere.

Light and dark mode, phone layout, keyboard-accessible, colorblind-checked chart palette.

## Sample data

`index.html` embeds a sample set: 83 marketing openings in the United States and Colombia (55 of them Dream Jobs), found on job boards and the employers' own careers pages and verified on October 13, 2026; postings may have closed since. Dream Jobs fields: company, title (with the original title when the posting is in Spanish), official URL, requisition ID, location and arrangement, employment type, seniority, timing, industry, area and role type, published pay (currency, period, range, base vs total), the posting's own words on visa sponsorship, a paraphrased description, responsibilities, required and preferred qualifications and named tools. Descriptions are paraphrases, not posting text.

## Try it

Open `index.html`, click **Resume** at the top and drop in `sample-resume.txt` to see the resume match in action, then replace it with your own. Click **Add an opening** to add a posting of your own.

## Running it yourself

Download `index.html` and open it in any browser; there is nothing to install. To host your own copy, put the file in a GitHub repository and enable GitHub Pages (Settings → Pages → *Deploy from a branch*).

---

Built as a job-search portfolio project. The resume match is keyword-based and meant as a triage aid, not a judgment of anyone's qualifications. Pay marked as an estimate is an estimate, not the employer's figure.
