module app;

import std.stdio;
import fluidsync.server;
import core.stdc.signal;

__gshared FluidSyncServer server;

extern (C) void handleSignal(int sig) nothrow @nogc @system
{
  if (server)
  {
    server.stop();
  }
}

void main()
{
  // Graceful shutdown handling
  signal(SIGINT, &handleSignal);
  signal(SIGTERM, &handleSignal);

  try
  {
    server = new FluidSyncServer();
    server.start();
  }
  catch (Exception e)
  {
    writeln("Error: ", e.msg);
  }

  writeln("FluidSync Daemon gracefully shut down.");
}
