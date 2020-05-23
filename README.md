# snoozebox

An imapfilter module for snoozing email -- like Sanebox, but free.

This is meant to provide an easy, cross-platform, client-independent method for snoozing email on an IMAP server for an arbitrary amount of time by moving the mail to a specially named folder.  When I tried [Sanebox](https://www.sanebox.com/) I really liked this functionality, but I did not like the idea of paying $60/year for it.   So I made snoozebox.

To configure this, create a parent folder for your snoozed email (such as `SnoozeBox`).  Within that you can create any number of sub-folders with the prefix `Snooze_`.  These will be processed by snoozebox to look for mail to snooze.  When snoozebox finds mail in one of these folders it will attach a custom `X-Snooze-Until` header to it then move it into a designated holding pen used for all your snoozed email.

The amount of time that a message is snoozed for depends upon the name of the `Snooze_` folder.  If it ends in an integer, _eg_ `Snooze_60`, the mail will be snoozed for only that number of seconds.  (This is not the most useful in real life, but is useful for testing -- it might be better to change this default to minutes.  Or hours.  Or make it configurable.  We'll see!)  However, rather than provide a raw number of seconds you can also add a suffix to your count: `d`, `w`, `m`, or `y`.   This will turn your integer into a number of days, weeks, months, or years, respectively.

If an interval name is provided, snoozebox does a little extra calculation to figure out the start of the current day and set the interval from there.  For example, if it is 10pm on Thursday, and you move mail into a folder called `Snooze_1d`, it will be snoozed for one day from _midnight_ on Thursday, meaning it will show back up in 2 hours.

This is meant so that you can easily have something be snoozed until "tomorrow" even if it's late in the day without having to wait a full 24 hours for it to pop back up again.

(Note that, this depends upon the timezone in which snoozebox runs -- you might want to set your `TZ` environment variable to your local timezone whin you run this if you're on a system that usually runs on UTC.  Note, also, that at this point, a month is assumed to be 30 days, and a year to be 365.  There's no special calendar logic.)

The second thing snoozebox does is examine your holding pen folder.  (We call this folder `Snoozed`.  You don't need to subscribe your client to it if you don't want to.)  It examines the `X-Snooze-Until` header of every message in this folder and if the current time is past the specified time the message will be marked as unread and moved back into your inbox.

For additional filtering options, configurable tags are applied both to messages that have been snoozed, and ones for which the snooze time is expired.

## configuration

The two public functions in `snoozebox.lua` take as an argument a table with the following items:

* account:  an imapfilter account object, as returned by `IMAP()`
* base_folder: the name of the parent folder for your snooze-folders and holding pen
* snoozed_tag: the tag applied to snoozed messages
* expired_tag: the tag applied to unsnoozed messages

For a simple imapfilter config file using this, examine `config.lua.example`.  A sample folder tree using this configuration might look be something like:

    - INBOX
     | - Sent
     | - Trash
     | - SnoozeBox
        | - Snooze_1d
        | - Snooze_1w
        | - Snoozed

## license and disclaimer

This is public domain software.  You should note that this is the first time I've written anything non-trivial in lua.  I do not _think_ it has any real chance of deleting all your email, burning down your house, or turning your kids into Republicans, but I make no promises and take no responsibility if it does.   If it does, I'm sorry.  Especially about your kids.

Aside from that, do with this what you will.