# Common Queries 



##### See a list of *which* apps you used yesterday

```bash
cat LOGFILE | jq .app -r | sort | uniq
```

##### See how much time you spent on a specific app 

```bash
cat LOGFILE | jq 'select()'
```

**Parse for *today*** (e.g. Chrome Usage)

```bash
cat logfile | jq 'select(.app=="Google Chrome")' | jq 'select(.timestamp > "'$(date +%Y-%m-%d)'")'
# This date format just works; it goes on a day-basis
# $(date +%Y-%m-%d) === today
```

