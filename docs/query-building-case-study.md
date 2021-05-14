# Case Study



Imagine -- I've been spending too much time on *Signal*, a desktop application that allows me to talk with my friends & family. I want to limit my Signal usage to 30 minutes per day. Once I've hit that 30 minute threshhold, I'd like it to start booting me off Signal. 

##### The QPA:

```bash
# QUERY;PREDICATE;ACTION
QUERY;>30;pkill Signal
```

Now that we've got the general idea scoped-out, we want to write the query as a one-liner. 

```bash
# 1. Get all instances where Signal is the app, today
# 2. Make it an array
# 3. Get the count
```

Start with just `cat`'ing out the file:

```
cat logfile | jq .
```

All good? Now see what the data outputs

```sh
# ...
{
  "app": "iTerm2",
  "timestamp": "2021-05-13T23:46:03.266Z",
  "title": "CursorShape=1 (tmux)"
}
{
  "app": "iTerm2",
  "timestamp": "2021-05-13T23:46:04.622Z",
  "title": "CursorShape=1 (tmux)"
}
{
  "app": "iTerm2",
  "timestamp": "2021-05-13T23:46:05.972Z",
  "title": "CursorShape=1 (tmux)"
}
user $ 
```

Ok, so we don't want those other apps. But we remember that it's named "Signal", so let's try matching on that:

```bash
cat logfile | jq 'select(.app=="Signal")'
```

Success!:

```bash
{
  "app": "Signal",
  "timestamp": "2021-05-13T23:45:21.455Z",
  "title": "Signal"
}
{
  "app": "Signal",
  "timestamp": "2021-05-13T23:45:22.817Z",
  "title": "Signal"
}
user $ 
```

Now to be safe, let's filter on today. 

Personally, I don't know how to "filter for date is today using jq", so I'll just google it.
Now, this yields a link that doesn't have exactly what I want: [LINK](https://github.com/stedolan/jq/issues/1056)
... so I'm going to fiddle with it until I have a manual value that works vs. does not work, and once I've convinced myself that it is doing something reasonable (e.g. is not tautological), then I'll functionalize it.

Fiddling:

```bash
# does not work, always grabs everything regardless of what the value is
cat logfile | jq 'select(.app=="Signal")' | jq 'select(.timestamp > 2021-05-14)' 

# ok so it needed quotes 
# GRABS NOTHING -- the data was -13, not -14
cat logfile | jq 'select(.app=="Signal")' | jq 'select(.timestamp > "2021-05-14")' 
# GRABS ALL -- this makes sense, today is 2021-05-13
cat logfile | jq 'select(.app=="Signal")' | jq 'select(.timestamp > "2021-05-13")' 
# STILL GRABS ALL
cat logfile | jq 'select(.app=="Signal")' | jq 'select(.timestamp > "2021-05-12")' 
```

(👍⌐■_■)👍, so let's functionalize it now:

```bash
# fiddle around with date -- this is how we could get YYYY-MM-DD string on the cmdline
$ date +%Y-%m-%d #> 2021-05-13
# ok, let's just plug it in:
cat logfile | jq 'select(.app=="Signal")' | jq 'select(.timestamp > "'$(date +%Y-%m-%d)'")' 
#> JSON ENTRIES
# Now we just need to count how many records we got (and we assume that the script was running minute-ly)
cat logfile | jq 'select(.app=="Signal")' | jq 'select(.timestamp > "'$(date +%Y-%m-%d)'")' | jq --slurp length
#> 17
```

🎉🎉🎉 We've got our `QUERY` (probably, saving any weird quote-escape issues).

