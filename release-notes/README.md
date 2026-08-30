# Release notes

One file per release: `0.2.0.html`, an HTML **fragment** (no `<html>` wrapper).
`scripts/release.sh` copies it next to the archive so Sparkle shows it in the
update panel.

```html
<h3>What's new</h3>
<ul>
  <li>Week view remembers which day you were on.</li>
</ul>
```

No file means an empty changelog, and the release script says so loudly.
