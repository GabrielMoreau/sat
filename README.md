# SAT — Simple At Scheduler

SAT is a lightweight one-shot job scheduler for Linux systems using systemd.
It provides an `at`-like user interface while using persistent systemd timers internally.

The goal is simple:

* schedule a command once;
* survive machine reboots;
* keep administration simple;
* avoid hidden state;
* remove completed jobs automatically;
* leave failed jobs available for inspection.


## Documentation and project resources

* **User manual**
  * `sat`: https://legi.gricad-pages.univ-grenoble-alpes.fr/soft/trokata/sat/sat.html
  * `satq`: https://legi.gricad-pages.univ-grenoble-alpes.fr/soft/trokata/sat/satq.html
  * `satrm`: https://legi.gricad-pages.univ-grenoble-alpes.fr/soft/trokata/sat/satrm.html
  * `sat-run`: https://legi.gricad-pages.univ-grenoble-alpes.fr/soft/trokata/sat/sat-run.html

* **Download** (**Debian packages**)
  * https://legi.gricad-pages.univ-grenoble-alpes.fr/soft/trokata/sat/download/

* **Source Code** (GitLab)
  * https://gricad-gitlab.univ-grenoble-alpes.fr/legi/soft/trokata/sat/


## Why SAT?

The traditional `at` command is convenient, but it has limitations on modern servers:

* jobs may be lost if the machine is powered off;
* there is limited visibility after scheduling;
* integration with systemd logging and administration tools is missing.

SAT uses systemd timers to provide a more robust execution model.


## Features

* One-shot command scheduling.
* Persistent execution across reboots.
* Simple shell pipeline interface.
* No database.
* No duplicated command metadata.
* Automatic cleanup after successful execution.
* Failed jobs are preserved.
* Manual retry or removal by administrator.
* Full integration with systemd and journald.
* Works for root and for regular users.


## Usage

### Schedule a job

A command is provided through standard input:

```bash
echo "usermgmt to-staff --employer DoD --job Programmer johndoe" | \
  sat 2026-08-31 23:59
```

Example:

```
scheduled job 000042 at 2026-08-31 23:59
```

The command is stored as an executable shell script and scheduled through a systemd timer.


### List jobs

```bash
satq
```

Example:

```
ID       NEXT RUN                  STATE      COMMAND
000042   2026-08-31 23:59          waiting    usermgmt to-staff --employer DoD --job Programmer johndoe
000043   2026-09-01 08:00          failed     backup --full
```


### Remove a job

If a mistake is noticed after scheduling:

```bash
satrm 42
```

The job is immediately cancelled.

No confirmation is requested.


## Job lifecycle

A normal job follows this lifecycle:

```
          +---------+
          | waiting |
          +----+----+
               |
               v
          +---------+
          | running |
          +----+----+
               |
      +--------+--------+
      |                 |
      v                 v
   +---------+       +---------+
   | removed |       | failed  |
   +---------+       +---------+
```

### Successful execution

When a job exits with status `0`:

* the timer is disabled;
* the timer unit is removed;
* the job script is removed.

The job disappears from SAT.


### Failed execution

When a job exits with a non-zero status:

* the timer is disabled;
* the job script is kept;
* the failure state is recorded;
* no automatic retry occurs.

The administrator decides what to do next.


## Design principles

### Single source of truth

SAT deliberately avoids storing job information in multiple places.

The command itself is stored only once:

```
(root) /var/lib/sat/job/sat-000042.sh
(user) ~/.local/state/sat/job/sat-000042.sh
```

The schedule is stored only in the systemd timer:

```
(root) /etc/systemd/system/sat-000042.timer
(user) ~/.config/systemd/user/sat-*.timer
```

There is no duplicated database or metadata file.

### No automatic retry

A failed administrative command is not automatically executed again.
Examples:

* account creation;
* permission changes;
* migrations;
* maintenance scripts.

An automatic retry could make a bad situation worse.
SAT leaves the decision to the administrator.


## User services and lingering

When SAT is used by a regular user, jobs are scheduled through the user's systemd instance (`systemctl --user`).

By default, user timers only run while the user's systemd instance is active.
On most systems this means while the user is logged in.
Depending on the system configuration, timers may require lingering (`loginctl enable-linger`) to continue running after the user logs out.

To allow timers to continue running after logout, you must enable *lingering*:

```bash
sudo loginctl enable-linger USERNAME
```

To disable it again:

```bash
sudo loginctl disable-linger USERNAME
```

You can check whether lingering is enabled with:

```bash
loginctl show-user USERNAME -p Linger
```

Root system timers are not affected by this limitation.


## Architecture

A similar approach works for non-root users by simply changing the paths.

```
             root
              |
              |
         +----v----+
         |   sat   |
         +----+----+
              |
              |
        /var/lib/sat/job/
         sat-000042.sh
              |
              |
      /etc/systemd/system/
         sat-000042.timer
              |
              |
         +----v----+
         | systemd <---------- sat-run@.service
         +----+----+
              |
              |
      sat-run@000042.service
              |
              |
      /usr/libexec/sat/sat-run
```


## Installed files

### Commands

```
/usr/bin/sat
/usr/bin/satq
/usr/bin/satrm
```

### Internal helpers

```
/usr/libexec/sat/sat-run
```

### Common parameters

```
/usr/libexec/sat/sat-common
```

### systemd integration

```
(root) /usr/lib/systemd/system/sat-run@.service
(user) /usr/lib/systemd/user/sat-run@.service
```

### Runtime data

```
(root) /var/lib/sat/job/
(user) ~/.local/state/sat/job/
```

### Generated timers

```
(root) /etc/systemd/system/sat-*.timer
(user) ~/.config/systemd/user/sat-*.timer
```


## Installation

Pre-built Debian packages are available: https://legi.gricad-pages.univ-grenoble-alpes.fr/soft/trokata/sat/download/

The package installs:

```
/usr/bin/
/usr/libexec/
/usr/lib/systemd/system/
/usr/share/man/
/var/lib/sat/
```

After installation:

```bash
systemctl daemon-reload
```

is required.


## Logging

Execution output is handled by systemd journal.
Examples:

```bash
(root) journalctl -u sat-run@000042.service
(user) journalctl --user -u sat-run@000042.service
```

or:

```bash
journalctl -xe
```


## Security considerations

SAT is mainly intended for system administration use.
The following directories must be protected:

```
/var/lib/sat/job/
/etc/systemd/system/
```

Only trusted users should be able to create or modify root scheduled jobs.
A modified job script is equivalent to modifying a privileged scheduled command.


## Future improvements

Possible future additions:

* `satcat` — display job content;
* `satrun` — run a job manually.


## Author

Written by Gabriel Moreau <Gabriel.Moreau(A)univ-grenoble-alpes.fr> - Grenoble - France


## License and Copyright

* License GNU GPL version 2 or later and Perl equivalent
* Copyright (C) 2026, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France

