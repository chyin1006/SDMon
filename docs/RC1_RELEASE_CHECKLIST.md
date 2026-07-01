# SDMon V2 RC1 Release Checklist

## Repository Checks

- [ ] `git status` is clean after the RC1 commit.
- [ ] `git log --oneline -10` shows `Finalize SDMon V2 RC1`.
- [ ] All `tests/test_*.sh` scripts pass.
- [ ] V1.1 files remain unchanged unless explicitly intended.

## RC Validation

- [ ] `./sdmon-v2.sh` runs the full scan.
- [ ] Administrator password is requested once.
- [ ] Administrator privilege is released after scan completion.
- [ ] `output/report.html` is generated.
- [ ] `output/report.pdf` is generated.
- [ ] `output/report.zip` is generated.
- [ ] `output/report.json` is generated.
- [ ] `output/report.csv` is generated.
- [ ] `output/summary.txt` is generated.
- [ ] HTML report opens automatically on macOS.
- [ ] PDF layout keeps Device, Executive Summary, and Statistics compact.

## GitHub Release Steps

1. Commit RC1:

```bash
git add .
git commit -m "Finalize SDMon V2 RC1"
```

2. Push main:

```bash
git push origin main
```

3. Create tag:

```bash
git tag v2.0.0-rc1
git push origin v2.0.0-rc1
```

4. Create GitHub Release:

- Tag: `v2.0.0-rc1`
- Title: `SDMon V2 RC1`
- Notes: use `docs/RELEASE_NOTES_RC1.md`

## Release Artifacts

- HTML: `output/report.html`
- PDF: `output/report.pdf`
- ZIP: `output/report.zip`
- JSON: `output/report.json`
- CSV: `output/report.csv`
- Summary: `output/summary.txt`

## Freeze Policy

After RC1 is published:

- Do not add new RC1 features.
- Only severe RC1 bugs should be fixed on top of the release candidate.
- Future development should move toward Beta work.

