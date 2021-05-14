# QPA Long-Term Vision
This is not necessarily the best framework/syntax for doing this sort of stuff. We envision some high-level API stuff (for example, popping from a Todoist queue of movies to watch when we just bumble onto youtube), for which we definitely would want javascript, but we can't get there overnight. 

Ideally, we have something that looks like this:

```sh
QUERY;PREDICATE;ACTION
minutes-spent-on-youtube-past-10pm;>1;dim-the-lights
# dimming the lights entails redshifting to get the circadian rhythm going
```

Or even more advanced:
```sh
QUERY;PREDICATE;ACTION
hopped-on-chat-during-workday;>1;pop-a-suggestion-of-message-you-wanted-to-send
# where you had wanted to stay focused, but remembered a thing for later
do-something-productive-after-7pm;>20;show-picture-of-loved-ones-that-makes-you-happy
# where the picture serves to "pavlov's dog" yourself
do-something-unproductive-after-workday;>1;suggest-a-todo
# where the todo needs to be grabbed from a high-level external API
```

... But these capabilities are not easy ones to build. We could envision getting there by simply having `userscripts/` where we can develop when they come up as burning desires. Maybe we even have a `builtin-scripts/` that serve as primitives for QPA-aspects. But as a first-approach, we can glue together stuff with shell:

```sh
QUERY;PREDICATE;ACTION
cat logfile | jq 'select(.app=="Signal")' | jq 'select(.timestamp > "'$(date +%Y-%m-%d)'")' | jq -s length;1===1;echo do nothing
```

### userscript-only-QPA
get-all-signal-ones-for-today;has-been-a-good-day;share-with-family-that-today-has-been-good

### built-ins can provide some complex, yet foundational functionality

```
Q;P;notify "message"
```

Where "notify" is special-parsed, and an internal routine is run for that which hooks-up system native notifications.

### v0 -- where do we start?

To start, we want a nice, fugly, iterable interface. And our simplest use cases entail:
1. detecting conditions (activity) on a machine
2. modifying that machine somehow (redshift, sys shutdown, kill app, notify suggestions, etc.)

