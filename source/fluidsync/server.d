module fluidsync.server;

import core.sys.windows.windows;
import std.stdio;
import std.datetime;
import core.thread;
import fluidsync.types;

class FluidSyncServer
{
  private HANDLE hMapFile;
  private FluidSyncState* pBuf;
  private string mapName = "Local\\FluidSyncSharedMem";
  private bool running = false;
  private uint tickCounter = 0;

  this()
  {
    import std.utf : toUTF16z;

    // 1. Create a named file mapping object using system paging file
    hMapFile = CreateFileMappingW(
      INVALID_HANDLE_VALUE, // use paging file
      null, // default security
      PAGE_READWRITE, // read/write access
      0, // maximum object size (high-order DWORD)
      FluidSyncState.sizeof, // maximum object size (low-order DWORD)
      mapName.toUTF16z); // name of mapping object

    if (hMapFile == null)
    {
      throw new Exception("Could not create file mapping object.");
    }

    // 2. Map the view of the file into the server's address space
    pBuf = cast(FluidSyncState*) MapViewOfFile(
      hMapFile, // handle to map object
      FILE_MAP_ALL_ACCESS, // read/write permission
      0,
      0,
      FluidSyncState.sizeof);

    if (pBuf == null)
    {
      CloseHandle(hMapFile);
      throw new Exception("Could not map view of file.");
    }

    // Initialize the shared memory state
    pBuf.version_tick = 0;
    pBuf.current_budget_ms = 16.6f; // target 60fps by default
    pBuf.urgent_mode = false;
    pBuf.ideal_layout_ms = 10.0f; // leave some ms for rasterization
  }

  ~this()
  {
    if (pBuf)
      UnmapViewOfFile(pBuf);
    if (hMapFile)
      CloseHandle(hMapFile);
  }

  void start()
  {
    running = true;
    writeln("FluidSync Daemon started. Writing to shared memory: ", mapName);
    writeln("Press Ctrl+C to stop.");

    while (running)
    {
      updateMetrics();
      Thread.sleep(msecs(16)); // Target ~60 ticks per second for metrics updates
    }
  }

  void stop() nothrow @nogc
  {
    running = false;
  }

  private void updateMetrics()
  {
    tickCounter++;

    // TODO: In a production implementation, this is where we poll ETW / DXGI
    // For now, we simulate system load changes and budget adjustments

    pBuf.version_tick = tickCounter;

    // MOCK: Toggle urgent mode every 5 seconds (approx 300 ticks at 60Hz)
    // This allows developers to test their applications switching in and out
    // of "Skeleton Pass" rendering without having to actually induce system lag.
    if (tickCounter % 300 == 0)
    {
      bool isUrgent = !pBuf.urgent_mode;
      pBuf.urgent_mode = isUrgent;

      if (isUrgent)
      {
        pBuf.current_budget_ms = 6.9f;
        pBuf.ideal_layout_ms = 3.0f;
      }
      else
      {
        pBuf.current_budget_ms = 16.6f;
        pBuf.ideal_layout_ms = 10.0f;
      }
    }
  }
}
