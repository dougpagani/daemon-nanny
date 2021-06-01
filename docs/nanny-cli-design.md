# Nanny CLI Design

This cli is used to CONFIGURE the context-aware actions / QPA's.

- remind/stack (hook)
    - $ nanny remind chat "msg nick about PR's"
    - STACKS:
        - chat
        - chatdoug (something more specific)
        - signal
        - email
        - youtube
        ... any time you open it...
        - bash
        - ag
        - vim 
- limit (negative threshhold)
- reward (positive threshhold)
    - 10 minutes of typing practice per day
- help (hook, but not a reminder) / habit?
    - dim the nights at 10pm

- nanny sort
    - bisectional insertion of todos

Roadmap...
- figure out event-based hooks & api (how to define "events" detection, and then configure/manage hooks to those events)
- daemonize
- publishing other data streams (like ps -ef)
- hooking into those data streams (for stuff like tool-hooks)

#{replacement}

