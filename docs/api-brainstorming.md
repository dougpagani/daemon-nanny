# API design brainstorming & usage process/patterns

### Data:

- timestamp -- self-generated, not from `active-win`
- `owner.name` -- this is the app, e.g. "Google Chrome"
- `title` 
  - (often has title of youtube video, but is, depending on application state (in search bar doesnt work for example) is title='')
- if chrome, `url` (always seems to work)
- `owner.processId` (could be used to find out how long an app has been up)
- applications seem to possibly have unique/idiosyncratic extra pieces of info available (e.g. chrome has `url` as a top-level field)

### Storage
- **format**: 2 possibilities: store in json _or_ line-per
  - single-line json entries could be just as easily processed with jq, yet having the other half of *best of both worlds* being that it is easily **appendable**.
  - **possible plaintext entry format**: `timestamp,app,[url],title` 
- **log file location** -- we want to put in this repo, or a dotfile in the `$HOME`

### Event Examples

A website, within an app, 

#### "Bad"
```json
{
  url: 'https://www.youtube.com/watch?v=qleVGNlyb_s',
  id: 155837,
  bounds: { y: 23, height: 1057, x: 0, width: 1920 },
  title: 'Magnus Carlsen: "A Very Friendly Guy." - YouTube',
  owner: {
    processId: 20955,
    name: 'Google Chrome',
    bundleId: 'com.google.Chrome',
    path: '/Applications/Google Chrome.app'
  },
  memoryUsage: 1152,
  platform: 'macos'
}
```
*Signature:* `url` is `contains("youtube")`

#### "Good"

```json
{
  id: 156063,
  bounds: { x: 0, y: 23, height: 1057, width: 1920 },
  owner: {
    path: '/Applications/iTerm.app',
    processId: 50270,
    bundleId: 'com.googlecode.iterm2',
    name: 'iTerm2'
  },
  title: 'CursorShape=1 (tmux)',
  memoryUsage: 8119576,
  platform: 'macos'
}
```

*Signature:* app is `contains("iTerm2")`

#### Neutral

... everything else

​	

### Example Analysis/Interaction/Query-building with the data

#### Case Study: Colors

```sh
cat example-jsons.log | jq  '{ color: .color, name: .name }' | jq -s
```

- let's imagine "green" is a time-sink that we want to blacklist
- by blacklist, really, we mean we want to shut down the app-of-interest when we detect this activity on it
- we filter on green, and grab a count of minutes
  - this assumes *we count one entry as one minute*
- when over some pre-defined, personally-defined threshhold, we want to run a command
- for the command, we want to maybe
  - run a russian roulette that has some significant chance of a system-shutdown

This yields a QPA of:

`QUERY-WRITTEN-ABOVE;>30;pkill "Google Chrome"`

#### Possible real queries 

- for each blacklisted activity, give me how many minutes spent after 10pm today
  - whether or not we have a rather hard-coded api like this will depend upon what kinds of actions we tend to want. Upon exploration, it seems like we probably do not.
  - instead, we can just have a generalized api of QPA. Instead of some "blacklisted-activities.txt" file


#### Useful Queries
You would do these sorts of things in a morning-after interrogation (a sort of post-mortem for dopamine-chain events):
##### analyze, look-around

```sh
cat example-jsons.log  | jq '.color' | uniq -c 
# at a certain point, you'll want it in array form (for various situationally-dependent reasons). The below is exactly equivalent to the above form, except it is extensible in different regards. Notice that jq -s & map are added/removed in concert.
cat example-jsons.log  | jq -s |  jq 'map(.color)' | jq .[] -r | uniq -c
```
##### answer specific question (query for specific datapoint)
_Q: How many minutes did I spend doing green?_

```sh
cat example-jsons.log  | jq -s |  jq 'map(select(.color=="green"))'  | jq length 
#> 3 
```

Notice here that this number is "primed" for a conditional. So, the downstream predicate would be `> 3` or some other threshhold. 

##### Quick tutorial: How to actually build jq queries (you want to do work with this, in a cli-pipeline, iteratively as much as possible)

```sh
# PROBLEM: you've got a big heckin' blob of json, and you produce/cat it and it just overfills the screen and you cant tell the structure of it. You want to get a lay of the land. 
# Thing to keep in mind: Generally, json is made programmatically, so it is typically _consistent_ at some lower/atomic level, no matter how big it is.
# always start with `keys`
cat JSON | jq keys
# if you see a bunch of numbers, your top-level is an array. So, grab an example of that array.
cat JSON | jq .[0] | jq keys
# Again, if array, then grab the zero-th element again
cat JSON | jq .[0] | ... | jq .someLeafKeyYouThinkIsInteresting
# now you want to run a map-select on that so you get a "feel" for how that field varies across the entire dataset
cat JSON | jq 'map(.someLeafKeyYouThinkIsInteresting)' | ...
cat JSON | jq 'map(.someOtherField)' | ...
# Things you can generally do from here:
# - Predicates
cat JSON | jq 'map(select(.someOtherField=="enumerateValue")' | ...
# - other cli stuff
cat JSON | jq 'map(.someLeafKeyYouThinkIsInteresting)' | sort | uniq -c # count
# In many problem-contexts, you'll need to interweave calls of jq -s and jq .[], which slurps/restructures vs. destructures json arrays. Basically, jq is fluent in this regards because it treats an array of objects in a single json blob, and many json blobs sent over the wire via line-wise stdout rather similarly -- it can deal fluently with both, and convert between the two.
TODO -- example for this kind of thing
```



#### Possible API ( Format of specification ):

Special Syntax: (that we parse on the `;`s)

```
QUERY;PREDICATE;ACTION
shell;js-ish-symbols-for-comparators;command (something you can find on $PATH)
```

**Query would look something like this:**

```sh
cat example-jsons.log  | jq -s |  jq 'map(select(.color=="green"))'  | jq length;
```



`ACTION` examples, just to provide some brainstorming context

- sudo shutdown now
- redshift 
- notify

### etc. grey-area considerations

- **Predicate-building**: how do you detect a blacklisted activity?: either app or url-defined
- enhancement: throw-out url's which match a certain pattern (e.g. programming-related words)
- ... this can just be built in the query
- count one entry, as one minute

Predicate-Action:
if over 30, shutdown machine