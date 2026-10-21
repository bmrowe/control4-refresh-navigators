# Control4 Refresh Navigators

A tiny DriverWorks driver that does what **File > Refresh Navigators** does in Composer, but from
programming. It has one command, **Refresh Navigators**, that you can run from the driver's
Actions tab or from any programming script.

## Why

After a Director restart or controller reboot, the Listen menu in every room can come up empty
even though the sources still play. Director builds its room lists before all audio paths exist
and doesn't rebuild them until it receives a project-info update, which is what Composer's Refresh
Navigators sends. This driver sends that update automatically, so you don't need Composer.

## How it works

The driver connects to Director's local command port (`127.0.0.1:5020`), sends a bare PIP
message, then disconnects:

```xml
<c4soap name="PIP" async="1"></c4soap>
```

Director logs it as `PIP received from local connection: Refresh Navigators(<id>)`, raises the
project version, and every Navigator reloads.

## Install

1. Download `refresh-navigators.c4z` from the [latest release](../../releases/latest).
2. Add the driver to any room in Composer Pro.
3. Click **Refresh Navigators** on the driver's Actions tab once to check it works: your
   Navigators should blink and reload.

## Use after every restart

In Programming, select the project root and choose **When the project is loaded**, then add:

1. **Delay** 1 minute
2. **Refresh Navigators** (this driver's command)
3. Optionally, a notification so you know the system is ready

The project-loaded event fires about 35 seconds after Director starts. That's a few seconds after
the controller's own audio bindings appear, so a short delay is enough.

## Properties

- **Debug Mode**: logs each step to the Lua output.
- **Last Refresh**: the time of the last refresh and its result: `sent`,
  `timed out connecting` or `connection failed`.

## Notes

- Each refresh reloads every Navigator, the same as the Composer menu item. Don't call it in a
  loop.
- The PIP message isn't part of the documented DriverWorks API. Tested on a CORE 5 running OS
  4.2.1.
- No dependencies, no build step. The `.c4z` is just `driver.xml` and `driver.lua` zipped:

  ```bash
  zip -X refresh-navigators.c4z driver.xml driver.lua
  ```

## License

MIT
