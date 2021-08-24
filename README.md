# org-alert

Provides notifications for scheduled or deadlined agenda entries. This
is a forked version from [the original by
spegoraro](https://github.com/spegoraro/org-alert) that checks how far
away the events are before notifying.

![Screenshot](/screenshot.png?raw=true "org-alert screenshot")


## Command overview
### `org-alert-check`

> Check for and display agenda entries that are active and due.

org-alert parses your org agenda for the current day looking for any
headlines that are scheduled or contain a deadline that aren't marked
with any of your `DONE` state keywords.


### `org-alert-enable`

> Enable periodic deadline checking.

Sets a timer which periodically calls `org-alert-check`. The
interval can be set by changing the `org-alert-interval` (defaults to
300s).


### `org-alert-disable`

> Disable periodic deadline checking.

Cancels any timers set up with the `org-alert-enable` function.

## Installation

### Manually

The original version linked above is the one in Melpa, so if you want
to use this version you have to install manually.

The original instructions are "Clone the repo somewhere you will
remember and then add it to your load path:"

```elisp
(add-to-list 'load-path "path/to/org-alert")
(require 'org-alert)
```

But I just put
```elisp
  (load "path/to/org-alert")
```

in my config. Probably the original instructions are better.

## Configuration

org-alert uses the excellent
[alert](https://github.com/jwiegley/alert) package from John Wiegley
to present its alerts. This defaults to using the emacs `message`
function for displaying notifications, to change it to something
prettier set the `alert-default-style` variable to one of the options
listed [here](https://github.com/jwiegley/alert#builtin-alert-styles).

To get system notifications like the screenshot use the following:
```elisp
(setq alert-default-style 'libnotify)
```
You can even define your own styles!

Some other configuration options I like:
```elisp
(setq org-alert-interval       60 ; how often to check for tasks, in seconds
	  org-alert-notify-cutoff  10 ; how long before an event to notify, in minutes
	  alert-persist-idle-time   0 ; make notifications persist
	  alert-fade-time         600 ; don't fade alerts for 10 minutes)
```

### Custom titles

org-alert uses the title `Org Agenda` by default. You can set this to
something else by changing the `org-alert-notification-title`
variable. Use this if you'd like to customise the display of org
notifications when using a daemon such as
[dunst](https://github.com/knopwob/dunst).

### Custom regexp for searching agenda entries

org-alert searches for agenda entries with 'Sched' or 'Deadline' word
by default. You can set any other regexp you wish using
the `org-alert-headline-regexp` variable.


