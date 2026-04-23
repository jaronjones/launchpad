# Top 10 Git/GitHub Commands for Developers

A quick reference of essential `git` commands every developer should know for working with GitHub.

## Setup & Cloning

### 1. `git clone` — Clone a Repository
Copy a remote repo to your local machine.
```bash
git clone https://github.com/user/repo.git
git clone git@github.com:user/repo.git           # via SSH
git clone https://github.com/user/repo.git dir   # into a custom directory
```

### 2. `git init` — Initialize a Repository
Start version-controlling an existing directory.
```bash
git init
git remote add origin https://github.com/user/repo.git
```

## Daily Workflow

### 3. `git status` — Check Working Tree State
See which files are modified, staged, or untracked.
```bash
git status
git status -s       # short format
```

### 4. `git add` — Stage Changes
Move changes to the staging area, preparing them for commit.
```bash
git add file.txt
git add .                   # stage all changes in current dir
git add -p                  # interactively stage hunks
```

### 5. `git commit` — Record Changes
Save staged changes to the local history.
```bash
git commit -m "Add feature X"
git commit -am "Fix bug"    # stage tracked files + commit
git commit --amend          # edit the most recent commit
```

### 6. `git push` — Upload Commits
Send local commits to the remote repository.
```bash
git push
git push origin main
git push -u origin feature-branch   # set upstream on first push
```

### 7. `git pull` — Fetch & Merge
Sync local branch with its remote counterpart.
```bash
git pull
git pull --rebase           # rebase local commits on top of remote
```

## Branching & Merging

### 8. `git branch` / `git checkout` — Manage Branches
Create, list, and switch between branches.
```bash
git branch                      # list local branches
git branch feature-x            # create a new branch
git checkout feature-x          # switch to a branch
git checkout -b feature-x       # create and switch in one step
git switch feature-x            # modern alternative to checkout
```

### 9. `git merge` — Combine Branches
Integrate another branch's history into the current branch.
```bash
git checkout main
git merge feature-x             # merge feature-x into main
git merge --no-ff feature-x     # preserve the branch topology
```

## Inspection

### 10. `git log` — View History
Review the commit history.
```bash
git log
git log --oneline               # condensed view
git log --graph --all --oneline # visualize branches
git log -p file.txt             # show changes per commit for a file
```

---

## Bonus: GitHub CLI (`gh`)

Install [`gh`](https://cli.github.com) for powerful GitHub interactions from the terminal:

```bash
gh repo clone user/repo             # clone a repo
gh pr create                        # open a pull request
gh pr list                          # list PRs
gh pr checkout 123                  # check out PR #123
gh issue create                     # open an issue
gh repo view --web                  # open the repo in a browser
```

## Handy Tips

- Configure your identity once: `git config --global user.name "Name"` and `git config --global user.email "email@example.com"`.
- Use `.gitignore` to exclude files (node_modules, .env, build artifacts) from version control.
- Write clear commit messages: short subject line, then a blank line, then details if needed.
- Before pushing, run `git status` and `git diff --staged` to confirm what you're about to commit.
