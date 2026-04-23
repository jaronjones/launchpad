# Top 20 Terminal Commands for Developers

A quick reference of essential Unix/Linux terminal commands every developer should know.

## Navigation & File System

### 1. `cd` — Change Directory
Move between directories.
```bash
cd /path/to/dir     # absolute path
cd ..               # parent directory
cd -                # previous directory
cd ~                # home directory
```

### 2. `ls` — List Files
List directory contents.
```bash
ls              # basic listing
ls -la          # long format, including hidden files
ls -lh          # human-readable file sizes
```

### 3. `pwd` — Print Working Directory
Show the full path of the current directory.
```bash
pwd
```

### 4. `mkdir` — Make Directory
Create new directories.
```bash
mkdir my-project
mkdir -p a/b/c      # create nested directories
```

### 5. `rm` — Remove Files
Delete files and directories. **Use with caution.**
```bash
rm file.txt
rm -r directory/    # recursive (directories)
rm -rf directory/   # force, no prompts — dangerous
```

### 6. `cp` — Copy Files
Copy files and directories.
```bash
cp source.txt dest.txt
cp -r src-dir/ dest-dir/
```

### 7. `mv` — Move/Rename
Move or rename files and directories.
```bash
mv old.txt new.txt          # rename
mv file.txt /new/location/  # move
```

## File Inspection

### 8. `cat` — Concatenate/Display
Print file contents to stdout.
```bash
cat file.txt
cat file1.txt file2.txt > combined.txt
```

### 9. `less` — Paged Viewer
View large files one page at a time. Press `q` to quit, `/` to search.
```bash
less large-log-file.log
```

### 10. `tail` — Show End of File
View the last lines of a file — great for logs.
```bash
tail file.log
tail -n 50 file.log     # last 50 lines
tail -f file.log        # follow new output in real time
```

## Search

### 11. `grep` — Search Text
Search for patterns in files.
```bash
grep "pattern" file.txt
grep -r "pattern" .             # recursive
grep -i "pattern" file.txt      # case-insensitive
grep -n "pattern" file.txt      # show line numbers
```

### 12. `find` — Find Files
Locate files by name, type, size, or modification time.
```bash
find . -name "*.js"
find . -type f -mtime -7    # files modified in last 7 days
find . -size +10M           # files larger than 10 MB
```

## Permissions & Process Management

### 13. `chmod` — Change Permissions
Modify file access permissions.
```bash
chmod +x script.sh          # make executable
chmod 755 script.sh         # rwxr-xr-x
chmod 644 file.txt          # rw-r--r--
```

### 14. `ps` — Process Status
List running processes.
```bash
ps aux                      # all processes, detailed
ps aux | grep node          # find node processes
```

### 15. `kill` — Terminate Process
Stop a running process by PID.
```bash
kill 1234                   # graceful (SIGTERM)
kill -9 1234                # force (SIGKILL)
```

## Networking & Data Transfer

### 16. `curl` — HTTP Client
Transfer data from or to a server.
```bash
curl https://api.example.com/data
curl -X POST -d '{"key":"value"}' -H "Content-Type: application/json" https://api.example.com
curl -o file.zip https://example.com/file.zip
```

### 17. `ssh` — Secure Shell
Connect to remote machines securely.
```bash
ssh user@hostname
ssh -i ~/.ssh/key.pem user@hostname
```

## Output & Piping

### 18. `echo` — Print Text
Output text or variables.
```bash
echo "Hello, World!"
echo $PATH
echo "content" > file.txt   # write to file
echo "more" >> file.txt     # append to file
```

### 19. `|` (Pipe) — Chain Commands
Pass output of one command as input to another.
```bash
ps aux | grep node
cat file.log | grep ERROR | wc -l
ls -la | less
```

### 20. `man` — Manual Pages
Read documentation for any command.
```bash
man ls
man grep
```

---

## Bonus Tips

- Use **Tab** for auto-completion of files, directories, and commands.
- Use **Ctrl+R** to search through command history.
- Use **Ctrl+C** to cancel a running command.
- Use **Ctrl+L** (or `clear`) to clear the terminal screen.
