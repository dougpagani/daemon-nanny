# macos troubleshooting cron



It works, no problem, with macos. It will request permissions out of iTerm, or whatever terminal emulator you're using, and is subsequently configurable in the Security & Privacy Preferences Pane.



***However,*** it does not work when run out of cron. There are two probable aspects to this:

1. It needs *Screen Recording* permission, which seems to be a bundle-only (things with reverse-domains) permission via TCC
2. It needs a valid `$DISPLAY` variable



The ***most*** likely next step is trying to manually write to TCC's database (a sqlite database). That would necessitate backing up the machine (very risky, could brick the driver).

> [LINK](https://stackoverflow.com/questions/59239485/screencapture-over-cron-shown-background-instead-window-content)
>
> JAMF, which is probably not how I want to do this -- PPPC [LINK](https://github.com/jamf/PPPC-Utility)

The ***second*** most likely step is to provision an apple script, instead of a cronjob (which seems to have access to these APIs).

> 

The ***third*** unfortunate step would be to make a real bundle, or at least a launchctl job. Since that has a reverse-domain handle, you could likely write some `csrutil` stuff to it.



### The problem

This error is realized, when trying to run out of cron:
![image-20210513190109028](/Users/dougpa/Library/Application Support/typora-user-images/image-20210513190109028.png)

### Tried so far

#### Messing with perms manually (avoiding triggering the prompt)

source: https://apple.stackexchange.com/questions/374158/why-is-screencapture-taking-the-screenshot-of-the-desktop-image-and-not-the-wind

```sh
tccutil reset ScreenCapture com.apple.Terminal
```



#### Reattaching the mach bootstrap hierarchy

main source: [LINK](https://superuser.com/questions/26956/use-cron-to-screen-capture-on-mac-os-x)

Code pieces:

```
# in sudoers
dougpa     ALL=(ALL) NOPASSWD: ALL
# as a script in ~/scrot.sh
#/bin/sh
loginwindowpid=`ps axo pid,comm | grep '[l]oginwindow' | sed -n 's# *\([^ ]*\).*$#\1#p'`
sudo launchctl bsexec $loginwindowpid screencapture ~/image3.png
# copied DISPLAY var
DISPLAY="/private/tmp/com.apple.launchd.AxtxweL1lR/org.macosforge.xquartz:0" 
# in crontab
* * * * * DISPLAY="/private/tmp/com.apple.launchd.AxtxweL1lR/org.macosforge.xquartz:0" /usr/sbin/screencapture ~/image1.png
* * * * * /usr/sbin/screencapture ~/image2.png
# * * * * * ~/scrot.sh
* * * * * DISPLAY="/private/tmp/com.apple.launchd.AxtxweL1lR/org.macosforge.xquartz:0" ~/scrot.sh
# * * * * * /Users/dougpa/.nvm/versions/node/v12.18.2/bin/node /Users/dougpa/daemon-nanny/index.js 
* * * * * DISPLAY="/private/tmp/com.apple.launchd.AxtxweL1lR/org.macosforge.xquartz:0" /Users/dougpa/.nvm/versions/node/v12.18.2/bin/node /Users/dougpa/daemon-nanny/index.js  >> /Users/dougpa/daemon-nanny/cronlog 2>&1

```

even more info: [LINK](https://apple.stackexchange.com/questions/23441/using-screencapture-when-remotely-logged-in-to-a-headless-mac-via-ssh)

#### Links to possible resources/context

- https://stackoverflow.com/questions/59239485/screencapture-over-cron-shown-background-instead-window-content

- [This guy suggests to use an apple script -- there may be some mechanism to auto-provision this.](https://superuser.com/questions/676735/taking-screen-shot-from-mac-by-an-interval)

- [apple docs talking about mach bootstrap hierarchy](https://developer.apple.com/library/archive/documentation/Darwin/Conceptual/KernelProgramming/contexts/contexts.html)



#### Troubleshooting simplicity

If you can get a valid screenshot (using `/bin/sbin/screencapture`) out of `cron`, that likely indicates it is working with permissions. Right now, it just appears as such:
![image-20210513190525216](/Users/dougpa/Library/Application Support/typora-user-images/image-20210513190525216.png)





#### All other info links

https://stackoverflow.com/questions/59239485/screencapture-over-cron-shown-background-instead-window-content
https://superuser.com/questions/1510312/mac-screenshot-crontab-only-got-desktop
https://superuser.com/questions/676735/taking-screen-shot-from-mac-by-an-interval
https://www.google.com/search?q=cron+screen+recording+prompt+for+permission+sip&oq=cron+screen+recording+prompt+for+permission+sip+&aqs=chrome..69i57j33i299.10175j1j1&sourceid=chrome&ie=UTF-8
https://stackoverflow.com/questions/57957198/how-to-trigger-screen-recording-permission-system-modal-dialog-on-macos-catalina
https://apple.stackexchange.com/questions/384230/how-do-i-reset-screen-recording-permission-on-macos-catalina
https://scriptingosx.com/2020/09/avoiding-applescript-security-and-privacy-requests/
https://masashi-k.blogspot.com/2013/07/screen-capture-with-cron-on-mac.html
https://askubuntu.com/questions/1196051/cronjob-for-screenshots-not-working
https://medium.com/nerd-for-tech/what-to-do-when-your-macos-daemon-gets-blocked-by-tcc-dialogues-d3a1b991151f
https://osxdaily.com/2020/04/27/fix-cron-permissions-macos-full-disk-access/
https://www.jamf.com/jamf-nation/discussions/35181/how-to-add-application-in-screen-recording-in-macos-catalina
https://github.com/jamf/PPPC-Utility
https://eclecticlight.co/2019/07/22/mojaves-privacy-consent-works-behind-your-back/