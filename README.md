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


## Usage

### Schedule a job

A command is provided through standard input:

```bash
echo "usermgmt to-staff --employer DoD --job Programmer toto" | \
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
000042   2026-08-31 23:59          waiting    usermgmt to-staff --employer DoD --job Programmer toto
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
/var/lib/sat/job/000042.sh
```

The schedule is stored only in the systemd timer:

```
/etc/systemd/system/sat-000042.timer
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


## Architecture

```
             user
              |
              |
         +----v----+
         |   sat   |
         +----+----+
              |
              |
    /var/lib/sat/job/000042.sh
              |
              |
    /etc/systemd/system/
         sat-000042.timer
              |
              |
         systemd
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

### systemd integration

```
/usr/lib/systemd/system/sat-run@.service
```

### Runtime data

```
/var/lib/sat/job/
```

### Generated timers

```
/etc/systemd/system/sat-*.timer
```


## Debian packaging

SAT is designed to be packaged as a Debian package.
The package should install:

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
journalctl -u sat-run@000042.service
```

or:

```bash
journalctl -xe
```


## Security considerations

SAT is intended for system administration use.
The following directories must be protected:

```
/var/lib/sat/job/
/etc/systemd/system/
```

Only trusted users should be able to create or modify scheduled jobs.

A modified job script is equivalent to modifying a privileged scheduled command.


## Future improvements

Possible future additions:

* `satcat` — display job content;
* `satrun` — run a job manually;
* relative dates (`+2h`, `tomorrow 08:00`);
* user mode using `systemd --user`;
* shell completion;
* Debian native integration.


## License

To be defined.


## Author

Written by Gabriel Moreau <Gabriel.Moreau(A)univ-grenoble-alpes.fr> - Grenoble - France


## License and Copyright

* License GNU GPL version 2 or later and Perl equivalent
* Copyright (C) 2026, LEGI UMR 5519 / CNRS UGA G-INP, Grenoble, France

