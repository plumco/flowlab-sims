# Huliot Simulators

Static website. No build step, no server code.

## Put it online (free, pick one)
- **Netlify Drop**: open app.netlify.com/drop, drag this whole folder in. You get a link to share.
- **GitHub Pages**: push this folder to a repo, Settings > Pages > deploy from `main` / root. Link is `https://<user>.github.io/<repo>/`.

## Add a new simulator later
1. Build the simulator as one HTML file.
2. Run: `python3 add-sim.py my-sim.html --slug my-sim --title "My Simulator" --desc "One line." --tags "Drainage,PRL"`
3. Upload the folder again (or push to GitHub). The card appears on the home page.

Manual way: copy the file to `sims/<slug>/index.html` and add one entry in `sims.js`.
